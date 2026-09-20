import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class AiChatDto {
  @IsString()
  @IsNotEmpty()
  message: string;

  @IsOptional()
  context?: Record<string, any>;
}
