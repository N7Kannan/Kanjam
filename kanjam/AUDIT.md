# KANJAM APK audit and rebuild notes

## Scope and limits

* The APK is a **release (AOT) build**: the Dart code is compiled into `libapp.so`. Source cannot
  be recovered from it. What can be recovered, and was used here, is the manifest, assets,
  dependency list, class / method / field names and every UI string.
* The old APK was **not executed** (no device or emulator). Findings below are therefore things
  the binary itself shows, not crash reports. Runtime bugs such as a wrong total or a back-button
  glitch cannot be observed from a release build; for those the rebuild is correct by construction
  and covered by unit tests (see "Requirement checklist").
* The Flutter SDK, pub.dev and the Android toolchain were unreachable from the sandbox, so
  `flutter pub get`, `flutter analyze`, `flutter test` and the release APK build **were not run**.

## What the APK contains

`com.kanjam.finance`, v1.0.0 (build 1), minSdk 24, targetSdk 36. Dart packages: `hive`,
`hive_flutter`, `path_provider`, `intl` (plus Flutter itself). Android components: only AndroidX
startup / profile-installer. Declared permission: `INTERNET`. Screens, services and models match
the names in your brief (account / budget / goal / storage / transaction services; account, budget,
goal, transaction, user, notification models).

## Findings (each backed by something in the binary)

| # | Finding | Evidence | Resolution |
| - | --- | --- | --- |
| 1 | Demo data is seeded as if it were the user's data | `seedDemoData`, `has_seeded_demo`, `isDemo`, ids `tx_demo_*`, `usr_demo_1`, `acc_*_1`, `goal_1..3`, `bg_*`, user "Arjun Sharma" | No seeding anywhere. A new user starts empty. |
| 2 | "Reset Demo Data" restores fake values | string "Reset Demo Data" | Replaced by **Erase my data** (clears transactions, budgets, goals, notifications; keeps accounts). |
| 3 | Account connection is simulated | `MockTransactionRepository`, `fetchExternalTransactions`, providers tagged "(AA Mock)", "Transactions Fetched Successfully" | Removed. **Connect Account** now adds a real tracked account (bank / cash / investment) and says plainly that KANJAM does not log in to banks. |
| 4 | Forgot Password shows a success message but cannot send anything | "Recovery link sent to your registered contact."; no mail / network packages | Real local reset: user ID + recovery contact saved at sign-up, then a new password. |
| 5 | App Lock switch with nothing behind it | "Biometric / App Lock"; no `local_auth` | Working PIN App Lock (set, confirm, lock at launch, turn off with PIN, "Forgot PIN" via account password). Biometrics were not added (needs a native plugin; see below). |
| 6 | Push Notifications switch with nothing behind it | "Push Notifications"; no notification plugin, no services / receivers in the manifest | In-app notifications that the (renamed) switch really controls. |
| 7 | Appearance row with only a dark theme | "Dark Theme (Fintech Black & #00E676)" | Dark / Light / System, persisted. Dark remains the default. |
| 8 | No password hashing | no `crypto` package; a literal demo password string (`Password123`) in the seed | Salted, iterated SHA-256 for passwords and PIN. |
| 9 | Unneeded `INTERNET` permission | manifest | The generated host project does not add it; the app makes no network calls. |
| 10 | Both logo files are JPEG data named `.png` | file headers | Converted to real PNG; a cropped icon-only mark added for light backgrounds. |
| 11 | Services notify through storage callbacks (`_onStorageChanged`) rather than a state container | method names | Provider + ChangeNotifier; screens rebuild from one source of truth. |
| 12 | Maps stored in Hive with `fromMap` / `toMap` | no generated adapters | Kept (no build step), but parsing is now tolerant of missing / mistyped fields and corrupt boxes. |

## Requirement checklist

| Area in your brief | How it is handled |
| --- | --- |
| Startup / splash / restart | Hive opened once before `runApp`; retry screen on failure; min 0.9 s splash; session restored; onboarding resumes at the saved step. |
| Login / signup / logout | Validated fields with the original messages; duplicate IDs refused; double-submit guarded; logout clears the session and closes stacked screens. |
| Onboarding | Name, income, cash, bank, investments; every answer saved on Continue; accounts created idempotently at the end. |
| Dashboard | Balance, cash / bank / invested, month income and expense, budgets, goals, recent transactions: all derived. |
| Transactions | Add, edit, delete, details, category, amount, date, notes, account, mode; `0`, negative, non-numeric and oversized amounts rejected; overdraft warned, not blocked. |
| Budgets | Per category or Overall, month-aware, remaining, %, 80 % and exceeded states, one budget per category, alerts once per level per month. |
| Goals | Create, edit, delete, add money, progress, optional target date, completion notice. |
| Reports | Month switcher; KPIs; income vs expense; category donut; weekly trend; empty, single and multi-month data handled. |
| Notifications / profile / settings | Real unread counts, mark read, swipe delete, clear all; edit profile, change password; theme, alerts, App Lock, erase data. |
| Edge cases | Covered by validators, `FinanceCalculator` unit tests, double-tap guards, `PopScope` back handling and `mounted` checks. |
| Build + QA | **Not executed here.** See README for the commands. |

## Assumptions

1. Old Hive data is not imported: its schema cannot be recovered from a release build, and its
   contents were largely demo data. New boxes are `kanjam_v2_*`; old boxes are left untouched.
2. Goal savings are tracked separately; adding money to a goal does not change account balances.
3. Dates cannot be in the future. Home income / expense cards show the current month.
4. Sign-up now asks for a recovery email or phone (needed for the offline password reset).
5. Money is kept as rupees rounded to paise at every aggregation (`round2`).
6. The PIN lock is a convenience lock (4 digits), not strong protection against someone with
   file access to the device.

## Possible follow-ups

* Biometric unlock: add `local_auth`, `USE_BIOMETRIC`, and `FlutterFragmentActivity`.
* Real bank sync needs an RBI Account Aggregator FIU relationship; it cannot be done client-only.
* A signed release keystore for Play Store distribution.
