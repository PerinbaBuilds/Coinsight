# Finance Tracker

> A professional personal finance tracking app built with **Flutter & Supabase**.

Take full control of your money. Finance Tracker lets you set monthly budgets per category, log expenses and income, monitor savings goals, track recurring bills, and view your financial health score — all in a clean, modern interface with full dark/light mode support.

**Live App:** [perinbabuilds.github.io/Finance-App](https://perinbabuilds.github.io/Finance-App/)

This app was originally hosted on [Netlify](https://finance-traking-app.netlify.app), but the free tier's build credits ran out, so it's now deployed on GitHub Pages instead. The Netlify link above is kept for reference and may no longer reflect the latest build — use the GitHub Pages link for the current version.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=flat&logo=supabase&logoColor=white)](https://supabase.com)
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-222222?style=flat&logo=github&logoColor=white)](https://pages.github.com)

---

## Features

| Feature | Description |
|---|---|
| **Budget Tracking** | Set monthly budgets per category, visualize actual vs planned spending |
| **Expense Management** | Add, view, and delete expenses with category breakdown |
| **Income Tracking** | Log multiple income sources and monitor net savings |
| **Savings Goals** | Create goals with target amounts and track progress |
| **Monthly History** | Snapshots of past months with carry-forward balances |
| **Recurring Expenses** | Track and manage bills that repeat monthly |
| **Financial Insights** | Health score, spending forecast, and smart alerts |
| **AI Financial Advisor** | Chat consultant for purchase, loan, and investment decisions — answers from your real budgets, income, goals and bills, asks follow-up questions (price, rate, tenure), factors in depreciation, and renders a before/after impact report with a projected-savings chart |
| **Dark / Light Mode** | Full theme support across all screens |

---

## Tech Stack

**Frontend**
- [Flutter](https://flutter.dev) (Dart) — Web, Android, iOS
- [fl_chart](https://pub.dev/packages/fl_chart) — Charts & visualizations
- [Provider](https://pub.dev/packages/provider) — State management

**Backend**
- [Supabase](https://supabase.com) — PostgreSQL database + Authentication
- Row Level Security — per-user data isolation
- Supabase Edge Function (`financial-advisor`) — proxies the AI advisor to the [Groq API](https://groq.com) (Llama 3.3 70B) so the API key stays server-side

**Hosting**
- [GitHub Pages](https://pages.github.com) — Static web deployment (built into `docs/` and served from the `main` branch)
- Previously hosted on [Netlify](https://netlify.com) until its free build credits ran out

---

## Getting Started

```bash
git clone https://github.com/PerinbaBuilds/Finance-App.git
cd Finance-App
flutter pub get
flutter run -d chrome
```

### Environment Setup

Create a Supabase project and add your credentials to `lib/config/supabase_config.dart`:

```dart
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseAnonKey = 'YOUR_ANON_KEY';
```

### AI Advisor Setup (one-time)

The advisor runs through a Supabase Edge Function so the model API key is never exposed in the web bundle:

1. Create a free API key at [console.groq.com/keys](https://console.groq.com/keys) (no credit card needed).
2. In the Supabase Dashboard → **Edge Functions** → **Deploy a new function**, name it `financial-advisor` and paste the code from [`supabase/functions/financial-advisor/index.ts`](supabase/functions/financial-advisor/index.ts).
3. In **Edge Functions → Secrets**, add `GROQ_API_KEY` with your key.

### Build for Web

```bash
flutter build web --release --no-tree-shake-icons
```

---

## License

MIT © [Perinba Athiban](https://github.com/PerinbaBuilds)
