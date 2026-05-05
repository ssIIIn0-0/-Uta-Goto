import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { createHash } from 'crypto';
import OpenAI from 'openai';
import { ConfigService } from '@nestjs/config';
import { TranslationCache } from './translation.entity';

@Injectable()
export class TranslationService {
  private openai: OpenAI;

  constructor(
    @InjectRepository(TranslationCache)
    private cacheRepo: Repository<TranslationCache>,
    private config: ConfigService,
  ) {
    this.openai = new OpenAI({
      apiKey: this.config.get<string>('OPENAI_API_KEY'),
    });
  }

  async translateLyrics(
    lyrics: string[],
    songId?: string,
  ): Promise<{ original: string; literal: string; natural: string }[]> {
    const hash = this.hashLyrics(lyrics);

    const cached = await this.cacheRepo.findOne({
      where: { lyricsHash: hash },
    });
    if (cached) return cached.translations;

    const translations = await this.callOpenAI(lyrics);

    await this.cacheRepo.save({
      songId: songId ?? undefined,
      lyricsHash: hash,
      translations,
    });

    return translations;
  }

  private hashLyrics(lyrics: string[]): string {
    return createHash('sha256').update(lyrics.join('\n')).digest('hex');
  }

  private async callOpenAI(
    lyrics: string[],
  ): Promise<{ original: string; literal: string; natural: string }[]> {
    const numbered = lyrics
      .map((line, i) => `${i + 1}. ${line}`)
      .join('\n');

    const response = await this.openai.chat.completions.create({
      model: 'gpt-4o-mini',
      temperature: 0.3,
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content: `당신은 일본어 노래 가사를 한국어로 번역하는 전문 번역가입니다.
각 줄에 대해 두 가지 번역을 제공하세요:
1. literal: 직역 (원문의 단어/문법 구조를 최대한 유지)
2. natural: 자연스러운 의역 (한국어로 자연스럽게)

빈 줄은 literal과 natural 모두 빈 문자열로 반환하세요.

JSON 형식으로 반환:
{
  "translations": [
    { "line": 1, "literal": "...", "natural": "..." }
  ]
}`,
        },
        {
          role: 'user',
          content: numbered,
        },
      ],
    });

    const content = response.choices[0]?.message?.content ?? '{}';
    const parsed = JSON.parse(content);

    return lyrics.map((original, i) => {
      const item = parsed.translations?.find(
        (t: { line: number }) => t.line === i + 1,
      );
      return {
        original,
        literal: item?.literal ?? '',
        natural: item?.natural ?? '',
      };
    });
  }
}
