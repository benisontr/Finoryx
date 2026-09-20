import { CategoryType } from '../dto/create-category.dto';

export class CategoryEntity {
  id: string;
  userId?: string | null;
  name: string;
  icon: string;
  colorHex: string;
  type: CategoryType;
  parentId?: string | null;
  isSystem: boolean;
  createdAt: string;
  updatedAt: string;

  static fromRow(row: any): CategoryEntity {
    return {
      id: row.id,
      userId: row.user_id,
      name: row.name,
      icon: row.icon,
      colorHex: row.color_hex,
      type: row.type as CategoryType,
      parentId: row.parent_id,
      isSystem: row.is_system,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }
}
