import { Body, Controller, Post, HttpException, HttpStatus } from '@nestjs/common';
import { TranslationService } from './translation.service';
import { TranslateLyricsDto, TranslationResponseDto } from './translation.dto';

@Controller('translate')
export class TranslationController {
  constructor(private readonly translationService: TranslationService) {}

  @Post('lyrics')
  async translateLyrics(
    @Body() dto: TranslateLyricsDto,
  ): Promise<TranslationResponseDto> {
    try {
      const translations = await this.translationService.translateLyrics(
        dto.lyrics,
        dto.songId,
      );
      return { translations };
    } catch (error: any) {
      if (error?.status === 429 || error?.code === 'insufficient_quota') {
        throw new HttpException(
          'OpenAI API 할당량 초과. 결제 설정을 확인하세요.',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
      throw new HttpException(
        '번역 중 오류가 발생했습니다.',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
