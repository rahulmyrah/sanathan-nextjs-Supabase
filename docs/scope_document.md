# Sanathan Rebuild - Core Scope & Technical Specification Document

This document serves as the master scope and technical context blueprint for the **Sanathan Spiritual Platform** migration. It provides a dense, granular reference for future Antigravity AI agents, SDK integrations, and engineering teams to understand the functional boundaries, database mappings, and external integrations of this clean migration.

---

## 1. Executive Platform Scope

Sanathan is a global spiritual guidance platform serving millions of active users who interact via daily horoscope readings, regional Panchang tracking, verified e-learning courses, a spiritual marketplace (Sevas & Pujas), and real-time consultation chats/calls with astrology experts (Gurujis).

### Legacy System Legacy
The original application was built as a single monolithic PHP Laravel application utilizing a MySQL database (`astronew_dump.sql` containing over 100 tables) and serving mobile clients synchronously. Our migration replaces the Laravel backend with a high-performance NestJS API and transitions the MySQL database into a Supabase PostgreSQL instance, leveraging Redis waitlists and Qdrant semantic vectors.

---

## 2. Granular Database Translation Scope

The core Postgres schema inside Supabase maps all legacy tables into high-scale relational models managed through Prisma:

```
                  ┌──────────────────────────────────────────────┐
                  │              User (Lazy Auth)                │
                  │   UUID, phone, isAnonymous, role, status     │
                  └──────────────┬───────────────────────────────┘
                                 │ 1:1
                                 ▼
                  ┌──────────────────────────────────────────────┐
                  │             Profile & Kundali                │
                  │  monthlyQuota, DOB, timezone, lat/lon bounds │
                  └──────────────┬───────────────────────────────┘
                                 │ 1:1
                                 ▼
                  ┌──────────────────────────────────────────────┐
                  │              Financial Wallet                │
                  │     balance, currency, USD-to-INR factors    │
                  └──────────────┬───────────────────────────────┘
                                 │ 1:M
                                 ▼
                  ┌──────────────────────────────────────────────┐
                  │             Ledger Transactions              │
                  │   amount, type, status, referenceId logs     │
                  └──────────────────────────────────────────────┘
```

### Module 1: Customer Accounts & Lazy Authentication
* **Legacy Tables:** `users`, `defaultprofile`, `user_device_details`, `marital_statuses`.
* **NestJS/Supabase Rebuild:** Standard guest browsing operates anonymously. The Flutter customer app communicates with Cloudflare edge caching nodes without transmitting authorization headers. The Supabase Phone OTP auth flow is triggered lazily ONLY when:
  * Connecting to an active consultation queue.
  * Executing a financial deposit or recharge.
  * Purchasing a spiritual course or marketplace Seva.

### Module 2: Astrologer Directory (Guruji Registry)
* **Legacy Tables:** `astrologers`, `astrologer_expertises`, `astrologer_categories`, `astrologer_documents`, `astrologer_availabilities`, `skills`, `highest_qualifications`.
* **NestJS/Supabase Rebuild:** Guruji profiles are registered under a unified `GurujiListing` table.
  * **Availability Calendars:** Hourly availability ranges are mapped in `astrologer_availabilities`.
  * **Expertise Tags:** Categories (Vedic, Tarot, Vastu) are stored as array parameters in Postgres.
  * **Stories Hub:** WhatsApp/Instagram style stories (legacy table `astrologer_stories`) expire automatically after 24 hours using Redis TTL key listeners.

### Module 3: Consultations waiting room (Real-time Waitlists)
* **Legacy Tables:** `chatrequest`, `callrequest`, `astrologer_wait_lists`, `waitlist`.
* **NestJS/Supabase Rebuild:**
  * **Queue Mechanics:** Waiting rooms are managed in-memory using **Redis sorted sets (ZSET)**. Users are indexed based on their join timestamp, preventing concurrency database conflicts during high-traffic surges.
  * **Peer-to-Peer Data Transfer:** To optimize API calculation costs, when a consultation begins, the Customer app fetches its locally stored birth Kundali JSON from their local **Isar DB** and pushes it over Socket.io directly to the Guruji app interface. The NestJS WebSocket gateway relays the payload instantly without storing it in high-cost database tables.

### Module 4: Wallet & Payout Ledgers
* **Legacy Tables:** `user_wallets`, `wallettransaction`, `withdrawrequest`, `withdraws`, `admin_get_commissions`, `commissions`.
* **NestJS/Supabase Rebuild:**
  * **Double-Entry Ledger:** Wallet balances are strictly updated inside database transactions, demanding matching `Transaction` records (credits/debits) with unique payment provider reference IDs.
  * **Commissions splits:** Astrologer payouts and withdrawals deduct a dynamic **30% platform commission** (managed in the Admin settings flags) on all voice/chat consultations.
  * **USD-to-INR Conversion:** Standard conversion factor (default: `80` in settings) applies automatically to international payments.

---

## 3. External Integration Scope

Our V1 NestJS gateway coordinates several critical integrations:

### 1. Paid Vedicastro API Integration
* **Shared Daily Horoscope & Panchang:** Fetched once at Midnight IST per zodiac sign and metro region (Delhi, Mumbai, Bengaluru), cached globally on Cloudflare edge nodes for 24h. Served free to guests.
* **User-Specific Calculations:** Personal Kundali and Matchmaking requests require unique inputs and cannot be cached. Gateway verifies user quotas (2 free monthly updates). Overages require ₹49 wallet balance debit before calling the paid Vedicastro API.

### 2. Voice & Video signaling (Agora + Zego)
* Mobile applications include support for both Agora RTC and Zego UIKit pre-built calling engines.
* The NestJS consultation controller reads standard `AgoraAppId` and `AgoraAppCertificate` system flags to generate secure, dynamic WebRTC signaling tokens whenever a consultation voice/video request is accepted by a Guruji.

### 3. Asynchronous FCM Notifications
* To prevent Laravel's synchronous push notification latency (using OneSignal or Firebase FCM), NestJS schedules pushes in a background worker queue, offloading push execution entirely from the client HTTP request threads.

### 4. Scripture vector search RAG (Qdrant + LLM)
* Verified spiritual scriptures, pooja procedures, and slokas are converted to dense embeddings and indexed in **Qdrant** or **Pinecone**.
* Astrologers and customer AI chat widgets query the database semantically.
* **Semantic matching:** Cosine similarity scores above `0.78` pull the verified text as direct grounded context, prompting the fallback LLM (Google Gemini) to format the response with citations. Match scores below `0.78` trigger standard LLM fallback with spiritual safety disclaimers.

---

## 4. Administrative Scope & Dashboards

The backend admin portal exposes highly secure REST endpoints for 67+ administrative settings:

1. **astrologers verification panel:** Review uploaded documents, edit pricing, and toggle online activation flags.
2. **Payout & Withdraw board:** Process Guruji withdrawal requests and audit commission ledger splits.
3. **Dynamic Configuration Manager:** Global screens to update GST rates, payment gateway credentials, and USD conversion variables.
4. **AI Form and Prompt Builder:** Canvas interface to build dynamic user query forms, map prompt engines, and monitor Gemini/OpenAI token expenditures.

---

## 5. Visual Dashboard Reference

For a live, visual representation of the roadmap, task cards, and milestones, please open:
* [project-board.html](file:///c:/Users/rahul/Desktop/Sanathan%20APP/Sanathan%20Mobile%20App/project-board.html)
* [sanathan-project-board.html](file:///c:/Users/rahul/Desktop/Sanathan%20APP/Sanathan%20Mobile%20App/sanathan-project-board.html)

Future Antigravity agents should inspect this project board's column states to verify task completions before claiming milestone success.
