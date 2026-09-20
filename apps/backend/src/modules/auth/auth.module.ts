import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { SupabaseJwtStrategy } from './strategies/supabase-jwt.strategy';
import { SupabaseAuthGuard } from './guards/supabase-auth.guard';

@Module({
  imports: [PassportModule.register({ defaultStrategy: 'supabase-jwt' })],
  controllers: [AuthController],
  providers: [AuthService, SupabaseJwtStrategy, SupabaseAuthGuard],
  exports: [AuthService, SupabaseAuthGuard],
})
export class AuthModule {}
