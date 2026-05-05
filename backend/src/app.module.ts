import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TranslationModule } from './translation/translation.module';
import { TranslationCache } from './translation/translation.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: () => ({
        type: 'sqljs',
        location: 'data/utagoto.db',
        autoSave: true,
        entities: [TranslationCache],
        synchronize: true,
      }),
    }),
    TranslationModule,
  ],
})
export class AppModule {}
