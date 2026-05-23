# Sanathan - High-Scale Spiritual Platform Rebuild

This repository houses the high-scale, cost-controlled, and offline-first rebuild of the **Sanathan** spiritual guidance platform. We are migrating from a legacy Laravel (MySQL) framework to a modern **TypeScript (NestJS) + Supabase (PostgreSQL) + Redis + Cloudflare Edge CDN + Qdrant Vector DB** stack.

Our architecture is custom-engineered to handle **1 Million+ Active Users** via aggressive caching, smart P2P signaling, and highly optimized external API consumption gates.

---

## 🚀 Key Architectural Pillars

### 1. Global CDN & Proximity Caching (Under <10ms Responses)
* Decouples static, repetitive astrology calculations (like daily horoscopes and general regional Panchang) from transaction flows.
* A daily cron job pre-calculates and caches datasets at **Midnight India Standard Time (IST)**, serving them from Cloudflare Edge CDN using `Cache-Control: public, s-maxage=86400` headers.
* The Flutter customer application caches pre-fetched payloads locally in **Isar DB / SQLite**, allowing the application to work instantly without active internet connections.

### 2. Vedicastro API Budget Optimization (₹49 Limit Gate)
* Caching daily predictions reduces global paid calculations to **fewer than 1,000 requests per day**.
* For user-specific calculations (Personal Kundalis and Matchmaking reports), the NestJS gateway intercepts calls and enforces a **quota limit of 2 free monthly requests**.
* Calculative requests beyond this limit are blocked, prompting a ₹49 billing check. Upon verification, the NestJS database ledger debits user wallets in a PostgreSQL transaction before calling the paid external API.

### 3. "Lazy Authentication" Model (Auth-on-Demand)
* Customers browse products, horoscopes, articles, and astrologer catalogs anonymously.
* Supabase OTP Phone Auth is lazily triggered **only when committing a wallet recharge, buying a course, or joining a live consultation waitlist**.
* This drops active Supabase Auth MAUs from 1 Million to under 50,000, reducing infrastructure billing drastically.

### 4. Real-time Peer-to-Peer Consultation waitlists (Redis + Socket.io)
* Active waitlist queues and consultation pairing are managed in-memory using **Redis sorted sets**.
* During active chat sessions, the Customer app reads their locally stored Kundali JSON and pushes it over WebSockets directly to the active Guruji's terminal.
* The NestJS WebSocket gateway (Socket.io) forwards the payload instantly without executing persistent database writes, reducing server IOPS and eliminating duplicated paid astronomical computations.

---

## 📁 Repository Layout

```
.
├── docs/
│   └── scope_document.md         # Comprehensive scope file for future Antigravity AI agents
├── Sanathan Flutter User/        # REFERENCE ONLY: Customer Flutter Mobile Application
├── Sanathan Flutter-Guruji/      # REFERENCE ONLY: Astrologer Partner Flutter Mobile Application
├── sanathan-nest-backend/        # Core NestJS Origin API Workspace
│   ├── prisma/
│   │   └── schema.prisma         # Unified Supabase DB PostgreSQL schema
│   ├── src/
│   │   ├── prisma/               # Global Prisma integration lifecycle modules
│   │   └── astrology/            # Caching daily horoscopes, Panchangs & limit control
│   └── package.json
├── project-board.html            # Premium visual Trello project board (sprint tracking dashboard)
├── sanathan-project-board.html   # Synced copy of the Trello visual project board
├── task.md                       # High-scale migration checklist tracking overall milestones
└── README.md                     # Technical roadmap & setup instructions
```

---

## ⚙️ Getting Started (Backend Developer Setup)

### Prerequisites
* **Node.js** (v20+ recommended)
* **NPM** (v10+ recommended)
* **PostgreSQL** or a Supabase Project instance

### Install Dependencies
Navigate to the backend directory and download required npm packages:
```bash
cd sanathan-nest-backend
npm install
```

### Environment Settings
Create a `.env` file in the root of the `sanathan-nest-backend` directory based on the configuration templates defined in the [.env configuration file](file:///c:/Users/rahul/Desktop/Sanathan%20APP/Sanathan%20Mobile%20App/sanathan-nest-backend/.env).

### Compile Database Clients
Prisma 7 uses a global config wrapper (`prisma.config.ts`). Generate the type-safe client:
```bash
npx prisma generate
```

### Start Development Server
Launch the local API server:
```bash
npm run start:dev
```
The NestJS server will start on `http://localhost:3000`. Public endpoints can be explored under:
* `/api/v1/astrology/horoscope?sign=aries&lang=en`
* `/api/v1/astrology/panchang?lat=28.61&lon=77.20`
