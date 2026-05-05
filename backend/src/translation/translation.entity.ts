import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index } from 'typeorm';

@Entity('translation_cache')
@Index(['lyricsHash'], { unique: true })
export class TranslationCache {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ nullable: true })
  songId: string;

  @Column()
  lyricsHash: string;

  @Column('simple-json')
  translations: { original: string; literal: string; natural: string }[];

  @CreateDateColumn()
  createdAt: Date;
}
