# Software Design Document
## Finance Tracker — Personal Budget Management App
**Version:** 2.0  
**Date:** July 2026  
**Author:** Athiban S (PerinbaBuilds)

---

## 1. Overview

Finance Tracker is a Flutter web application. The architecture follows the **Provider pattern** for state management, with three core services (`AuthService`, `FinanceService`, `AdvisorService`) exposed via `MultiProvider` at the app root. Navigation is driven entirely by auth state events — no manual `Navigator.push` for auth transitions. As of v2.0 an **AI Financial Advisor** feature adds a chat surface backed by a Supabase Edge Function that proxies to a hosted LLM.

---

## 2. Architecture

```
FinanceTrackerApp (MaterialApp)
└── _AuthGate (StatefulWidget)
    ├── ResetPasswordScreen  ← when _isRecovery = true
    ├── LoginScreen          ← when !isLoggedIn
    └── HomeScreen           ← when isLoggedIn (bottom nav)
        ├── DashboardScreen
        ├── IncomeScreen
        ├── GoalsScreen
        ├── AdvisorScreen     ← AI Financial Advisor (v2.0)
        ├── InsightsScreen
        └── HistoryScreen

Advisor data path:
AdvisorScreen → AdvisorService → Supabase Edge Function
    (financial-advisor) → Groq API (Llama 3.3 70B)
```

### 2.1 State Management
| Provider | Responsibility |
|----------|---------------|
| `AuthService` | Wraps Supabase auth. Exposes `isLoggedIn`, `currentUser`, `signIn`, `signOut`, `resetPassword`, `updateProfile`. Calls `notifyListeners()` on every auth state change. |
| `FinanceService` | All finance data. Loads from Supabase on sign-in. Exposes categories, transactions, income, goals, recurring, month history. Also holds `isDarkMode`, `currency`, `isBudgetLocked`. |
| `AdvisorService` | Advisor chat state. Builds the financial snapshot, calls the `financial-advisor` Edge Function, parses replies into prose + Impact Report, and persists active/archived conversations per user in local storage. Exposes `messages`, `history`, `isThinking`, `send()`, `startNewChat()`, `resumeChat()`, `deleteChat()`. |

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
│   ├── finance_service.dart   # All finance CRUD + computed getters
│   └── advisor_service.dart   # AI advisor chat, snapshot, history (v2.0)
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
│   ├── advisor_screen.dart    # AI advisor chat + Impact Report UI (v2.0)
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

supabase/
└── functions/
    └── financial-advisor/
        └── index.ts               # Edge Function: JWT check + Groq proxy (v2.0)
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

### 4.6 AI Advisor — Server-Side Key via Edge Function
The site is a static Flutter web bundle on GitHub Pages, so it has no server to safely hold an LLM API key. The advisor therefore calls a Supabase **Edge Function** (`financial-advisor`) instead of the LLM directly:
- The function reads `GROQ_API_KEY` from a Supabase secret — the key never enters the client bundle.
- It verifies the caller's Supabase JWT (`auth.getUser()`) and returns `401` for anonymous requests, so tokens are only spent for signed-in users.
- It injects the system prompt and the user's financial snapshot, calls the Groq API (Llama 3.3 70B), and returns only the model's text.
- The conversation is trimmed to the last ~20 messages server-side to stay within free-tier token limits.

### 4.7 AI Advisor — Grounding Snapshot
`AdvisorService._buildSnapshot()` converts the already-loaded `FinanceService` state into a compact JSON object (budgets, category spend, income, goals, active recurring bills, recent month history, a projected month-spend estimate, an emergency-buffer-in-months estimate, and the health score). This is sent as a second system message so the model reasons over the user's real numbers rather than generic assumptions. The health-score formula is defined once in `AdvisorService.computeHealthScore()` and reused by `InsightsScreen`, so the advisor and the Insights tab never disagree.

### 4.8 AI Advisor — Impact Report Parsing
For a final recommendation the model appends a machine-readable block wrapped in `<impact>…</impact>` containing strict JSON (verdict, one-time/monthly cost, current vs projected snapshot, a 6-point savings timeline, and suggestions). `AdvisorService` strips this block from the prose, parses it into an `ImpactReport`, and `AdvisorScreen` renders it as a verdict card with a comparison table and an `fl_chart` line chart. Parsing is defensive: malformed JSON simply yields no card and the prose is still shown.

### 4.9 AI Advisor — Conversation Persistence & History
Conversations are stored in local storage (`shared_preferences`) under per-user keys (`advisor_history_<uid>` for the active chat, `advisor_archive_<uid>` for archived ones), so history survives reloads and never crosses accounts. "New chat" archives the current conversation; the history sheet lists archived chats by date; opening one shows it read-only with a "Continue with today's finances" action that reactivates it (any new question then rebuilds the snapshot from current data). The archive is capped at 30 conversations to keep storage small.

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

### 5.1 Edge Function (v2.0)
```
supabase/functions/financial-advisor/index.ts
  - Runtime: Deno (Supabase Edge Functions)
  - Secret:  GROQ_API_KEY (server-side only)
  - Auth:    verifies caller JWT via supabase.auth.getUser(); 401 if absent
  - Calls:   Groq API — model "llama-3.3-70b-versatile"
  - Body in: { messages: [...], snapshot: {...} }
  - Body out:{ content: "<model reply>" }  (or { error, detail } on failure)
```

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

### 6.3 Advisor Edge Function Setup (v2.0)
1. Create a free API key at `console.groq.com/keys`.
2. Deploy `supabase/functions/financial-advisor/index.ts` as an Edge Function named `financial-advisor`.
3. Add the secret `GROQ_API_KEY` under **Edge Functions → Secrets**.

Without the secret the advisor returns a friendly "backend not configured" message; the rest of the app is unaffected.
