import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { SupabaseService } from '../../database/supabase.service';
import { SignUpDto, SignInDto } from './dto/auth.dto';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(private readonly supabaseService: SupabaseService) {}

  async signUp(dto: SignUpDto) {
    const supabase = this.supabaseService.getClient();

    const { data, error } = await supabase.auth.signUp({
      email: dto.email,
      password: dto.password,
      options: {
        data: {
          full_name: dto.fullName,
          base_currency: dto.baseCurrency || 'INR',
        },
      },
    });

    if (error) {
      this.logger.error(`Sign up failed for ${dto.email}: ${error.message}`);
      throw new BadRequestException(error.message);
    }

    if (!data.user) {
      throw new InternalServerErrorException('Failed to create user');
    }

    // Ensure profile row exists in public.profiles table
    const adminClient = this.supabaseService.getAdminClient();
    const { error: profileError } = await adminClient
      .from('profiles')
      .upsert({
        id: data.user.id,
        full_name: dto.fullName,
        base_currency: dto.baseCurrency || 'INR',
        biometric_enabled: false,
        month_start_day: 1,
      });

    if (profileError) {
      this.logger.warn(`Profile upsert note: ${profileError.message}`);
    }

    return {
      user: {
        id: data.user.id,
        email: data.user.email,
        fullName: dto.fullName,
      },
      session: data.session,
    };
  }

  async signIn(dto: SignInDto) {
    const supabase = this.supabaseService.getClient();

    const { data, error } = await supabase.auth.signInWithPassword({
      email: dto.email,
      password: dto.password,
    });

    if (error) {
      this.logger.error(`Sign in failed for ${dto.email}: ${error.message}`);
      throw new UnauthorizedException(error.message);
    }

    const userMetadata = data.user.user_metadata || {};
    const fullName = userMetadata.full_name || userMetadata.fullName || dto.email.split('@')[0];
    const baseCurrency = userMetadata.base_currency || userMetadata.baseCurrency || 'INR';

    return {
      user: {
        id: data.user.id,
        email: data.user.email,
        fullName,
        baseCurrency,
        metadata: userMetadata,
      },
      session: data.session,
    };
  }

  async signOut(token: string) {
    const userClient = this.supabaseService.getClientForUser(token);
    const { error } = await userClient.auth.signOut();
    if (error) {
      this.logger.error(`Sign out error: ${error.message}`);
    }
    return { message: 'Successfully signed out' };
  }
}
