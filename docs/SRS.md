# Software Requirements Specification
## Finance Tracker — Personal Budget Management App
**Version:** 1.0  
**Date:** June 2026  
**Author:** Athiban S (PerinbaBuilds)

---

## 1. Introduction

### 1.1 Purpose
This document defines the functional and non-functional requirements for the Finance Tracker web application — a personal finance management tool that allows users to track income, expenses, savings goals, and monthly budgets.

### 1.2 Scope
Finance Tracker is a Flutter web application backed by Supabase. It is deployed on GitHub Pages and targets individual users who want a minimalist, theme-adaptive personal finance dashboard.

### 1.3 Definitions
| Term | Meaning |
|------|---------|
| Budget Lock | Budgets cannot be edited after day 7 of each month |
| Budget Category | A named spending bucket with an allocated monthly amount |
| Month Snapshot | An archived record of a prior month's budget vs actual spend |
| PKCE | Proof Key for Code Exchange — Supabase's secure auth flow for web |

---

## 2. Overall Description

### 2.1 Product Perspective
A single-page web app (Flutter compiled to JS/HTML). Auth via Supabase (email/password). All user data is stored in a Supabase PostgreSQL database, scoped per authenticated user.

### 2.2 User Classes
- **Primary user:** Individual managing personal finances

### 2.3 Operating Environment
- Modern web browsers (Chrome, Firefox, Safari, Edge)
- Hosted on GitHub Pages (`perinbabuilds.github.io/Finance-App/`)
- Supabase project for auth + database

### 2.4 Constraints
- Flutter web only (no mobile builds)
- Single-user per account (no multi-user sharing)
- No offline support

---

## 3. Functional Requirements

### 3.1 Authentication
| ID | Requirement |
|----|-------------|
| FR-A1 | Users can register with email and password |
| FR-A2 | Users can sign in with email and password |
| FR-A3 | Users can request a password reset email |
| FR-A4 | Password reset link redirects to app's SetNewPassword screen via PKCE `?type=recovery` param |
| FR-A5 | After password update, user is signed out and redirected to Login |
| FR-A6 | Authenticated session persists across page reloads |
| FR-A7 | App shows a loading splash during session restoration (max 5s timeout) |

### 3.2 Budget Management
| ID | Requirement |
|----|-------------|
| FR-B1 | User can set a total monthly budget amount |
| FR-B2 | User can create budget categories with name, icon, color, and amount |
| FR-B3 | User can edit or delete budget categories |
| FR-B4 | Budget editing (add/edit/delete categories and total) is locked after day 7 of each month |
| FR-B5 | Locked state shows an orange lock banner and disables all edit controls |
| FR-B6 | Spending progress per category is shown as a bar with % used |
| FR-B7 | Over-budget categories are highlighted in red |

### 3.3 Transactions
| ID | Requirement |
|----|-------------|
| FR-T1 | User can add an expense transaction linked to a budget category |
| FR-T2 | User can view all transactions with date, category, and amount |
| FR-T3 | User can delete a transaction (swipe-to-dismiss) |
| FR-T4 | Transactions feed into the category's `actualAmount` in real-time |

### 3.4 Income
| ID | Requirement |
|----|-------------|
| FR-I1 | User can add income entries with source name, amount, and date |
| FR-I2 | User can delete income entries |
| FR-I3 | Total income is displayed with animated count-up |

### 3.5 Savings Goals
| ID | Requirement |
|----|-------------|
| FR-G1 | User can create savings goals with target amount and deadline |
| FR-G2 | User can record contributions toward a goal |
| FR-G3 | Progress is shown as percentage and estimated completion date |

### 3.6 Insights
| ID | Requirement |
|----|-------------|
| FR-IN1 | Dashboard shows a donut chart of spending by category |
| FR-IN2 | Insights screen shows a spending breakdown donut with tap-to-focus |
| FR-IN3 | Monthly history is charted as a bar graph |
| FR-IN4 | A financial health score is computed from budget adherence and savings rate |

### 3.7 Appearance
| ID | Requirement |
|----|-------------|
| FR-UI1 | App supports light and dark themes switchable from profile settings |
| FR-UI2 | Theme preference is persisted in Supabase `user_settings.is_dark_mode` |
| FR-UI3 | All AppBars use a dark gradient in dark mode and system default in light mode |
| FR-UI4 | Income and profile headers use bright green gradient in light mode |

---

## 4. Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR-1 | App must load initial data within 3s on a standard broadband connection |
| NFR-2 | Auth token must be refreshed silently; users must not be unexpectedly signed out |
| NFR-3 | Password reset redirect URL must be in Supabase's allowed-redirect list |
| NFR-4 | All user data is isolated by `user_id` (Supabase Row Level Security) |
| NFR-5 | App must remain functional after service worker cache updates (requires hard refresh or incognito for version changes) |

---

## 5. External Interface Requirements

### 5.1 Supabase Tables
| Table | Purpose |
|-------|---------|
| `user_settings` | Dark mode flag, currency preference |
| `budget_categories` | Category definitions per user |
| `transactions` | Expense records |
| `incomes` | Income records |
| `savings_goals` | Goal definitions and contributions |
| `recurring_expenses` | Monthly recurring costs |
| `month_snapshots` | End-of-month archive records |

---

## 6. Appendix

### 6.1 Budget Lock Logic
```
isBudgetLocked = DateTime.now().day > 7
```
Days 1–7: open. Days 8–end of month: locked. Resets on the 1st of each month.

### 6.2 Password Reset Flow
1. User clicks "Forgot Password" → `AuthService.resetPassword(email)` called
2. Supabase sends email with link: `https://perinbabuilds.github.io/Finance-App/?type=recovery&code=xxx`
3. App detects `Uri.base.queryParameters['type'] == 'recovery'` before Supabase initializes
4. `_AuthGate` shows `ResetPasswordScreen` immediately
5. User sets new password → `signOut()` fired → `_AuthGate` transitions to `LoginScreen`
