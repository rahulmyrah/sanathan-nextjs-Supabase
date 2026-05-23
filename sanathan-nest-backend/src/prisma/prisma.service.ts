import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly hasDatabaseUrl: boolean;

  constructor() {
    const databaseUrl = process.env.DATABASE_URL;
    const adapter = new PrismaPg({
      connectionString:
        databaseUrl ?? 'postgresql://postgres:postgres@localhost:5432/sanathan_test',
    });

    super({
      adapter,
      log: process.env.NODE_ENV === 'development' ? ['query', 'info', 'warn', 'error'] : ['error'],
    });

    this.hasDatabaseUrl = !!databaseUrl;
  }

  async onModuleInit() {
    if (!this.hasDatabaseUrl && process.env.NODE_ENV === 'test') {
      return;
    }

    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
