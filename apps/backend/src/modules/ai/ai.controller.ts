import { Controller, Post, Get, Body, UseGuards } from '@nestjs/common';
import { AiService } from './ai.service';
import { AiChatDto } from './dto/ai-chat.dto';
import { AffordabilityCheckDto } from './dto/affordability-check.dto';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('ai')
@UseGuards(SupabaseAuthGuard)
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('chat')
  async chat(
    @CurrentUser('id') userId: string,
    @Body() dto: AiChatDto,
  ) {
    return this.aiService.processChat(userId, dto);
  }

  @Post('affordability-check')
  async checkAffordability(
    @CurrentUser('id') userId: string,
    @Body() dto: AffordabilityCheckDto,
  ) {
    return this.aiService.checkAffordability(userId, dto);
  }

  @Get('insights')
  async getInsights(
    @CurrentUser('id') userId: string,
  ) {
    return this.aiService.getProactiveInsights(userId);
  }
}
