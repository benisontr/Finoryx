import { InternalServerErrorException, Logger } from '@nestjs/common';

export function handleSupabaseError(logger: Logger, error: any, contextMessage: string): never {
  const message = error?.message || 'Database operation failed';
  logger.error(`${contextMessage}: ${message}`, error?.stack);
  throw new InternalServerErrorException(message);
}
