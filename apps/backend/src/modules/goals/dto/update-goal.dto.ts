import { IsString, IsNotEmpty, IsNumber, IsPositive, IsOptional, IsUUID, IsDateString, IsBoolean, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateGoalDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  name?: string;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @IsPositive()
  @Type(() => Number)
  targetAmount?: number;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Type(() => Number)
  currentAmount?: number;

  @IsOptional()
  @IsDateString()
  targetDate?: string;

  @IsOptional()
  @IsUUID('4')
  linkedAccountId?: string;

  @IsOptional()
  @IsBoolean()
  isCompleted?: boolean;
}
