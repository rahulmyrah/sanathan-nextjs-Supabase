import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthenticatedUser } from '../auth/authenticated-user.interface';
import { LazyAuthGuard } from '../auth/lazy-auth.guard';
import { RechargeQuoteDto } from './dto/recharge-quote.dto';
import { WalletService } from './wallet.service';

@Controller('api/v1/wallet')
@UseGuards(LazyAuthGuard)
export class WalletController {
  constructor(private readonly walletService: WalletService) {}

  @Get('me')
  getMyWallet(@CurrentUser() user: AuthenticatedUser) {
    return this.walletService.getWallet(user.id);
  }

  @Post('recharge/quote')
  createRechargeQuote(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: RechargeQuoteDto,
  ) {
    return this.walletService.createRechargeQuote(user.id, body.amount, body.currency);
  }
}
