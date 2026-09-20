# 🪙 FINORYX — AI Personal Finance Operating System

Finoryx is a next-generation personal finance operating system engineered with a high-fidelity **Flutter** mobile experience, an enterprise **NestJS** backend engine, **Supabase PostgreSQL** data persistence with multi-tenant row-level security (RLS), and a **grounded AI Financial Copilot** powered by Google Gemini.

---

## 🌟 Key Architecture & Capabilities

- 🔐 **Zero-Knowledge Multi-Tenant Auth**: Biometric locking, secure hardware token vault, and Supabase JWT auth.
- 💳 **Accounts & Double-Entry Ledger**: Real-time asset & liability balancing, multi-currency support, and net worth tracking.
- 🏷️ **Smart Categorization & Taxonomies**: Multi-tier income and expense hierarchies with customized icons and color palettes.
- ⚡ **Transactions & Atomic Balance Transfers**: Double-entry journal records with auto-calculated transfer fees and source/destination balancing.
- 📊 **Category Budgets & Burn Rate Velocity Engine**: Predictive month-end spend forecasting with `ON_TRACK`, `WARNING`, and `EXCEEDED` statuses.
- 🎯 **Savings Goals & Milestone Pacing Engine**: Atomic source-account goal contributions, time-to-goal trajectory estimations, and milestone celebration UI.
- 📈 **Analytics Scorecards & Dynamic Cash Flow**: 6-month historical spending curves, category donut breakdowns, and net cash flow insights.
- 🤖 **Grounded AI Copilot & Natural Language Decision Engine**: Grounded tool calling (`check_affordability`, `get_monthly_burn_rate`, `get_savings_goals_pace`, `get_net_worth`) with structured interactive decision cards.

---

## 🏗️ Repository Monorepo Structure

```
Finoryx/
├── .github/
│   └── workflows/
│       ├── backend-ci-cd.yml         # Automated NestJS test suite & Docker build check
│       └── mobile-release-apk.yml     # Automated Flutter release APK builder & GitHub Release
├── apps/
│   ├── backend/                      # NestJS 10 Enterprise API
│   │   ├── src/
│   │   │   ├── modules/ (auth, accounts, categories, transactions, budgets, goals, analytics, ai)
│   │   │   ├── database/ (supabase client & RLS)
│   │   │   └── app.controller.ts (/health probe)
│   │   ├── test/                     # 13 Test Suites (64 Unit, E2E & Security tests)
│   │   ├── Dockerfile                # Multi-stage production container build
│   │   └── vercel.json               # Serverless cloud deployment config
│   └── mobile/                       # Flutter 3.19+ Mobile Application
│       ├── lib/
│       │   ├── core/ (design tokens, theme, networking, secure storage)
│       │   └── features/ (14 modernized screens across auth, dashboard, accounts, transactions, budgets, goals, analytics, copilot)
│       └── test/                     # Domain formatters & math tests
├── docker-compose.yml                # Local containerized deployment
├── render.yaml                       # Infrastructure-as-Code for 1-click Render deployment
├── DEPLOYMENT.md                     # Complete cloud deployment & tester sharing guide
└── README.md
```

---

## 🚀 Quick Start (Local Development)

### 1. Backend Setup
```bash
cd apps/backend
npm install
cp .env.example .env     # Fill in your Supabase URL & Keys
npm run start:dev        # API running at http://localhost:3000/api/v1
```

### 2. Run Backend Tests
```bash
cd apps/backend
npm test                 # 13/13 test suites (64/64 tests green)
```

### 3. Mobile Setup
```bash
cd apps/mobile
flutter pub get
flutter run
```

---

## ☁️ Production Deployment

See [**`DEPLOYMENT.md`**](./DEPLOYMENT.md) for full instructions on:
1. Deploying the backend to **Render** (free tier) or **Vercel**.
2. Setting up **Supabase PostgreSQL** database.
3. Automatically generating installable **Android `.apk`** files from GitHub Actions to share with friends.
