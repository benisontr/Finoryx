import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  fullName?: string;

  @IsOptional()
  @IsString()
  baseCurrency?: string;

  @IsOptional()
  @IsBoolean()
  biometricEnabled?: boolean;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(28)
  monthStartDay?: number;
}
