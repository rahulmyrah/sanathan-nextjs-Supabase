# Laravel to Supabase/NestJS Migration Plan

This project is a migration of the existing Laravel/MySQL Sanathan platform, not a greenfield rebuild. The legacy Laravel app and `astronew_dump.sql` are the source of truth for product scope, while the new stack should simplify operations and scale the hot paths.

## Source Review

Reviewed sources:

- `C:\Users\rahul\Desktop\Sanathan APP\Sanathan Web\astronew_dump.sql`
- `C:\Users\rahul\Desktop\Sanathan APP\Sanathan Web\database`
- `C:\Users\rahul\Desktop\Sanathan APP\Sanathan Web\routes`
- `C:\Users\rahul\Desktop\Sanathan APP\Sanathan Web\app\Http\Controllers`
- `C:\Users\rahul\Desktop\Sanathan APP\Sanathan Web\app\Models`
- `C:\Users\rahul\Desktop\Sanathan APP\Sanathan Web\app\services`

High-level findings:

- Legacy SQL dump contains 154 MySQL tables.
- Laravel has around 340 mobile/API route declarations in `routes/api.php`.
- Laravel has 140 model files.
- API controllers are mainly grouped under User, Astrologer, and AiAstrologer.
- Newer Laravel migrations already define Sanathan-specific AI, listing, Guruji, RAG, course tracking, listing payment, and verification tables.

## Product Domains to Preserve

The Supabase/Postgres schema should be derived from the existing domains:

1. Identity and lazy auth
   - Legacy tables: `users`, `user_roles`, `roles`, `user_device_details`, `defaultprofile`, `marital_statuses`.
   - New shape: Supabase Auth for OTP/session identity, public `users`/`profiles` for app metadata, device table for FCM/OneSignal tokens.

2. Guruji/astrologer marketplace
   - Legacy tables: `astrologers`, `astrologer_categories`, `astrologer_availabilities`, `astrologer_documents`, `astrologer_expertises`, `skills`, `astrologer_stories`, `astrologer_followers`.
   - New shape: typed Guruji profile/listing tables, availability, verification documents, skills/categories, stories with Redis/Supabase storage metadata.

3. Chat/call consultations
   - Legacy tables: `chatrequest`, `callrequest`, `waitlist`, `astrologer_wait_lists`, `intakeform`, `chats`, `user_chats`, `user_chat_histories`, `user_call_histories`, `call_request_apoinments`.
   - New shape: Postgres for durable consultation state and history; Redis sorted sets for active waitlists and presence; Socket.io for real-time transitions; optional compatibility endpoints for Flutter.

4. Wallet, payments, commissions, payouts
   - Legacy tables: `user_wallets`, `wallettransaction`, `payment`, `order_request`, `order_payments`, `admin_get_commissions`, `commissions`, `commission_types`, `withdrawrequest`, `withdraws`, `withdrawmethods`, `rechargeamount`.
   - New shape: transaction-safe wallet ledger, payment intents/orders, webhook events, commission ledger, payout requests, unique provider references.

5. Astrology, Kundali, horoscope, Panchang
   - Legacy tables: `kundalis`, `kundali_matchings`, `dailyhoroscope`, `dailyhoroscopeinsight`, `hororscope_signs`, `horoscopes`, `kundali_prices`.
   - New shape: cache-first public astrology tables, paid personalized calculation ledger, user quota fields, offline-first payloads for Flutter.

6. Marketplace, pujas, courses
   - Legacy tables: `astromall_products`, `product_categories`, `product_details`, `product_recommends`, `pujas`, `puja_categories`, `puja_subcategories`, `puja_package`, `puja_orders`, `puja_recommends`, `courses`, `course_categories`, `course_chapters`, `course_orders`.
   - New shape: normalized catalog tables with Postgres JSON fields for legacy flexible metadata, order tables tied to wallet/payment ledger.

7. Content, notifications, support
   - Legacy tables: `banners`, `banner_types`, `blogs`, `blog_categories`, `pages`, `web_home_faqs`, `notifications`, `user_notifications`, `user_notifications_scheduler`, `tickets`, `ticketreview`, `help_supports`, `help_support_quations`, `help_support_quation_answers`.
   - New shape: content CMS tables, notification jobs, support/ticket module.

8. AI and RAG
   - Laravel migrations already define `sanathan_ai_*`, `sanathan_knowledge_*`, `sanathan_guruji_*`.
   - New shape: preserve these concepts in Postgres, keep vector IDs in Postgres, store embeddings in Qdrant or pgvector depending cost/performance.

## API Strategy for Flutter

Yes, the Flutter customer app and Guruji app should call the new NestJS API.

Recommended approach:

- Do not force new Flutter apps to inherit every old Laravel endpoint name forever.
- For migration speed, create compatibility aliases for high-use old endpoints.
- For long-term health, create clean versioned APIs under `/api/v1`.

Example:

- Legacy alias: `POST /api/loginAppUser`
- New API: `POST /api/v1/auth/lazy-login`
- Legacy alias: `POST /api/chatRequest/add`
- New API: `POST /api/v1/consultations/chat/request`
- Legacy alias: `POST /api/getCustomerHome`
- New API: `GET /api/v1/home`

Flutter should consume the new APIs when we control the app code. Compatibility aliases are useful for testing old flows or reusing request/response contracts.

## Supabase Schema Strategy

Use Postgres migrations, not direct dashboard table edits.

Initial migration groups:

1. `core_identity_wallet`
   - users, profiles, devices, wallets, wallet_transactions, payment_orders, payment_events, system_flags.

2. `guruji_consultations`
   - guruji_profiles/listings, skills, categories, availability, documents, consultations, consultation_events, waitlists, intake_forms.

3. `astrology_cache`
   - horoscope signs, cached astrology, kundali profiles, kundali calculations, kundali pricing.

4. `catalog_content`
   - banners, blogs, pages, help/support, marketplace products/categories, pujas, courses.

5. `ai_rag`
   - AI providers, AI models, tools, tool runs, knowledge sources, chunks, answer cache, Guruji memories.

6. `admin_audit`
   - admin users/roles/permissions, audit logs, commission configs, payout workflows.

## Data Migration Strategy

Do not blindly import all 154 MySQL tables into public Postgres as-is.

Use a three-layer migration:

1. Archive layer
   - Keep raw legacy dumps and optional `legacy_*` staging tables for validation.

2. Canonical app layer
   - New normalized tables used by NestJS/Supabase.

3. Transform scripts
   - Map legacy IDs to UUIDs.
   - Normalize booleans, statuses, timestamps, and money values.
   - Preserve legacy IDs in `legacy_id` columns for traceability.

Critical migrations first:

- users/profiles/devices
- wallets/payment/transaction ledgers
- astrologers/guruji listings
- chat/call request history
- system flags
- recharge amounts
- skills/categories/languages
- astrology cache and Kundali basics

## Architecture Target

- NestJS: main API, business logic, payment webhooks, Socket.io gateway, scheduled workers.
- Supabase Postgres: durable relational data, auth metadata, storage metadata.
- Supabase Auth: phone OTP and session validation.
- Supabase Storage or Cloudflare R2: profile images, documents, stories, recordings.
- Redis: presence, waitlists, short-lived queues, story expirations.
- Cloudflare CDN: public cacheable endpoints like horoscope, Panchang, product catalog.
- Qdrant or pgvector: scripture/vector search.
- Next.js: recommended for admin/web portal if we rebuild Laravel web/admin screens.
- Flutter: customer app and Guruji app consuming the NestJS `/api/v1` API.

## Immediate Next Steps

1. Create Supabase project.
2. Add `.env` with Supabase/Postgres values.
3. Create `supabase/` folder and migration files in this repo.
4. Expand Prisma schema from the legacy-derived domain map.
5. Generate and apply migrations to Supabase test project.
6. Write smoke tests for:
   - public horoscope/Panchang
   - lazy auth/user creation
   - wallet quote and webhook credit
   - Guruji listing read
   - chat/call request preflight
7. Update Flutter-facing API contract docs.

## GitHub and Supabase

Connect GitHub after `supabase/migrations` exists and has been tested.

Recommended workflow:

- Use migration files as source of truth.
- Commit migrations to GitHub.
- Enable Supabase GitHub integration after the first clean migration set.
- Use preview branches for PR testing.
- Only enable production auto-deploy after migrations are stable.

Do not make direct schema edits in Supabase dashboard once migrations are active, except temporary experiments that are pulled back into migrations immediately.

