import { IsNumber, IsPositive, IsOptional, IsUUID } from 'class-validator';
import { Type } from 'class-transformer';

export class ContributeGoalDto {
  @IsNumber({ maxDecimalPlaces: 2 })
  @IsPositive()
  @Type(() => Number)
  amount: number;

  @IsOptional()
  @IsUUID('4')
  sourceAccountId?: string;
}
