import {
  Injectable,
  Logger,
} from '@nestjs/common';
import { SupabaseService } from '../../database/supabase.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { handleSupabaseError } from '../../common/utils/supabase-error.util';

export class UserProfile {
  id: string;
  email?: string;
  fullName: string;
  baseCurrency: string;
  biometricEnabled: boolean;
  monthStartDay: number;
  createdAt: string;
  updatedAt: string;

  static fromRow(row: any, email?: string): UserProfile {
    return {
      id: row.id,
      email: email || row.email,
      fullName: row.full_name,
      baseCurrency: row.base_currency,
      biometricEnabled: row.biometric_enabled,
      monthStartDay: row.month_start_day,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }
}

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(private readonly supabaseService: SupabaseService) {}

  async getProfile(userId: string, email?: string): Promise<UserProfile> {
    const supabase = this.supabaseService.getAdminClient();

    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (error || !data) {
      this.logger.warn(`Profile not found for ${userId}: ${error?.message}`);
      return {
        id: userId,
        email,
        fullName: 'Finoryx User',
        baseCurrency: 'INR',
        biometricEnabled: false,
        monthStartDay: 1,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
    }

    return UserProfile.fromRow(data, email);
  }

  async updateProfile(userId: string, dto: UpdateProfileDto): Promise<UserProfile> {
    const supabase = this.supabaseService.getAdminClient();

    const updates: Record<string, any> = {};
    if (dto.fullName !== undefined) updates.full_name = dto.fullName;
    if (dto.baseCurrency !== undefined) updates.base_currency = dto.baseCurrency;
    if (dto.biometricEnabled !== undefined) updates.biometric_enabled = dto.biometricEnabled;
    if (dto.monthStartDay !== undefined) updates.month_start_day = dto.monthStartDay;

    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', userId)
      .select('*')
      .single();

    if (error) {
      handleSupabaseError(this.logger, error, `Failed to update profile for ${userId}`);
    }

    return UserProfile.fromRow(data);
  }
}
