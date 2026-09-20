import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { SupabaseService } from '../../database/supabase.service';
import { CreateCategoryDto, UpdateCategoryDto, CategoryType } from './dto/create-category.dto';
import { CategoryEntity } from './entities/category.entity';
import { MemoryCache } from '../../common/utils/cache.util';

@Injectable()
export class CategoriesService {
  private readonly logger = new Logger(CategoriesService.name);
  private readonly categoryCache = new MemoryCache<CategoryEntity[]>(120); // 2 minute cache

  constructor(private readonly supabaseService: SupabaseService) {}

  async getCategories(userId: string, type?: CategoryType): Promise<CategoryEntity[]> {
    const cacheKey = `${userId}-${type || 'all'}`;
    const cached = this.categoryCache.get(cacheKey);
    if (cached) {
      return cached;
    }

    const supabase = this.supabaseService.getAdminClient();

    let query = supabase
      .from('categories')
      .select('*')
      .or(`is_system.eq.true,user_id.eq.${userId}`)
      .order('is_system', { ascending: false })
      .order('name', { ascending: true });

    if (type) {
      query = query.eq('type', type);
    }

    const { data, error } = await query;

    if (error) {
      this.logger.error(`Failed to fetch categories for user ${userId}: ${error.message}`);
      throw new InternalServerErrorException(error.message);
    }

    const categories = (data || []).map(CategoryEntity.fromRow);
    this.categoryCache.set(cacheKey, categories);
    return categories;
  }

  async getCategoryById(userId: string, categoryId: string): Promise<CategoryEntity> {
    const supabase = this.supabaseService.getAdminClient();

    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('id', categoryId)
      .or(`is_system.eq.true,user_id.eq.${userId}`)
      .single();

    if (error || !data) {
      throw new NotFoundException(`Category with ID '${categoryId}' not found`);
    }

    return CategoryEntity.fromRow(data);
  }

  async createCustomCategory(userId: string, dto: CreateCategoryDto): Promise<CategoryEntity> {
    const supabase = this.supabaseService.getAdminClient();

    const { data, error } = await supabase
      .from('categories')
      .insert({
        user_id: userId,
        name: dto.name,
        icon: dto.icon,
        color_hex: dto.colorHex,
        type: dto.type,
        parent_id: dto.parentId ?? null,
        is_system: false,
      })
      .select('*')
      .single();

    if (error) {
      this.logger.error(`Failed to create category for user ${userId}: ${error.message}`);
      throw new BadRequestException(error.message);
    }

    this.categoryCache.clear();
    return CategoryEntity.fromRow(data);
  }

  async updateCategory(
    userId: string,
    categoryId: string,
    dto: UpdateCategoryDto,
  ): Promise<CategoryEntity> {
    const category = await this.getCategoryById(userId, categoryId);

    if (category.isSystem) {
      throw new ForbiddenException('System categories cannot be modified');
    }

    if (category.userId !== userId) {
      throw new ForbiddenException('You do not have permission to modify this category');
    }

    const supabase = this.supabaseService.getAdminClient();

    const updates: Record<string, any> = {};
    if (dto.name !== undefined) updates.name = dto.name;
    if (dto.icon !== undefined) updates.icon = dto.icon;
    if (dto.colorHex !== undefined) updates.color_hex = dto.colorHex;
    if (dto.parentId !== undefined) updates.parent_id = dto.parentId;

    const { data, error } = await supabase
      .from('categories')
      .update(updates)
      .eq('id', categoryId)
      .eq('user_id', userId)
      .select('*')
      .single();

    if (error) {
      this.logger.error(`Failed to update category ${categoryId}: ${error.message}`);
      throw new InternalServerErrorException(error.message);
    }

    this.categoryCache.clear();
    return CategoryEntity.fromRow(data);
  }

  async deleteCategory(userId: string, categoryId: string): Promise<{ success: boolean; message: string }> {
    const category = await this.getCategoryById(userId, categoryId);

    if (category.isSystem) {
      throw new ForbiddenException('System categories cannot be deleted');
    }

    if (category.userId !== userId) {
      throw new ForbiddenException('You do not have permission to delete this category');
    }

    const supabase = this.supabaseService.getAdminClient();

    const { error } = await supabase
      .from('categories')
      .delete()
      .eq('id', categoryId)
      .eq('user_id', userId);

    if (error) {
      this.logger.error(`Failed to delete category ${categoryId}: ${error.message}`);
      throw new InternalServerErrorException(error.message);
    }

    this.categoryCache.clear();
    return {
      success: true,
      message: 'Category successfully deleted',
    };
  }
}
