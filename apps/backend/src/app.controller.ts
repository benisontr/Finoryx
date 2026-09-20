import { Controller, Get } from '@nestjs/common';
import { Public } from './common/decorators/public.decorator';

@Controller()
export class AppController {
  private readonly startTime = Date.now();

  @Public()
  @Get()
  getRoot() {
    return {
      status: 'ok',
      service: 'finoryx-backend',
      version: '1.0.0',
      message: 'Finoryx AI Personal Finance OS API is running 🚀',
      endpoints: {
        health: '/api/v1/health',
        docs: '/api/v1',
      },
      timestamp: new Date().toISOString(),
    };
  }

  @Public()
  @Get('health')
  getHealth() {
    const uptimeSeconds = Math.floor((Date.now() - this.startTime) / 1000);
    return {
      status: 'ok',
      service: 'finoryx-backend',
      version: '1.0.0',
      uptime: `${uptimeSeconds}s`,
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV || 'development',
    };
  }
}
