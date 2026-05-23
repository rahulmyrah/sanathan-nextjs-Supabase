import { Module } from '@nestjs/common';
import { AstrologyService } from './astrology.service';
import { AstrologyController } from './astrology.controller';

@Module({
  controllers: [AstrologyController],
  providers: [AstrologyService],
  exports: [AstrologyService],
})
export class AstrologyModule {}
