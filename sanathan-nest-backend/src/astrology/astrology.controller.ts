import { Controller, Get, Post, Body, Query, Res, HttpStatus, HttpException } from '@nestjs/common';
import * as express from 'express';
import { AstrologyService } from './astrology.service';

@Controller('api/v1/astrology')
export class AstrologyController {
  constructor(private readonly astrologyService: AstrologyService) {}

  /**
   * Public GET endpoint to retrieve the daily horoscope.
   * Leverages aggressive Cloudflare CDN edge caching via response headers.
   */
  @Get('horoscope')
  async getDailyHoroscope(
    @Query('sign') sign: string,
    @Query('lang') lang: string = 'en',
    @Res({ passthrough: true }) res: express.Response
  ) {
    if (!sign) {
      throw new HttpException('Zodiac sign query parameter is required', HttpStatus.BAD_REQUEST);
    }

    // Serve horoscope payload
    const data = await this.astrologyService.getDailyHoroscope(sign, lang);

    // Inject aggressive CDN Edge Caching headers
    // public: allow caching by all downstreams (browsers + Cloudflare edge)
    // max-age: browser cache limit (12 hours / 43200 seconds)
    // s-maxage: CDN edge cache limit (24 hours / 86400 seconds)
    res.setHeader('Cache-Control', 'public, max-age=43200, s-maxage=86400');
    
    return data;
  }

  /**
   * Public GET endpoint to retrieve the daily Panchang.
   * Leverages proximity edge caching coordinates mapping.
   */
  @Get('panchang')
  async getPanchang(
    @Query('lat') lat: string,
    @Query('lon') lon: string,
    @Query('tz') tz: string = '5.5',
    @Res({ passthrough: true }) res: express.Response
  ) {
    if (!lat || !lon) {
      throw new HttpException('Latitude (lat) and longitude (lon) query parameters are required', HttpStatus.BAD_REQUEST);
    }

    const latitude = parseFloat(lat);
    const longitude = parseFloat(lon);
    const timezone = parseFloat(tz);

    if (isNaN(latitude) || isNaN(longitude) || isNaN(timezone)) {
      throw new HttpException('Invalid coordinate or timezone formats', HttpStatus.BAD_REQUEST);
    }

    const data = await this.astrologyService.getPanchang(latitude, longitude, timezone);

    // Inject CDN Edge Caching headers
    res.setHeader('Cache-Control', 'public, max-age=43200, s-maxage=86400');

    return data;
  }

  /**
   * Dynamic POST endpoint to calculate or update a personal Kundali.
   * Involves JWT auth verification (placeholder user ID here for validation)
   * and enforces strict quota (2 free per month) / billing (₹49) gates.
   */
  @Post('kundali')
  async generatePersonalKundali(
    @Body() birthData: {
      userId: string; // Will come from lazy auth request extraction in production guards
      name: string;
      gender: string;
      dob: string; // DD/MM/YYYY
      tob: string; // HH:MM
      lat: number;
      lon: number;
      tz: number;
    }
  ) {
    if (!birthData.userId) {
      throw new HttpException('Authenticated User ID is required', HttpStatus.UNAUTHORIZED);
    }
    if (!birthData.dob || !birthData.tob || birthData.lat === undefined || birthData.lon === undefined) {
      throw new HttpException('Missing required birth credentials (dob, tob, lat, lon)', HttpStatus.BAD_REQUEST);
    }

    return await this.astrologyService.generatePersonalKundali(birthData.userId, birthData);
  }
}
