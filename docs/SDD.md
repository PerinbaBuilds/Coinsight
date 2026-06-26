# Software Design Document
## Finance Tracker — Personal Budget Management App
**Version:** 1.0  
**Date:** June 2026  
**Author:** Athiban S (PerinbaBuilds)

---

## 1. Overview

Finance Tracker is a Flutter web application. The architecture follows the **Provider pattern** for state management, with two core services (`AuthService`, `FinanceService`) exposed via `MultiProvider` at the app root. Navigation is driven entirely by auth state events — no manual `Navigator.push` for auth transitions.

---

## 2. Architecture

```
FinanceTrackerApp (MaterialApp)
└── _AuthGate (StatefulWidget)
    ├── ResetPasswordScreen  ← when _isRecovery = true
    ├── LoginScreen          ← when !isLoggedIn
    └── HomeScreen           ← when isLoggedIn (bottom nav)
        ├── DashboardScreen
        ├── TransactionsScreen
        ├── InsightsScreen
        └── ProfileScreen
```

### 2.1 State Management
| Provider | Responsibility |
|----------|---------------|
| `AuthService` | Wraps Supabase auth. Exposes `isLoggedIn`, `currentUser`, `signIn`, `signOut`, `resetPassword`, `updateProfile`. Calls `notifyListeners()` on every auth state change. |
| `FinanceService` | All finance data. Loads from Supabase on sign-in. Exposes categories, transactions, income, goals, recurring, month history. Also holds `isDarkMode`, `currency`, `isBudgetLocked`. |

### 2.2 Auth Gate State Machine
`_AuthGateState` manages two boolean flags:
- `_initialized` — false during session restoration splash
- `_isRecovery` — true when the current URL contains `?type=recovery`

Transitions are driven by `_authSub` (always created, even in recovery mode):

| Event | Action |
|-------|--------|
| `passwordRecovery` | `_isRecovery = true`, `_initialized = true` |
| `signedOut` | `_isRecovery = false` |
| `signedIn` / `tokenRefreshed` | `loadData()` if not recovery |

> **Critical design note:** `_authSub` must be created BEFORE the early-return in the recovery path. If it is created after, the `signedOut` event (fired by `signOut()` in `ResetPasswordScreen`) is never received and `_isRecovery` is never reset — the user is permanently stuck on `ResetPasswordScreen`.

---

## 3. Directory Structure

```
lib/
├── main.dart                  # App entry, _AuthGate
├── config/
│   └── supabase_config.dart   # URL + anon key constants
├── models/
│   ├── category.dart          # BudgetCategory (mutable name/amount/icon/color)
│   ├── transaction.dart
│   ├── income.dart
│   ├── savings_goal.dart
│   ├── recurring_expense.dart
│   └── month_snapshot.dart
├── services/
│   ├── auth_service.dart      # Supabase auth wrapper
│   └── finance_service.dart   # All finance CRUD + computed getters
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   └── reset_password_screen.dart
│   ├── home_screen.dart       # Bottom nav shell
│   ├── dashboard_screen.dart
│   ├── income_screen.dart
│   ├── manage_budgets_screen.dart
│   ├── goals_screen.dart
│   ├── transactions_screen.dart
│   ├── insights_screen.dart
│   ├── history_screen.dart
│   └── profile_screen.dart
├── widgets/
│   ├── budget_category_card.dart  # Per-category spend card with lock
│   ├── budget_chart.dart          # Donut chart (dashboard)
│   └── add_expense_screen.dart
└── theme/
    └── app_theme.dart             # Light/dark ThemeData, color constants
```

---

## 4. Key Design Decisions

### 4.1 No Manual Navigation for Auth Transitions
`LoginScreen`, `ResetPasswordScreen`, and `HomeScreen` are swapped as children of `_AuthGate` by changing state variables (`_isRecovery`, `_initialized`), not via `Navigator.push/pushAndRemoveUntil`. 

This avoids a critical failure mode: if `pushAndRemoveUntil(LoginScreen)` is called from `ResetPasswordScreen`, `_AuthGate` is removed from the widget tree. Subsequent successful login fires `signedIn` but `_AuthGate` is gone — the app never navigates to `HomeScreen`.

### 4.2 Data Loading Location
`FinanceService.loadData()` is called in exactly two places:
1. `_AuthGate._authSub` on `signedIn` event — covers login and session restore on cold start
2. `_AuthGate._init()` after session restore — covers the case where the user was already signed in when the app launched

It is deliberately NOT called in `LoginScreen._signIn()` because `LoginScreen` is destroyed by `_AuthGate` rebuilding before `await loadData()` would return, causing `mounted = false` and the call to silently do nothing.

### 4.3 Password Reset PKCE Flow
Supabase's PKCE flow sends a `?code=xxx` query param (not the legacy `#type=recovery` fragment). The app embeds `?type=recovery` in the `redirectTo` URL so it can detect the recovery intent before Supabase exchanges the code:

```dart
redirectTo = '${base}?type=recovery';
// Supabase appends: &code=xxx
// Final URL: https://perinbabuilds.github.io/Finance-App/?type=recovery&code=xxx
```

Detection happens before `Supabase.initialize()` so the PKCE exchange (which fires `passwordRecovery`) does not race with the UI showing the wrong screen.

### 4.4 Budget Lock
```dart
bool get isBudgetLocked => DateTime.now().day > 7;
```
Days 1–7 are open. Day 8 onwards the lock applies. This is enforced in three places:
- `budget_category_card.dart` — blocks recording new spend against a category
- `manage_budgets_screen.dart` — hides add button/FAB, replaces edit/delete with lock icon, shows orange banner
- `dashboard_screen.dart` — shows locked state in the budget card

### 4.5 Theme Adaptation Pattern
All screens check `Theme.of(context).brightness == Brightness.dark` for conditional styling. The two main patterns:

**AppBar gradient (dark mode only):**
```dart
flexibleSpace: Theme.of(context).brightness == Brightness.dark
    ? Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient))
    : null,
```

**Hero card gradient (income, profile, drawer):**
```dart
colors: isDark
    ? const [AppTheme.navyDark, AppTheme.navy, AppTheme.navyLight]
    : const [Color(0xFF22C55E), Color(0xFF4ADE80), Color(0xFF86EFAC)],
```

---

## 5. Supabase Schema (key tables)

```sql
-- user_settings
id            uuid references auth.users primary key
is_dark_mode  boolean default false
currency      text default 'USD'

-- budget_categories
id            text primary key
user_id       uuid references auth.users
name          text
budget_amount numeric
actual_amount numeric
icon_code     int         -- IconData.codePoint
color_value   int         -- Color.value
created_at    timestamptz

-- transactions
id            text primary key
user_id       uuid references auth.users
category_id   text references budget_categories
amount        numeric
description   text
date          date

-- incomes
id            text primary key
user_id       uuid references auth.users
source        text
amount        numeric
date          date
```

Row Level Security (RLS) is enabled on all tables — all queries are automatically scoped to `auth.uid()`.

---

## 6. Deployment

| Target | Command | Output | URL |
|--------|---------|--------|-----|
| GitHub Pages | `flutter build web --base-href="/Finance-App/" --release --no-tree-shake-icons` then copy `build/web/*` to `docs/` | `docs/` folder | `perinbabuilds.github.io/Finance-App/` |
| Netlify (paused) | `flutter build web --base-href="/" --release --no-tree-shake-icons` | `build/web/` | — (credits exhausted) |

### 6.1 Service Worker Caveat
Flutter web registers a service worker that aggressively caches `main.dart.js`. After deploying a new build, users must hard refresh (`Ctrl+Shift+R`) or open in Incognito to get the updated version.

### 6.2 Required Supabase Config
Go to **Authentication → URL Configuration → Redirect URLs** and add:
```
https://perinbabuilds.github.io/Finance-App/**
```
Without this, password reset emails will use a disallowed redirect and the reset flow will fail.
