import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
  Min,
  ValidateIf,
} from 'class-validator';

export enum TransactionType {
  INCOME = 'income',
  EXPENSE = 'expense',
  TRANSFER = 'transfer',
}

export class CreateTransactionDto {
  @IsNotEmpty()
  @IsUUID()
  accountId: string;

  @ValidateIf((o) => o.type === TransactionType.TRANSFER)
  @IsNotEmpty({ message: 'destinationAccountId is required for transfer transactions' })
  @IsUUID()
  destinationAccountId?: string;

  @ValidateIf((o) => o.type !== TransactionType.TRANSFER)
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @IsNotEmpty()
  @IsEnum(TransactionType, {
    message: 'type must be one of: income, expense, transfer',
  })
  type: TransactionType;

  @IsNotEmpty()
  @IsNumber()
  @IsPositive({ message: 'amount must be a positive number' })
  amount: number;

  @IsOptional()
  @IsNumber()
  @Min(0, { message: 'feeAmount must be non-negative' })
  feeAmount?: number = 0.0;

  @IsOptional()
  @IsDateString()
  transactionDate?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];

  @IsOptional()
  @IsString()
  receiptUrl?: string;

  @IsOptional()
  @IsBoolean()
  isRecurring?: boolean;
}
