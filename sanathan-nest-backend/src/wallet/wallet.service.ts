import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class WalletService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  async getWallet(userId: string) {
    const wallet = await this.prisma.wallet.upsert({
      where: { userId },
      update: {},
      create: { userId },
      include: {
        transactions: {
          orderBy: { createdAt: 'desc' },
          take: 20,
        },
      },
    });

    return {
      id: wallet.id,
      userId: wallet.userId,
      balance: wallet.balance,
      currency: wallet.currency,
      recentTransactions: wallet.transactions,
    };
  }

  createRechargeQuote(userId: string, amount: number, currency: 'INR' | 'USD') {
    const conversionRate = Number(this.configService.get<string>('USD_TO_INR_FACTOR') ?? 80);
    const amountInInr = currency === 'USD' ? amount * conversionRate : amount;

    return {
      userId,
      requestedAmount: amount,
      requestedCurrency: currency,
      amountInInr: Number(amountInInr.toFixed(2)),
      walletCurrency: 'INR',
      conversionRate: currency === 'USD' ? conversionRate : 1,
      supportedProviders: ['razorpay', 'stripe', 'cashfree'],
    };
  }
}

