# Coinsight

> A professional personal finance tracking app built with **Flutter & Supabase**.

Take full control of your money. Coinsight lets you set monthly budgets per category, log expenses and income, monitor savings goals, track recurring bills, and view your financial health score — all in a clean, modern interface with full dark/light mode support.

**Live App:** [perinbabuilds.github.io/Coinsight](https://perinbabuilds.github.io/Coinsight/)

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

## AI Financial Advisor

An in-app consultant that answers real money decisions — *"Can I buy a MacBook now or after a week?"*, *"Should I take this loan?"*, *"How much can I safely invest this month?"* — grounded entirely in **your own data**, not generic advice.

### What it does

- **Grounded in your finances.** Every reply is based on a live snapshot of your budgets, category spending, income, savings goals, recurring bills, past-month history, emergency-buffer estimate, and financial-health score. It cites the specific numbers that drive its conclusion.
- **Asks before it answers.** If a decision needs details it doesn't have — price, loan amount, interest rate, tenure, expected return, timeline — it asks a short follow-up first instead of guessing.
- **Thinks like an advisor.** It weighs liquidity after the purchase, months of emergency buffer, impact on your goals, upcoming bills, and — for assets — depreciation and opportunity cost. For loans it estimates the monthly payment and flags debt-to-income concerns; for investments it checks your buffer and goal timelines first.
- **Visual impact report.** When it gives a final recommendation, it renders a decision card: a **GO / WAIT / NOT ADVISED** verdict, a **before → after** comparison of net savings, budget used, emergency buffer, and health score, a **6-month projected-savings chart** (with vs. without the decision), and actionable suggestions.

### Chat history

- Conversations are **saved per user** and survive reloads and tab switches.
- Starting a **new chat** archives the current one instead of discarding it.
- A **history** view lists past conversations by date; open any of them read-only, then tap **"Continue with today's finances"** to reopen it as the active chat so new advice uses your current data.

### How it works

The advisor is powered by a **Supabase Edge Function** (`financial-advisor`) that proxies requests to the [Groq API](https://groq.com) (Llama 3.3 70B). The model API key lives only in a Supabase secret and is never shipped in the web bundle, and the function verifies the caller is a signed-in user before spending any tokens. See [AI Advisor Setup](#ai-advisor-setup-one-time) below.

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
git clone https://github.com/PerinbaBuilds/Coinsight.git
cd Coinsight
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
