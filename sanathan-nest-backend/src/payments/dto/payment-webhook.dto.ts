export interface PaymentWebhookCredit {
  provider: 'razorpay' | 'stripe' | 'cashfree';
  referenceId: string;
  userId: string;
  amount: number;
  currency: string;
  rawPayload: unknown;
}

