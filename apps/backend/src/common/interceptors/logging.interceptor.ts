import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const req = context.switchToHttp().getRequest();
    const { method, originalUrl, ip } = req;
    const userAgent = req.get('user-agent') || 'Unknown Device';
    const now = Date.now();

    return next.handle().pipe(
      tap({
        next: () => {
          const res = context.switchToHttp().getResponse();
          const statusCode = res.statusCode;
          const delay = Date.now() - now;
          this.logger.log(
            `[${method}] ${originalUrl} -> ${statusCode} +${delay}ms | IP: ${ip} | UA: ${userAgent.substring(0, 40)}`,
          );
        },
        error: (err) => {
          const delay = Date.now() - now;
          const status = err.status || 500;
          this.logger.warn(
            `[${method}] ${originalUrl} -> ${status} (${err.message}) +${delay}ms | IP: ${ip}`,
          );
        },
      }),
    );
  }
}
