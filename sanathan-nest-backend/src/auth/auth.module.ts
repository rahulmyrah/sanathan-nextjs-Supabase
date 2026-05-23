import { Module } from '@nestjs/common';
import { LazyAuthGuard } from './lazy-auth.guard';

@Module({
  providers: [LazyAuthGuard],
  exports: [LazyAuthGuard],
})
export class AuthModule {}

