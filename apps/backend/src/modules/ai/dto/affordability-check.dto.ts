import { IsNumber, IsPositive, IsOptional, IsString } from 'class-validator';

export class AffordabilityCheckDto {
  @IsNumber()
  @IsPositive()
  amount: number;

  @IsOptional()
  @IsString()
  categoryId?: string;

  @IsOptional()
  @IsString()
  description?: string;
}
