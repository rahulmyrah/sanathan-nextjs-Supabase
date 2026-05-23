import { Body, Controller, Headers, Post } from '@nestjs/common';
import { PaymentsService } from './payments.service';

@Controller('api/v1/payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('razorpay/webhook')
  handleRazorpayWebhook(
    @Body() payload: any,
    @Headers('x-razorpay-signature') signature?: string,
  ) {
    this.paymentsService.verifyHmacSignature(payload, signature, 'RAZORPAY_WEBHOOK_SECRET');
    const payment = payload?.payload?.payment?.entity ?? payload;

    return this.paymentsService.creditWalletFromWebhook({
      provider: 'razorpay',
      referenceId: payment.id,
      userId: payment.notes?.userId ?? payment.notes?.user_id,
      amount: Number(payment.amount ?? 0) / 100,
      currency: payment.currency ?? 'INR',
      rawPayload: payload,
    });
  }

  @Post('stripe/webhook')
  handleStripeWebhook(
    @Body() payload: any,
    @Headers('stripe-signature') signature?: string,
  ) {
    this.paymentsService.verifyHmacSignature(payload, signature, 'STRIPE_WEBHOOK_SECRET');
    const paymentIntent = payload?.data?.object ?? payload;

    return this.paymentsService.creditWalletFromWebhook({
      provider: 'stripe',
      referenceId: paymentIntent.id,
      userId: paymentIntent.metadata?.userId ?? paymentIntent.metadata?.user_id,
      amount: Number(paymentIntent.amount_received ?? paymentIntent.amount ?? 0) / 100,
      currency: paymentIntent.currency?.toUpperCase() ?? 'USD',
      rawPayload: payload,
    });
  }

  @Post('cashfree/webhook')
  handleCashfreeWebhook(
    @Body() payload: any,
    @Headers('x-webhook-signature') signature?: string,
  ) {
    this.paymentsService.verifyHmacSignature(payload, signature, 'CASHFREE_WEBHOOK_SECRET');
    const payment = payload?.data?.payment ?? payload?.data ?? payload;
    const order = payload?.data?.order ?? payload?.order ?? {};

    return this.paymentsService.creditWalletFromWebhook({
      provider: 'cashfree',
      referenceId: payment.cf_payment_id ?? payment.payment_id ?? order.order_id,
      userId: order.order_tags?.userId ?? order.order_tags?.user_id ?? payload.userId,
      amount: Number(payment.payment_amount ?? order.order_amount ?? 0),
      currency: payment.payment_currency ?? order.order_currency ?? 'INR',
      rawPayload: payload,
    });
  }
}

