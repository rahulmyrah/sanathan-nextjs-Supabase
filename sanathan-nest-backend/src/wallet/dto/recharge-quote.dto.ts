import { IsIn, IsNumber, Min } from 'class-validator';

export class RechargeQuoteDto {
  @IsNumber()
  @Min(1)
  amount: number;

  @IsIn(['INR', 'USD'])
  currency: 'INR' | 'USD' = 'INR';
}

