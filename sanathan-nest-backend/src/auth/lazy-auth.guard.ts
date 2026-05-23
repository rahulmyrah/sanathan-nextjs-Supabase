import {
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from './authenticated-user.interface';

@Injectable()
export class LazyAuthGuard implements CanActivate {
  private readonly supabase?: SupabaseClient;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    const supabaseUrl = this.configService.get<string>('SUPABASE_URL');
    const supabaseKey =
      this.configService.get<string>('SUPABASE_SERVICE_ROLE_KEY') ??
      this.configService.get<string>('SUPABASE_ANON_KEY');

    if (supabaseUrl && supabaseKey) {
      this.supabase = createClient(supabaseUrl, supabaseKey, {
        auth: { persistSession: false },
      });
    }
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<{
      headers: Record<string, string | string[] | undefined>;
      user?: AuthenticatedUser;
    }>();

    const authorization = this.getHeader(request.headers, 'authorization');
    const token = authorization?.startsWith('Bearer ')
      ? authorization.slice('Bearer '.length).trim()
      : undefined;

    if (token && this.supabase) {
      const { data, error } = await this.supabase.auth.getUser(token);
      if (error || !data.user) {
        throw new HttpException('Invalid Supabase auth token', HttpStatus.UNAUTHORIZED);
      }

      const user = await this.prisma.user.upsert({
        where: { id: data.user.id },
        update: {
          phone: data.user.phone ?? undefined,
          email: data.user.email ?? undefined,
          isAnonymous: false,
        },
        create: {
          id: data.user.id,
          phone: data.user.phone,
          email: data.user.email,
          isAnonymous: false,
          wallet: { create: {} },
          profile: { create: {} },
        },
      });

      request.user = {
        id: user.id,
        phone: user.phone,
        email: user.email,
        role: user.role,
      };
      return true;
    }

    const devUserId = this.getHeader(request.headers, 'x-user-id');
    if (devUserId && this.configService.get<string>('NODE_ENV') !== 'production') {
      const user = await this.prisma.user.upsert({
        where: { id: devUserId },
        update: {},
        create: {
          id: devUserId,
          isAnonymous: false,
          wallet: { create: {} },
          profile: { create: {} },
        },
      });

      request.user = { id: user.id, phone: user.phone, email: user.email, role: user.role };
      return true;
    }

    throw new HttpException(
      'Authentication is required for this premium action',
      HttpStatus.UNAUTHORIZED,
    );
  }

  private getHeader(
    headers: Record<string, string | string[] | undefined>,
    name: string,
  ): string | undefined {
    const value = headers[name] ?? headers[name.toLowerCase()];
    return Array.isArray(value) ? value[0] : value;
  }
}

