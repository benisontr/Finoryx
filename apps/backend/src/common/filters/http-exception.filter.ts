import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const exceptionResponse =
      exception instanceof HttpException ? exception.getResponse() : null;

    let errorCode = 'INTERNAL_SERVER_ERROR';
    let errorMessage = 'An unexpected error occurred';
    let details: any = null;

    if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
      const respObj = exceptionResponse as Record<string, any>;
      errorMessage = respObj.message || errorMessage;
      errorCode = respObj.error || `HTTP_${status}`;
      if (Array.isArray(respObj.message)) {
        errorCode = 'VALIDATION_ERROR';
        details = respObj.message;
        errorMessage = 'Validation failed for the request payload';
      }
    } else if (typeof exceptionResponse === 'string') {
      errorMessage = exceptionResponse;
    } else if (exception instanceof Error) {
      errorMessage = exception.message;
    }

    this.logger.error(
      `[${request.method}] ${request.url} - Status ${status} - Error: ${errorMessage}`,
    );

    response.status(status).json({
      success: false,
      statusCode: status,
      error: {
        code: errorCode,
        message: errorMessage,
        details,
      },
      path: request.url,
      timestamp: new Date().toISOString(),
    });
  }
}
