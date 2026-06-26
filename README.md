# Finance Tracker

> A professional personal finance tracking app built with **Flutter & Supabase**.

Take full control of your money. Finance Tracker lets you set monthly budgets per category, log expenses and income, monitor savings goals, track recurring bills, and view your financial health score — all in a clean, modern interface with full dark/light mode support.

**Live App:** [finance-traking-app.netlify.app](https://finance-traking-app.netlify.app)
| Unfortunately, netlify credits got over. So latest and after changes deployed in github.io.pages| 

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=flat&logo=supabase&logoColor=white)
![Netlify](https://img.shields.io/badge/Netlify-00C7B7?style=flat&logo=netlify&logoColor=white)

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

**Hosting**
- [Netlify](https://netlify.com) — Static web deployment

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

### Build for Web

```bash
flutter build web --release --no-tree-shake-icons
```

---

## License

MIT © [Perinba Athiban](https://github.com/PerinbaBuilds)
