import {
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { IS_PUBLIC_KEY } from '../../../common/decorators/public.decorator';
import { SupabaseService } from '../../../database/supabase.service';

@Injectable()
export class SupabaseAuthGuard extends AuthGuard('supabase-jwt') {
  constructor(
    private reflector: Reflector,
    private supabaseService: SupabaseService,
  ) {
    super();
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers['authorization'];

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing or invalid Authorization header');
    }

    const token = authHeader.split(' ')[1];

    try {
      // Direct token validation with Supabase Auth
      const { data: { user }, error } = await this.supabaseService.getClient().auth.getUser(token);

      if (error || !user) {
        throw new UnauthorizedException('Invalid or expired authentication token');
      }

      request.user = {
        id: user.id,
        email: user.email,
        role: user.role,
        user_metadata: user.user_metadata,
      };

      return true;
    } catch (err) {
      if (err instanceof UnauthorizedException) {
        throw err;
      }
      try {
        return (await super.canActivate(context)) as boolean;
      } catch {
        throw new UnauthorizedException('Invalid or expired authentication token');
      }
    }
  }
}
