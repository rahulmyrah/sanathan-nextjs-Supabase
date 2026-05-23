import { HttpException, HttpStatus, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, timingSafeEqual } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { PaymentWebhookCredit } from './dto/payment-webhook.dto';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  verifyHmacSignature(payload: unknown, signature: string | undefined, secretName: string) {
    const secret = this.configService.get<string>(secretName);
    if (!secret) {
      this.logger.warn(`${secretName} is not configured; accepting webhook in local mode.`);
      return;
    }

    if (!signature) {
      throw new HttpException('Missing webhook signature', HttpStatus.UNAUTHORIZED);
    }

    const expected = createHmac('sha256', secret)
      .update(JSON.stringify(payload))
      .digest('hex');
    const expectedBuffer = Buffer.from(expected);
    const providedBuffer = Buffer.from(signature);

    if (
      expectedBuffer.length !== providedBuffer.length ||
      !timingSafeEqual(expectedBuffer, providedBuffer)
    ) {
      throw new HttpException('Invalid webhook signature', HttpStatus.UNAUTHORIZED);
    }
  }

  async creditWalletFromWebhook(input: PaymentWebhookCredit) {
    if (!input.userId || !input.referenceId || input.amount <= 0) {
      throw new HttpException('Webhook payload is missing payment metadata', HttpStatus.BAD_REQUEST);
    }

    const referenceId = `${input.provider}:${input.referenceId}`;
    const existing = await this.prisma.transaction.findFirst({
      where: {
        referenceId,
        type: 'CREDIT',
        status: 'COMPLETED',
      },
    });

    if (existing) {
      return { status: 'duplicate_ignored', referenceId };
    }

    const user = await this.prisma.user.upsert({
      where: { id: input.userId },
      update: { isAnonymous: false },
      create: {
        id: input.userId,
        isAnonymous: false,
        profile: { create: {} },
      },
    });

    const wallet = await this.prisma.wallet.upsert({
      where: { userId: user.id },
      update: {},
      create: { userId: user.id, currency: 'INR' },
    });

    const amountInInr = this.toWalletCurrency(input.amount, input.currency);

    await this.prisma.$transaction([
      this.prisma.wallet.update({
        where: { id: wallet.id },
        data: { balance: { increment: amountInInr } },
      }),
      this.prisma.transaction.create({
        data: {
          walletId: wallet.id,
          amount: amountInInr,
          type: 'CREDIT',
          status: 'COMPLETED',
          referenceId,
          description: `Wallet recharge via ${input.provider}`,
        },
      }),
    ]);

    return {
      status: 'credited',
      userId: user.id,
      referenceId,
      amount: amountInInr,
      currency: 'INR',
    };
  }

  private toWalletCurrency(amount: number, currency: string) {
    if (currency.toUpperCase() === 'USD') {
      const rate = Number(this.configService.get<string>('USD_TO_INR_FACTOR') ?? 80);
      return Number((amount * rate).toFixed(2));
    }

    return Number(amount.toFixed(2));
  }
}

