export class PaginationMetaDto {
  page: number;
  limit: number;
  totalItems: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPrevPage: boolean;
}

export class ApiResponse<T> {
  success: boolean;
  statusCode: number;
  data: T;
  meta?: PaginationMetaDto;
  timestamp: string;

  constructor(data: T, statusCode = 200, meta?: PaginationMetaDto) {
    this.success = true;
    this.statusCode = statusCode;
    this.data = data;
    if (meta) {
      this.meta = meta;
    }
    this.timestamp = new Date().toISOString();
  }
}
