import {
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsPositive,
  IsUUID,
  Max,
  Min,
} from 'class-validator';

export class CreateBudgetDto {
  @IsNotEmpty()
  @IsUUID()
  categoryId: string;

  @IsNotEmpty()
  @IsInt()
  @Min(1)
  @Max(12)
  month: number;

  @IsNotEmpty()
  @IsInt()
  @Min(2020)
  year: number;

  @IsNotEmpty()
  @IsNumber()
  @IsPositive({ message: 'limitAmount must be greater than 0' })
  limitAmount: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  notifyThresholdPct?: number = 80;
}

export class UpdateBudgetDto {
  @IsOptional()
  @IsNumber()
  @IsPositive({ message: 'limitAmount must be greater than 0' })
  limitAmount?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  notifyThresholdPct?: number;
}
