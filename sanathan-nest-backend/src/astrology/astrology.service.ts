import { Injectable, Logger, HttpException, HttpStatus } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';
import axios from 'axios';

@Injectable()
export class AstrologyService {
  private readonly logger = new Logger(AstrologyService.name);
  private readonly baseUrl = 'https://api.vedicastroapi.com/v3-json';

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Cron job that runs daily at Midnight India Standard Time (IST).
   * Midnight IST = 18:30 UTC.
   */
  @Cron('30 18 * * *')
  async handleDailyMidnightSync() {
    this.logger.log('Starting Daily Midnight IST Horoscope & Panchang Caching Cycle...');
    const todayStr = this.getTodayDateString();

    const signs = [
      'aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo',
      'libra', 'scorpio', 'sagittarius', 'capricorn', 'aquarius', 'pisces'
    ];
    const languages = ['en', 'hi'];

    for (const lang of languages) {
      for (const sign of signs) {
        try {
          const cacheKey = `horoscope:${sign}:${lang}`;
          
          // Check if already cached
          const existing = await this.prisma.cachedAstrology.findUnique({
            where: {
              type_key_date: {
                type: 'HOROSCOPE',
                key: cacheKey,
                date: todayStr,
              },
            },
          });

          if (existing) continue;

          // Fetch from API or mock fallback
          const data = await this.fetchHoroscopeFromApi(sign, lang, todayStr);
          
          await this.prisma.cachedAstrology.create({
            data: {
              type: 'HOROSCOPE',
              key: cacheKey,
              date: todayStr,
              data: JSON.stringify(data),
            },
          });

          this.logger.log(`Successfully cached ${cacheKey} for ${todayStr}`);
        } catch (error) {
          this.logger.error(`Failed to pre-cache horoscope for ${sign} (${lang}): ${error.message}`);
        }
      }
    }

    // Pre-cache Panchang for primary locations
    const majorLocations = [
      { name: 'delhi', lat: 28.6139, lon: 77.2090, tz: 5.5 },
      { name: 'mumbai', lat: 19.0760, lon: 72.8777, tz: 5.5 },
      { name: 'bengaluru', lat: 12.9716, lon: 77.5946, tz: 5.5 }
    ];

    for (const loc of majorLocations) {
      try {
        const cacheKey = `panchang:${loc.name}`;
        const existing = await this.prisma.cachedAstrology.findUnique({
          where: {
            type_key_date: {
              type: 'PANCHANG',
              key: cacheKey,
              date: todayStr,
            },
          },
        });

        if (existing) continue;

        const panchangData = await this.fetchPanchangFromApi(loc.lat, loc.lon, loc.tz, todayStr);

        await this.prisma.cachedAstrology.create({
          data: {
            type: 'PANCHANG',
            key: cacheKey,
            date: todayStr,
            data: JSON.stringify(panchangData),
          },
        });
        this.logger.log(`Successfully pre-cached Panchang for ${loc.name} on ${todayStr}`);
      } catch (error) {
        this.logger.error(`Failed to pre-cache Panchang for ${loc.name}: ${error.message}`);
      }
    }
    
    this.logger.log('Daily Midnight IST Astrology Caching completed.');
  }

  /**
   * Retrieves the daily horoscope. Serves from cache or makes an on-demand API call.
   */
  async getDailyHoroscope(sign: string, lang: string): Promise<any> {
    const todayStr = this.getTodayDateString();
    const cacheKey = `horoscope:${sign.toLowerCase()}:${lang.toLowerCase()}`;

    // Read from DB Cache
    const cached = await this.prisma.cachedAstrology.findUnique({
      where: {
        type_key_date: {
          type: 'HOROSCOPE',
          key: cacheKey,
          date: todayStr,
        },
      },
    });

    if (cached) {
      return JSON.parse(cached.data);
    }

    // Cache Miss -> Fetch and Save
    this.logger.log(`Cache miss for ${cacheKey} on ${todayStr}. Fetching on-demand...`);
    const data = await this.fetchHoroscopeFromApi(sign, lang, todayStr);

    try {
      await this.prisma.cachedAstrology.create({
        data: {
          type: 'HOROSCOPE',
          key: cacheKey,
          date: todayStr,
          data: JSON.stringify(data),
        },
      });
    } catch (e) {
      // Handle concurrent writes
    }

    return data;
  }

  /**
   * Retrieves Panchang for specific coordinates. Serves from cache if requested before today,
   * otherwise makes an API call and stores the response.
   */
  async getPanchang(lat: number, lon: number, timezone: number): Promise<any> {
    const todayStr = this.getTodayDateString();
    // Cache coordinates rounded to 2 decimal places to capture close proximity requests
    const latRounded = Math.round(lat * 100) / 100;
    const lonRounded = Math.round(lon * 100) / 100;
    const cacheKey = `panchang:${latRounded}:${lonRounded}`;

    const cached = await this.prisma.cachedAstrology.findUnique({
      where: {
        type_key_date: {
          type: 'PANCHANG',
          key: cacheKey,
          date: todayStr,
        },
      },
    });

    if (cached) {
      return JSON.parse(cached.data);
    }

    this.logger.log(`Cache miss for Panchang at ${latRounded}, ${lonRounded} on ${todayStr}. Fetching on-demand...`);
    const data = await this.fetchPanchangFromApi(lat, lon, timezone, todayStr);

    try {
      await this.prisma.cachedAstrology.create({
        data: {
          type: 'PANCHANG',
          key: cacheKey,
          date: todayStr,
          data: JSON.stringify(data),
        },
      });
    } catch (e) {
      // Handle concurrent writes
    }

    return data;
  }

  /**
   * Proxy endpoint for dynamic Personal Kundali generations.
   * Enforces monthly quota (2 free per month) and dynamic premium charges (₹49 per change).
   */
  async generatePersonalKundali(userId: string, birthData: {
    name: string;
    gender: string;
    dob: string; // DD/MM/YYYY
    tob: string; // HH:MM
    lat: number;
    lon: number;
    tz: number;
  }): Promise<any> {
    // 1. Quota Check
    const profile = await this.prisma.profile.findUnique({
      where: { userId },
    });

    if (!profile) {
      throw new HttpException('User profile not found. Please create a profile first.', HttpStatus.BAD_REQUEST);
    }

    const now = new Date();
    const currentMonth = now.getMonth();
    const currentYear = now.getFullYear();

    // Reset quota if we entered a new calendar month
    let changesThisMonth = profile.kundaliChangesThisMonth;
    const lastChange = profile.lastKundaliChangeAt;

    if (lastChange) {
      const lastChangeDate = new Date(lastChange);
      if (lastChangeDate.getMonth() !== currentMonth || lastChangeDate.getFullYear() !== currentYear) {
        changesThisMonth = 0;
      }
    }

    const freeLimit = 2;
    const chargeAmount = 49.00; // INR ₹49

    if (changesThisMonth >= freeLimit) {
      // Requires payment! Check wallet balance
      const wallet = await this.prisma.wallet.findUnique({
        where: { userId },
      });

      if (!wallet || wallet.balance < chargeAmount) {
        throw new HttpException({
          statusCode: HttpStatus.PAYMENT_REQUIRED,
          message: 'You have used your 2 free monthly calculations. Please recharge your wallet to proceed.',
          requiredAmount: chargeAmount,
          currentBalance: wallet ? wallet.balance : 0,
        }, HttpStatus.PAYMENT_REQUIRED);
      }

      // Deduct Wallet Balance
      await this.prisma.$transaction([
        this.prisma.wallet.update({
          where: { userId },
          data: { balance: { decrement: chargeAmount } },
        }),
        this.prisma.transaction.create({
          data: {
            walletId: wallet.id,
            amount: chargeAmount,
            type: 'DEBIT',
            status: 'COMPLETED',
            description: 'Premium Astro Calculations Charge (Kundali Update)',
          },
        }),
        this.prisma.profile.update({
          where: { userId },
          data: {
            kundaliChangesThisMonth: changesThisMonth + 1,
            lastKundaliChangeAt: now,
            dateOfBirth: this.parseDate(birthData.dob),
            timeOfBirth: birthData.tob,
            placeOfBirth: 'Selected Coordinates',
            latitude: birthData.lat,
            longitude: birthData.lon,
            timezone: birthData.tz.toString(),
          },
        }),
      ]);
      
      this.logger.log(`User ${userId} charged ₹${chargeAmount} for Kundali calculation.`);
    } else {
      // Increments Free Quota
      await this.prisma.profile.update({
        where: { userId },
        data: {
          kundaliChangesThisMonth: changesThisMonth + 1,
          lastKundaliChangeAt: now,
          dateOfBirth: this.parseDate(birthData.dob),
          timeOfBirth: birthData.tob,
          placeOfBirth: 'Selected Coordinates',
          latitude: birthData.lat,
          longitude: birthData.lon,
          timezone: birthData.tz.toString(),
        },
      });
      this.logger.log(`User ${userId} utilized free calculation slot. Slots used: ${changesThisMonth + 1}/2`);
    }

    // 2. Fetch from Vedicastro API
    return await this.fetchKundaliFromApi(birthData.dob, birthData.tob, birthData.lat, birthData.lon, birthData.tz);
  }

  // --- PRIVATE UTILITIES & API INTEGRATIONS ---

  private getTodayDateString(): string {
    const now = new Date();
    const yyyy = now.getFullYear();
    const mm = String(now.getMonth() + 1).padStart(2, '0');
    const dd = String(now.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
  }

  private parseDate(dateStr: string): Date {
    // DD/MM/YYYY
    const parts = dateStr.split('/');
    if (parts.length === 3) {
      return new Date(parseInt(parts[2]), parseInt(parts[1]) - 1, parseInt(parts[0]));
    }
    return new Date();
  }

  private isApiConfigured(): boolean {
    const key = process.env.VEDICASTRO_API_KEY;
    return !!(key && key !== 'placeholder_vedicastro_api_key');
  }

  private async fetchHoroscopeFromApi(sign: string, lang: string, date: string): Promise<any> {
    if (!this.isApiConfigured()) {
      return this.getMockHoroscope(sign, lang);
    }

    try {
      const response = await axios.get(`${this.baseUrl}/prediction/daily-sun`, {
        params: {
          zodiac: sign.toLowerCase(),
          lang: lang.toLowerCase(),
          api_key: process.env.VEDICASTRO_API_KEY,
        },
      });
      return response.data;
    } catch (error) {
      this.logger.error(`Vedicastro API horoscope request failed: ${error.message}`);
      return this.getMockHoroscope(sign, lang);
    }
  }

  private async fetchPanchangFromApi(lat: number, lon: number, timezone: number, dateStr: string): Promise<any> {
    if (!this.isApiConfigured()) {
      return this.getMockPanchang(dateStr);
    }

    const parts = dateStr.split('-');
    const formattedDate = `${parts[2]}/${parts[1]}/${parts[0]}`;

    try {
      const response = await axios.get(`${this.baseUrl}/dashas/panchang`, {
        params: {
          date: formattedDate,
          lat: lat,
          lon: lon,
          tz: timezone,
          api_key: process.env.VEDICASTRO_API_KEY,
        },
      });
      return response.data;
    } catch (error) {
      this.logger.error(`Vedicastro API Panchang request failed: ${error.message}`);
      return this.getMockPanchang(dateStr);
    }
  }

  private async fetchKundaliFromApi(dob: string, tob: string, lat: number, lon: number, tz: number): Promise<any> {
    if (!this.isApiConfigured()) {
      return this.getMockKundali(dob, tob);
    }

    try {
      const response = await axios.get(`${this.baseUrl}/horoscope/chart`, {
        params: {
          dob: dob,
          tob: tob,
          lat: lat,
          lon: lon,
          tz: tz,
          chart_id: 'D1',
          api_key: process.env.VEDICASTRO_API_KEY,
        },
      });
      return response.data;
    } catch (error) {
      this.logger.error(`Vedicastro API Kundali request failed: ${error.message}`);
      return this.getMockKundali(dob, tob);
    }
  }

  // --- REPUTABLE SPIRITUAL MOCK DATA GENERATORS ---

  private getMockHoroscope(sign: string, lang: string): any {
    const isEn = lang.toLowerCase() === 'en';
    const predictions = {
      aries: {
        en: 'Today calls for dynamic spiritual action. A solar alignment in your ascendant house sparks deep inner wisdom. Focus on deep breathing exercises during sunrise to harvest maximum energy.',
        hi: 'आज का दिन आध्यात्मिक ऊर्जा से भरपूर रहेगा। आपकी सूर्य स्थिति सूर्योदय के समय गहरी आंतरिक शक्ति प्रदान करेगी। मंत्र जाप से मन शांत रहेगा।'
      },
      taurus: {
        en: 'Financial clarity manifests through calm patience. Avoid rushed material commitments. An evening meditation centered on grounded root chakras brings intense clarity.',
        hi: 'आर्थिक स्थिति में स्थिरता आएगी। जल्दबाजी में निर्णय न लें। संध्या के समय शिव आराधना से मानसिक शांति मिलेगी।'
      },
      gemini: {
        en: 'Your intellectual capacity and creative aura are highly illuminated. A transit in Mercury creates harmonious conversations with spiritual guides or elders.',
        hi: 'बौद्धिक क्षमता और रचनात्मकता में वृद्धि होगी। बुध का गोचर बड़े बुजुर्गों और आध्यात्मिक गुरुओं से मार्गदर्शन दिलाएगा।'
      },
      cancer: {
        en: 'The moon enhances your intuitive flow. Spiritual alignment is high. Practice gratitude and offer water to the rising sun to strengthen emotional health.',
        hi: 'चंद्रमा आपकी संवेदनशीलता को बढ़ाएगा। सूर्य देव को जल अर्पित करने से मानसिक तनाव दूर होगा और ऊर्जा में वृद्धि होगी।'
      },
      leo: {
        en: 'Sun rays channel vital energy directly to your solar plexus. It is an auspicious day to begin new sacred learning, sloka memorization, or healthy lifestyle regimens.',
        hi: 'सूर्य की किरणें आपके आत्मविश्वास को बढ़ाएंगी। आज नए ग्रंथ, श्लोक या शुभ कार्यों की शुरुआत के लिए उत्तम दिन है।'
      },
      virgo: {
        en: 'Pragmatic organization of spiritual routines leads to inner freedom. Dedicate twenty minutes to quiet reading of scriptural commentary to ease your mind.',
        hi: 'नियमित पूजा-पाठ से मन में पवित्र विचार आएंगे। आज धार्मिक पुस्तकों के अध्ययन से ज्ञान की प्राप्ति होगी और मन शांत रहेगा।'
      },
      libra: {
        en: 'Harmonious relationship transits bring beautiful connections. A peaceful sanctuary is created by burning pure sandalwood incense and focusing on balancing breath.',
        hi: 'पारिवारिक संबंधों में मधुरता आएगी। चंदन की सुगंध और नियमित प्राणायाम से मानसिक संतुलन बना रहेगा।'
      },
      scorpio: {
        en: 'Transformation is occurring deep inside your spiritual core. Embrace changes with absolute surrender (Sharanagati). Recite the Maha Mrityunjaya mantra for protection.',
        hi: 'आपके भीतर गहरे बदलाव आ रहे हैं। ईश्वर के प्रति पूर्ण समर्पण का भाव रखें। महामृत्युंजय मंत्र का जाप शुभ फल देगा।'
      },
      sagittarius: {
        en: 'Jupiter blesses your wisdom house. Spiritual journeys, virtual pilgrimages, or listening to philosophical discourses will reward your soul immensely today.',
        hi: 'गुरु बृहस्पति की कृपा से ज्ञान में वृद्धि होगी। आज सत्संग सुनने या तीर्थ यात्रा पर विचार करने से मन को शांति मिलेगी।'
      },
      capricorn: {
        en: 'Patience and disciplined Seva (selfless service) unlock Saturnian blessings. Dedicate a small gesture of charity or feed animals to ground your energetic field.',
        hi: 'शनि देव की कृपा से सेवा भाव बढ़ेगा। गरीबों की सहायता करें अथवा पशु-पक्षियों को भोजन खिलाने से भाग्य उदय होगा।'
      },
      aquarius: {
        en: 'Universal consciousness flows through your innovative thoughts. Share spiritual kindness. Pray for global wellness with a peaceful heart.',
        hi: 'विश्व कल्याण की भावना आपके मन में रहेगी। शांत मन से की गई प्रार्थना आज अवश्य स्वीकार होगी और शांति मिलेगी।'
      },
      pisces: {
        en: 'Grounded meditations prevent overwhelming emotions from draining your spirit. Focus on visualization of golden light surrounding your body for supreme protection.',
        hi: 'भावुकता से बचें और ध्यान में समय बिताएं। अपने शरीर के चारों ओर दिव्य प्रकाश की कल्पना करें, जिससे नकारात्मक ऊर्जा दूर होगी।'
      }
    };

    const pred = predictions[sign.toLowerCase()] || predictions['aries'];
    const text = pred[lang.toLowerCase()] || pred['en'];

    return {
      status: 'success',
      zodiac: sign,
      prediction: text,
      color: 'Solar Amber & Cosmic Blue',
      lucky_number: 7,
      lucky_time: '06:00 AM - 08:30 AM',
      remedy: isEn ? 'Recite Gayatri Mantra 11 times in the morning.' : 'प्रातःकाल 11 बार गायत्री मंत्र का जाप करें।'
    };
  }

  private getMockPanchang(dateStr: string): any {
    return {
      status: 'success',
      date: dateStr,
      tithi: 'Shukla Ekadashi',
      nakshatra: 'Rohini',
      karana: 'Bava',
      yoga: 'Harshana',
      sunrise: '05:42 AM',
      sunset: '07:05 PM',
      moonrise: '03:15 PM',
      moonset: '02:40 AM',
      rahukaal: '01:30 PM - 03:00 PM',
      abhijit_muhurat: '11:50 AM - 12:40 PM',
      disclaimer: 'Calculated for default capital coordinates. Synchronized offline.'
    };
  }

  private getMockKundali(dob: string, tob: string): any {
    return {
      status: 'success',
      dob,
      tob,
      ascendant: 'Leo',
      rashi: 'Sagittarius',
      nakshatra: 'Moola',
      planets: [
        { name: 'Sun', house: 1, sign: 'Leo', degree: 14.5 },
        { name: 'Moon', house: 5, sign: 'Sagittarius', degree: 22.1 },
        { name: 'Mars', house: 10, sign: 'Taurus', degree: 4.8 },
        { name: 'Mercury', house: 1, sign: 'Leo', degree: 28.2 },
        { name: 'Jupiter', house: 9, sign: 'Aries', degree: 18.9 },
        { name: 'Venus', house: 12, sign: 'Cancer', degree: 9.3 },
        { name: 'Saturn', house: 7, sign: 'Aquarius', degree: 11.2 },
        { name: 'Rahu', house: 8, sign: 'Pisces', degree: 1.4 },
        { name: 'Ketu', house: 2, sign: 'Virgo', degree: 1.4 }
      ],
      charts: {
        D1: [
          { house: 1, planets: ['Sun', 'Mercury'] },
          { house: 2, planets: ['Ketu'] },
          { house: 3, planets: [] },
          { house: 4, planets: [] },
          { house: 5, planets: ['Moon'] },
          { house: 6, planets: [] },
          { house: 7, planets: ['Saturn'] },
          { house: 8, planets: ['Rahu'] },
          { house: 9, planets: ['Jupiter'] },
          { house: 10, planets: ['Mars'] },
          { house: 11, planets: [] },
          { house: 12, planets: ['Venus'] }
        ]
      }
    };
  }
}
