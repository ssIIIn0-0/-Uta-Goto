import { IsArray, IsOptional, IsString } from 'class-validator';

export class TranslateLyricsDto {
  @IsOptional()
  @IsString()
  songId?: string;

  @IsArray()
  @IsString({ each: true })
  lyrics: string[];
}

export class TranslationResponseDto {
  translations: {
    original: string;
    literal: string;
    natural: string;
  }[];
}
