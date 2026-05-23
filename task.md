# Sanathan Platform Rebuild - Migration Checklist

This document acts as the living work tracker for our high-scale TypeScript (NestJS) + Supabase (PostgreSQL) + Redis + Qdrant + Flutter offline-first rebuild.

## Phase 0: Legacy Laravel Migration Discovery
- [x] Review legacy Laravel app folder end to end (`routes`, `app`, `database`, SQL dump)
- [x] Inventory legacy MySQL source schema (`astronew_dump.sql`, 154 tables)
- [x] Identify Flutter-facing API surfaces from `routes/api.php`
- [x] Capture migration plan in `docs/laravel-to-supabase-migration-plan.md`
- [x] Expand canonical Prisma schema for the first Supabase migration slice
- [ ] Create detailed endpoint compatibility matrix for Flutter apps
- [ ] Create Supabase migration files from canonical domain plan

## Phase 1: Backend Foundations (NestJS & Supabase)
- [x] Initialize NestJS strict TypeScript project workspace
- [x] Configure environment variables framework (.env base templates)
- [x] Create backend `.env` / `.env.example` for Supabase credentials and integration secrets
- [x] Add portable `.env.local.sample` for setting up keys on another PC
- [x] Register global ScheduleModule, ConfigModule, and PrismaModule in AppModule
- [x] Set up Supabase DB integration & Prisma schema
- [x] Design core schema models (User, Profile, Wallet, Transaction, Waitlist, CachedAstrology)
- [x] Compile type-safe DB adapter classes using `npx prisma generate` (Prisma v7.8.0)
- [ ] Generate PostgreSQL SQL migrations scripts for direct Supabase updates

## Phase 2: Caching & Core APIs (Cloudflare Ready)
- [x] Implement Daily Horoscope & Panchang Astrology Module
  - [x] Cron schedule (Midnight IST / 18:30 UTC) for predictions caching
  - [x] Proximity-based on-demand coordinate rounding & caching (lat/lon to 2 decimals)
  - [x] Dynamic calculation limit checking (2 free calculations per calendar month)
  - [x] In-DB wallet balance debit transaction (₹49) on paid calculation overages
  - [x] Elegant spiritual predictions mock backup fallback for local testing
  - [x] Inject aggressive CDN Edge caching headers (`public, max-age=43200, s-maxage=86400`)
- [ ] Implement Authenticated User & Wallet APIs
  - [x] Lazy authentication JWT validation filter and middleware
  - [x] Wallet balance and recharge quote endpoints
  - [x] Razorpay webhook payment controller & ledger transaction writer
  - [x] Stripe webhook payment controller & ledger transaction writer
  - [x] Cashfree webhook payment controller & ledger transaction writer
  - [x] USD-to-INR conversion factor support via config
  - [ ] Provider-specific payment order/intent creation endpoints
  - [ ] Raw-body signature hardening for production Stripe/Cashfree verification

## Phase 3: Real-Time Signaling Gateway (WebSockets)
- [ ] Configure NestJS WebSocket Socket.io Gateway
- [ ] Implement active consultations queue waitlist inside Redis sorted sets
- [ ] Implement peer-to-peer Kundali JSON payload forwarding over Socket
- [ ] Implement call connection signaling (Agora/Zego token dispatching)
- [ ] Implement Guruji availability/online status in-memory state tracker

## Phase 4: Spiritual AI & Scriptural RAG Engine
- [ ] Set up Qdrant vector database NestJS client
- [ ] Scriptural data injection pipelines (Vedas, Upanishads, Slokas, Pujas)
- [ ] Semantic query controller with cosine similarity score threshold check (Score > 0.78)
- [ ] Implement context-grounded LLM prompts wrap (Google Gemini fallback)
- [ ] Enforce Spiritual Safety Directives for off-scripture queries

## Phase 5: Spiritual Marketplace & Media V2
- [ ] Astromall physical remedies catalog APIs (Gemstones, Rudraksha inventory)
- [ ] Puja booking marketplace APIs (puja packages, subcategories, schedule mappings)
- [ ] Guruji Pujas recommendations APIs (linking recommended pujas to users)
- [ ] E-Learning courses player module APIs (stream indices, lesson progress trackers)
- [ ] Guruji stories catalog with automated 24-hour expiration locks

## Phase 6: Flutter Customer App (Offline-First Sync)
- [ ] Install and configure local Isar DB offline database
- [ ] Anonymity-first homepage pre-fetching data from Cloudflare CDN nodes
- [ ] Lazy authentication popup trigger (intercept wallet & connect chats only)
- [ ] Premium Glassmorphic cards UI overhaul featuring Outfit typography
- [ ] Socket waitlist queuing state frames and Agora voice/video players

## Phase 7: Flutter Guruji App (Consultations Dashboard)
- [ ] Partner WebSockets client wiring for real-time waitlists incoming pings
- [ ] Native radial Kundali chart widget drawing houses from shared JSON payloads
- [ ] In-chat vector search scriptural helper drawer (Pujas & Slokas copying tool)
- [ ] Astrologer earnings ledger list and withdraw payout request sheet

## Phase 8: Testing & Verification
- [ ] Run high-concurrency waitlist locks stress tests (using K6 scripts)
- [ ] Validate Cloudflare `CF-Cache-Status` HIT headers in production endpoints
- [ ] Verify local offline DB rendering by launching app in airplane mode
- [ ] Produce walkthough.md walk-through documentation
