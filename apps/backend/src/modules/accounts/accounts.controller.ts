import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AccountsService } from './accounts.service';
import { CreateAccountDto, UpdateAccountDto } from './dto/create-account.dto';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';

@UseGuards(SupabaseAuthGuard)
@Controller('accounts')
export class AccountsController {
  constructor(private readonly accountsService: AccountsService) {}

  @Get()
  async getAccounts(
    @CurrentUser() user: AuthenticatedUser,
    @Query('includeArchived') includeArchived?: string,
  ) {
    const isIncludeArchived = includeArchived === 'true';
    return this.accountsService.getAccounts(user.id, isIncludeArchived);
  }

  @Get('summary')
  async getAccountsSummary(@CurrentUser() user: AuthenticatedUser) {
    return this.accountsService.getAccountsSummary(user.id);
  }

  @Get(':id')
  async getAccountById(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.accountsService.getAccountById(user.id, id);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createAccount(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateAccountDto,
  ) {
    return this.accountsService.createAccount(user.id, dto);
  }

  @Patch(':id')
  async updateAccount(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateAccountDto,
  ) {
    return this.accountsService.updateAccount(user.id, id, dto);
  }

  @Delete(':id')
  async deleteAccount(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.accountsService.deleteAccount(user.id, id);
  }
}
