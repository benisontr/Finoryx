import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
} from 'class-validator';

export enum CategoryType {
  INCOME = 'income',
  EXPENSE = 'expense',
}

export class CreateCategoryDto {
  @IsNotEmpty()
  @IsString()
  name: string;

  @IsNotEmpty()
  @IsString()
  icon: string;

  @IsNotEmpty()
  @IsString()
  @Matches(/^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$/, {
    message: 'colorHex must be a valid hex color (e.g. #6366F1 or #6366F1FF)',
  })
  colorHex: string;

  @IsNotEmpty()
  @IsEnum(CategoryType, {
    message: 'type must be either income or expense',
  })
  type: CategoryType;

  @IsOptional()
  @IsUUID()
  parentId?: string;
}

export class UpdateCategoryDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  icon?: string;

  @IsOptional()
  @IsString()
  @Matches(/^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$/, {
    message: 'colorHex must be a valid hex color',
  })
  colorHex?: string;

  @IsOptional()
  @IsUUID()
  parentId?: string;
}
