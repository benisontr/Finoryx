import { IsString, IsNotEmpty, IsNumber, IsPositive, IsOptional, IsUUID, IsDateString, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateGoalDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsNumber({ maxDecimalPlaces: 2 })
  @IsPositive()
  @Type(() => Number)
  targetAmount: number;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Type(() => Number)
  currentAmount?: number;

  @IsDateString()
  targetDate: string;

  @IsOptional()
  @IsUUID('4')
  linkedAccountId?: string;
}
