import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service';
import { SupabaseService } from '../../database/supabase.service';

describe('AuthService', () => {
  let service: AuthService;
  let mockSupabaseService: Partial<SupabaseService>;

  const mockUser = {
    id: 'test-user-id-123',
    email: 'test@finoryx.io',
    user_metadata: { full_name: 'Test User' },
  };

  beforeEach(async () => {
    mockSupabaseService = {
      getClient: jest.fn().mockReturnValue({
        auth: {
          signUp: jest.fn().mockResolvedValue({
            data: { user: mockUser, session: { access_token: 'mock-access-token', refresh_token: 'mock-refresh-token' } },
            error: null,
          }),
          signInWithPassword: jest.fn().mockResolvedValue({
            data: { user: mockUser, session: { access_token: 'mock-access-token', refresh_token: 'mock-refresh-token' } },
            error: null,
          }),
        },
      }),
      getAdminClient: jest.fn().mockReturnValue({
        from: jest.fn().mockReturnValue({
          upsert: jest.fn().mockResolvedValue({ error: null }),
        }),
      }),
      getClientForUser: jest.fn().mockReturnValue({
        auth: {
          signOut: jest.fn().mockResolvedValue({ error: null }),
        },
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: SupabaseService, useValue: mockSupabaseService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should sign up a user successfully and return user with session', async () => {
    const result = await service.signUp({
      email: 'test@finoryx.io',
      password: 'SecurePassword123!',
      fullName: 'Test User',
      baseCurrency: 'INR',
    });

    expect(result).toHaveProperty('user');
    expect(result.user.id).toBe('test-user-id-123');
    expect(result.user.email).toBe('test@finoryx.io');
    expect(result.session).toHaveProperty('access_token');
  });

  it('should sign in a user successfully', async () => {
    const result = await service.signIn({
      email: 'test@finoryx.io',
      password: 'SecurePassword123!',
    });

    expect(result).toHaveProperty('user');
    expect(result.user.id).toBe('test-user-id-123');
    expect(result.session).toHaveProperty('access_token');
  });

  it('should sign out successfully', async () => {
    const result = await service.signOut('mock-access-token');
    expect(result).toEqual({ message: 'Successfully signed out' });
  });
});
