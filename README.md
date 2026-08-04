# Coinsight&nbsp;&nbsp;[![CI](https://img.shields.io/github/actions/workflow/status/PerinbaBuilds/Coinsight/deploy.yml?branch=main&logo=githubactions&logoColor=white&label=CI&labelColor=0D1117)](https://github.com/PerinbaBuilds/Coinsight/actions/workflows/deploy.yml)

A personal finance tracker that turns your budgets, spending, and goals into a live financial-health picture — and an in-app advisor that answers real money decisions from *your* numbers, not generic tips.

**Live app:** https://perinbabuilds.github.io/Coinsight/

[![Flutter](https://img.shields.io/badge/Flutter-0D1117?style=for-the-badge&logo=flutter&logoColor=54C5F8)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0D1117?style=for-the-badge&logo=dart&logoColor=0175C2)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-0D1117?style=for-the-badge&logo=supabase&logoColor=3FCF8E)](https://supabase.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-0D1117?style=for-the-badge&logo=postgresql&logoColor=4169E1)](https://www.postgresql.org)
[![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-0D1117?style=for-the-badge&logo=githubactions&logoColor=2088FF)](https://github.com/features/actions)
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-0D1117?style=for-the-badge&logo=github&logoColor=FFFFFF)](https://pages.github.com)

## Why this exists

Most budgeting apps stop at "here's what you spent." I wanted one that could actually answer *"can I afford this right now?"* using my own budgets, income, and goals — and I was curious whether an LLM could give grounded, numbers-first advice instead of hand-wavy tips. Coinsight is the result: a clean tracker with an advisor that reasons over a live snapshot of your finances.

## Features

- Set monthly budgets per category and watch actual-vs-planned spending in real time
- Log expenses and income, with per-category breakdowns and net-savings tracking
- Create savings goals and track progress toward them
- Automatic monthly snapshots with carry-forward balances and a history view
- A financial-health score plus spending forecasts and smart alerts
- An AI advisor that answers purchase / loan / investment questions from your real data and renders a GO / WAIT / NOT ADVISED impact report
- Multi-currency with live FX conversion, and full dark / light mode

## Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Frontend | Flutter (Dart) | One codebase for web + mobile that compiles to a static bundle — free to host on GitHub Pages |
| State | Provider | Light enough for this app; no need for a heavier state solution |
| Charts | fl_chart | Donut + bar charts for budgets, insights, and the advisor's projection |
| Backend | Supabase (Postgres + Auth) | Managed Postgres and auth with Row Level Security — per-user isolation with no server to run |
| AI proxy | Supabase Edge Function | Keeps the LLM API key server-side so it never ships in the client bundle |
| LLM | Groq — Llama 3.3 70B | Free tier and fast inference for the advisor |
| Hosting / CI | GitHub Pages via GitHub Actions | Free static hosting; every push to `main` rebuilds and deploys automatically |
| FX rates | Frankfurter API | Free, no API key, CORS-friendly; static fallback rates keep conversion working offline |

## Architecture

> Full detail — data model, runtime flows, and design tradeoffs — in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

```
Flutter web/mobile client
  ├── Provider (AuthService · FinanceService · AdvisorService)
  │
  ├──────────────► Supabase Auth          (email/password, PKCE reset)
  ├──────────────► Supabase Postgres      (per-user rows, Row Level Security)
  │
  └── Advisor ───► Supabase Edge Function ───► Groq API (Llama 3.3 70B)
                   (financial-advisor)         key stays server-side
```

- **FinanceService** — single source of truth for budgets, transactions, income, goals, history; also owns currency + FX conversion.
- **AdvisorService** — builds a financial snapshot, calls the edge function, and parses replies into prose + an impact report.
- **financial-advisor (Edge Function)** — verifies the caller's JWT, then proxies to Groq so the model key is never in the client.

**One interesting decision:** all amounts are stored in a single base currency (USD) and converted only at the display/input boundary. That keeps every stored row currency-agnostic and the math simple — the tradeoff is that switching currency re-scales historical values by today's FX rate rather than the rate at the time each entry was made.

## Getting Started

Should take under 5 minutes.

```bash
git clone https://github.com/PerinbaBuilds/Coinsight.git
cd Coinsight
cp .env.example .env          # fill in your Supabase URL + anon (public) key
flutter pub get
flutter run -d chrome --dart-define-from-file=.env
```

If you skip the `.env` step, the app falls back to the project's public demo backend so it still runs. `.env` values are read via `--dart-define`, so they never get bundled as an asset.

**Requirements:** Flutter 3.6+ (Dart 3.6+), Chrome (for web), and a free [Supabase](https://supabase.com) project.

### Optional: enable the AI Advisor

The advisor runs through a Supabase Edge Function so the model key stays off the client:

1. Get a free key at [console.groq.com/keys](https://console.groq.com/keys) (no card needed).
2. Supabase Dashboard → **Edge Functions** → deploy a function named `financial-advisor` using [`supabase/functions/financial-advisor/index.ts`](supabase/functions/financial-advisor/index.ts).
3. **Edge Functions → Secrets** → add `GROQ_API_KEY`.

### Build for web

```bash
flutter build web --release --no-tree-shake-icons \
  --base-href="/Coinsight/" --dart-define-from-file=.env
```

Pushing to `main` builds and deploys this automatically via GitHub Actions — see [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml).

### Run with Docker

No local Flutter toolchain needed — the multi-stage [`Dockerfile`](Dockerfile) builds the web bundle and serves it with nginx:

```bash
docker build -t coinsight .
docker run --rm -p 8080:80 coinsight
# open http://localhost:8080
```

To point the container at your own Supabase project, pass build args (falls back to the public demo backend if omitted):

```bash
docker build -t coinsight \
  --build-arg SUPABASE_URL=https://your-project.supabase.co \
  --build-arg SUPABASE_ANON_KEY=your-anon-public-key .
```

## Usage

Once signed in, set a total monthly budget and a few categories, then log expenses against them. To ask the advisor a real decision:

```text
"Can I buy a ₹90,000 laptop this month, or should I wait?"
```

It pulls your live budgets, income, goals, and buffer, asks for any missing detail (price, rate, tenure), and returns a GO / WAIT / NOT ADVISED card with a before → after projection.

## Known Limitations / What I'd Do Differently

- **Currency is display-time, not per-entry.** Amounts are stored in USD and converted for display, so switching currency re-scales *historical* values by today's FX rate rather than the rate when they were recorded.
- **Budget editing locks after the 7th** by design (to discourage mid-month goalpost-moving). It's opinionated and not yet configurable.
- **No automated test coverage** on the newer currency-conversion and advisor code — the older auth/month-snapshot logic has unit + widget tests, but these paths don't yet.
- **The anon key ships in the client.** That's fine for Supabase (it's public and RLS-protected), but a stricter design would route all reads/writes through edge functions.
- **FX rates are best-effort.** A free live feed with static fallbacks — good enough for display, not for precise historical accounting.

## License

MIT © [Perinba Athiban](https://github.com/PerinbaBuilds) — see [LICENSE](LICENSE).
