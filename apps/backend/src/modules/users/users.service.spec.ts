import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { SupabaseService } from '../../database/supabase.service';

describe('UsersService', () => {
  let service: UsersService;
  let mockSupabaseService: Partial<SupabaseService>;

  const mockProfileRow = {
    id: 'test-user-id-123',
    full_name: 'Alex Mercer',
    base_currency: 'INR',
    biometric_enabled: true,
    month_start_day: 1,
    created_at: '2026-09-18T20:00:00.000Z',
    updated_at: '2026-09-18T20:00:00.000Z',
  };

  beforeEach(async () => {
    mockSupabaseService = {
      getAdminClient: jest.fn().mockReturnValue({
        from: jest.fn().mockImplementation((tableName: string) => {
          return {
            select: jest.fn().mockReturnValue({
              eq: jest.fn().mockReturnValue({
                single: jest.fn().mockResolvedValue({
                  data: mockProfileRow,
                  error: null,
                }),
              }),
            }),
            update: jest.fn().mockReturnValue({
              eq: jest.fn().mockReturnValue({
                select: jest.fn().mockReturnValue({
                  single: jest.fn().mockResolvedValue({
                    data: { ...mockProfileRow, full_name: 'Updated Name', base_currency: 'USD' },
                    error: null,
                  }),
                }),
              }),
            }),
          };
        }),
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: SupabaseService, useValue: mockSupabaseService },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should retrieve user profile correctly', async () => {
    const profile = await service.getProfile('test-user-id-123');

    expect(profile).toBeDefined();
    expect(profile.id).toBe('test-user-id-123');
    expect(profile.fullName).toBe('Alex Mercer');
    expect(profile.baseCurrency).toBe('INR');
    expect(profile.biometricEnabled).toBe(true);
  });

  it('should update user profile successfully', async () => {
    const updated = await service.updateProfile('test-user-id-123', {
      fullName: 'Updated Name',
      baseCurrency: 'USD',
    });

    expect(updated.fullName).toBe('Updated Name');
    expect(updated.baseCurrency).toBe('USD');
  });
});
