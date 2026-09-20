import {
  IsBoolean,
  IsEnum,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export enum AccountType {
  CASH = 'cash',
  BANK = 'bank',
  CREDIT_CARD = 'credit_card',
  DIGITAL_WALLET = 'digital_wallet',
  OTHER = 'other',
}

export class CreateAccountDto {
  @IsNotEmpty()
  @IsString()
  name: string;

  @IsNotEmpty()
  @IsEnum(AccountType, {
    message: 'accountType must be one of: cash, bank, credit_card, digital_wallet, other',
  })
  accountType: AccountType;

  @IsOptional()
  @IsString()
  currency?: string = 'INR';

  @IsOptional()
  @IsNumber()
  initialBalance?: number = 0.0;

  @IsOptional()
  @IsNumber()
  @Min(0, { message: 'creditLimit must be non-negative' })
  creditLimit?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(28)
  billingCycleDay?: number;
}

export class UpdateAccountDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsEnum(AccountType)
  accountType?: AccountType;

  @IsOptional()
  @IsNumber()
  creditLimit?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(28)
  billingCycleDay?: number;

  @IsOptional()
  @IsBoolean()
  isArchived?: boolean;
}
