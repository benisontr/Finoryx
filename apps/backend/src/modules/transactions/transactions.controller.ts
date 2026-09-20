import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { TransactionsService } from './transactions.service';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { QueryTransactionsDto } from './dto/query-transactions.dto';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';

@UseGuards(SupabaseAuthGuard)
@Controller('transactions')
export class TransactionsController {
  constructor(private readonly transactionsService: TransactionsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createTransaction(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateTransactionDto,
  ) {
    return this.transactionsService.createTransaction(user.id, dto);
  }

  @Get()
  async getTransactions(
    @CurrentUser() user: AuthenticatedUser,
    @Query() queryDto: QueryTransactionsDto,
  ) {
    return this.transactionsService.getTransactions(user.id, queryDto);
  }

  @Get(':id')
  async getTransactionById(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.transactionsService.getTransactionById(user.id, id);
  }

  @Delete(':id')
  async deleteTransaction(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.transactionsService.deleteTransaction(user.id, id);
  }
}
