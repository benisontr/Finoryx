import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { ApiResponse } from '../dto/api-response.dto';

@Injectable()
export class TransformResponseInterceptor<T>
  implements NestInterceptor<T, ApiResponse<T>>
{
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<ApiResponse<T>> {
    const ctx = context.switchToHttp();
    const response = ctx.getResponse();
    const statusCode = response.statusCode;

    return next.handle().pipe(
      map((data) => {
        // If data is already an instance of ApiResponse or contains special meta
        if (data && typeof data === 'object' && 'data' in data && 'meta' in data) {
          return new ApiResponse(data.data, statusCode, data.meta);
        }
        if (data && typeof data === 'object' && 'success' in data) {
          return data;
        }
        return new ApiResponse(data, statusCode);
      }),
    );
  }
}
