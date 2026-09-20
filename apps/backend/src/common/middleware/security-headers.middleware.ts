import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';

@Injectable()
export class SecurityHeadersMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    // 1. Obfuscate backend runtime
    res.removeHeader('X-Powered-By');

    // 2. Prevent clickjacking & framing attacks
    res.setHeader('X-Frame-Options', 'DENY');

    // 3. Prevent MIME sniffing
    res.setHeader('X-Content-Type-Options', 'nosniff');

    // 4. Cross-site scripting (XSS) filter
    res.setHeader('X-XSS-Protection', '1; mode=block');

    // 5. Enforce referrer policy
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');

    // 6. HTTP Strict Transport Security (HSTS)
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');

    next();
  }
}
