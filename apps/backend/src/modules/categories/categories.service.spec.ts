import { Test, TestingModule } from '@nestjs/testing';
import { CategoriesService } from './categories.service';
import { SupabaseService } from '../../database/supabase.service';
import { CategoryType } from './dto/create-category.dto';
import { ForbiddenException } from '@nestjs/common';

describe('CategoriesService', () => {
  let service: CategoriesService;
  let mockSupabaseService: Partial<SupabaseService>;

  const mockCategories = [
    {
      id: 'cat-sys-1',
      user_id: null,
      name: 'Food & Dining',
      icon: 'restaurant',
      color_hex: '#EF4444',
      type: 'expense',
      parent_id: null,
      is_system: true,
      created_at: '2026-09-18T20:00:00.000Z',
      updated_at: '2026-09-18T20:00:00.000Z',
    },
    {
      id: 'cat-usr-1',
      user_id: 'user-123',
      name: 'Specialty Coffee',
      icon: 'local_cafe',
      color_hex: '#8B5CF6',
      type: 'expense',
      parent_id: 'cat-sys-1',
      is_system: false,
      created_at: '2026-09-18T20:00:00.000Z',
      updated_at: '2026-09-18T20:00:00.000Z',
    },
  ];

  beforeEach(async () => {
    mockSupabaseService = {
      getAdminClient: jest.fn().mockReturnValue({
        from: jest.fn().mockReturnValue({
          select: jest.fn().mockReturnValue({
            or: jest.fn().mockReturnValue({
              order: jest.fn().mockReturnValue({
                order: jest.fn().mockResolvedValue({
                  data: mockCategories,
                  error: null,
                }),
              }),
            }),
            eq: jest.fn().mockReturnValue({
              or: jest.fn().mockReturnValue({
                single: jest.fn().mockImplementation(() => {
                  return Promise.resolve({
                    data: mockCategories[0],
                    error: null,
                  });
                }),
              }),
            }),
          }),
          insert: jest.fn().mockReturnValue({
            select: jest.fn().mockReturnValue({
              single: jest.fn().mockResolvedValue({
                data: mockCategories[1],
                error: null,
              }),
            }),
          }),
          update: jest.fn().mockReturnValue({
            eq: jest.fn().mockReturnValue({
              eq: jest.fn().mockReturnValue({
                select: jest.fn().mockReturnValue({
                  single: jest.fn().mockResolvedValue({
                    data: { ...mockCategories[1], name: 'Artisan Coffee' },
                    error: null,
                  }),
                }),
              }),
            }),
          }),
          delete: jest.fn().mockReturnValue({
            eq: jest.fn().mockReturnValue({
              eq: jest.fn().mockResolvedValue({ error: null }),
            }),
          }),
        }),
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CategoriesService,
        { provide: SupabaseService, useValue: mockSupabaseService },
      ],
    }).compile();

    service = module.get<CategoriesService>(CategoriesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should list categories including system and user custom categories', async () => {
    const categories = await service.getCategories('user-123');
    expect(categories).toBeDefined();
    expect(categories.length).toBe(2);
    expect(categories[0].isSystem).toBe(true);
    expect(categories[1].name).toBe('Specialty Coffee');
  });

  it('should create a custom category', async () => {
    const created = await service.createCustomCategory('user-123', {
      name: 'Specialty Coffee',
      icon: 'local_cafe',
      colorHex: '#8B5CF6',
      type: CategoryType.EXPENSE,
      parentId: 'cat-sys-1',
    });

    expect(created).toBeDefined();
    expect(created.name).toBe('Specialty Coffee');
    expect(created.isSystem).toBe(false);
  });

  it('should block deletion of system categories', async () => {
    // When trying to delete a system category (mocked cat-sys-1 with is_system=true)
    await expect(service.deleteCategory('user-123', 'cat-sys-1')).rejects.toThrow(
      ForbiddenException,
    );
  });
});
