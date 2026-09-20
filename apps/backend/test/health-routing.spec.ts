import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AppController } from '../src/app.controller';

describe('Health & Global Prefix Routing', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          load: [() => ({ port: 3000, apiPrefix: 'api/v1' })],
        }),
      ],
      controllers: [AppController],
    }).compile();

    app = moduleRef.createNestApplication();
    const configService = app.get(ConfigService);
    const apiPrefix = configService.get<string>('apiPrefix', 'api/v1');

    app.setGlobalPrefix(apiPrefix, {
      exclude: ['/', 'health', `${apiPrefix}/health`, 'api/v1/health'],
    });

    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('should have AppController responding with status ok', () => {
    const controller = app.get<AppController>(AppController);
    expect(controller.getRoot().status).toBe('ok');
    expect(controller.getHealth().status).toBe('ok');
    expect(controller.getApiHealth().status).toBe('ok');
  });
});
