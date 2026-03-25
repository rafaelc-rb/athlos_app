# Project Context

## Name Origin

The name **Athlos** comes from *Dodekathlos* (Δωδέκαθλος) — the Twelve Labors of Heracles in Greek mythology. The word *athlos* (ἆθλος) means "labor", "trial", or "heroic feat". The app's visual identity and theme follow this Greek mythological line.

## Overview

Athlos is a modular health and fitness app built around independent modules. Development follows a **depth-first** strategy: each module is fully polished (bug-free, feature-complete within zero-cost constraints) before the next one begins. The first public release (1.0.0) ships with **Training** as the most complete free workout tracker possible — including advanced features like cardio support, execution feedback, supersets, training cycles, and AI assistance via Chiron (Gemini free tier). **Diet** follows with the same depth-first approach in subsequent 1.x releases. After the free modules are solid, a decision is made on whether to add more free modules or move to premium features.

The app is designed as a **hub-based** system: a central screen (the Hub) provides access to each module. Each module is a self-contained experience with its own home dashboard and navigation. New modules can be added without restructuring the app.

## Current Implementation Snapshot

- Local-first remains the default runtime mode (Drift on-device), with optional Supabase catalog sync.
- Backup is implemented as JSON **export/import with merge** (not destructive restore).
- Import conflict handling is item-by-item for workouts/catalog and field-by-field for profile data.
- Catalog reconciliation is implemented with governance workflow (`catalog_governance_events` / `catalog_governance_rules`) and idempotent multi-device rule application.
- The local database currently runs with schema version **12**.
- Automated tests are in place for core backup flows, training/profile repositories, use cases, provider wiring, and error/result contracts.

## Modules

| Module       | Status        | Target Version | Description                                         |
| ------------ | ------------- | -------------- | --------------------------------------------------- |
| Training     | 🔨 Building   | 1.0.0          | Workout registration, planning, tracking, cardio, execution feedback, cycles, AI (Chiron) |
| Diet         | 📋 Planned    | 1.x            | Food registration, meals, and caloric control       |
| Assessments  | 💡 Idea       | —              | Physical assessments, body measurements, progress photos |
| Progress     | 💡 Idea       | —              | Consolidated dashboard across all modules           |

See each module's documentation for details:

- [Training Module](./modules/training.md)
- [Diet Module](./modules/diet.md)

## Navigation

### Hub ("Olympus")

The Hub is the app's main screen — a central point from which the user accesses each module. Each module is represented as a card with a quick summary (e.g. last workout, today's macros). Profile/Settings is accessible from the Hub's app bar.

### Module Navigation

Each module has its own bottom navigation bar with sections relevant to that module. Entering a module takes the user into a focused experience; they can return to the Hub at any time.

```
Hub (Olympus)
├── Training → [Home] [Workouts] [History] [Exercises] [Equipment]
├── Diet     → [Home] [Meals]    [Foods]     [Log]
├── (future modules follow the same pattern)
└── Profile (via Hub app bar)
```

Each module's **Home** tab is a dashboard showing relevant summary data for that module.

## Development Strategy

Athlos follows a **depth-first, one-module-at-a-time** approach:

1. **Training** — fully polished, bug-free, with every feature achievable at zero cost (including Chiron AI via Gemini free tier)
2. **Diet** — same treatment: complete and polished before moving on
3. **Decision point** — evaluate whether to add more free modules or start building premium features

The guiding principle is: **maximize the value of each module before starting the next**. No half-finished features — each module ships as the best free version it can be.

## Monetization Strategy

Athlos follows a **freemium** model:

**Free (1.x — local):**
- Training module with all features (exercises, workouts, execution logging, cardio, supersets, cycles, execution feedback, history)
- Chiron AI assistant via Gemini free tier (personalized suggestions, Q&A chat)
- Diet module with all features (food registration, meal builder, caloric control)
- Exercise and food catalogs (pre-loaded)
- Verified catalog reconciliation via Supabase sync (catalog consistency/governance only)
- Full local history
- Manual data export/import (backup)

**Premium (future — requires account):**
- Cloud sync and automatic backup
- Multi-device support
- Advanced progression charts and trend analysis
- Kleos gamification (achievements, streaks, challenges)
- Formatted report exports (PDF)
- Extended AI capacity (beyond free tier limits)

The free tier must be fully functional and valuable on its own — good enough to attract and retain users. Premium features add convenience (sync, backup) and enhanced capabilities that justify a subscription.

## Versioning Strategy

Athlos follows [Semantic Versioning](https://semver.org/) adapted for app releases: `MAJOR.MINOR.PATCH+build`.

| Part | When to increment | Example |
| --- | --- | --- |
| **MAJOR** | Strategic milestone — first public release, backend migration, AI era | `1.0.0`, `2.0.0`, `3.0.0` |
| **MINOR** | New user-facing feature or module added | `1.0.0` → `1.1.0` |
| **PATCH** | Bug fixes, performance improvements, UI polish | `1.1.0` → `1.1.1` |
| **build** (`+N`) | Always incrementing integer for store identification — never resets | `+1`, `+2`, `+3`... |

PATCH resets to 0 when MINOR increments. MINOR resets to 0 when MAJOR increments. Build number never resets.

**Pre-1.0** (`0.x.x`) is development/beta phase — the app is not yet publicly released.

### Release Roadmap

```
0.x.0  — Development / beta (Training + Chiron)
1.0.0  — First public store release (Training fully polished + Chiron AI)
1.x.0  — Diet module (food registration → meal builder → caloric control)
  ...  — Patches between minors
 ?.0.0 — Decision: more free modules OR premium features
 x.0.0 — Backend, auth, cloud sync (Supabase)
 x.0.0 — Gamification (Kleos), integrations, extended AI
```

> **Note:** Major version numbers beyond 1.x are intentionally unassigned. The decision to go premium or add more free modules is made after Diet is complete, based on the state of the app and user feedback.

## Chiron (AI Assistant)

Chiron (Χείρων) is the app's AI assistant, inspired by the wise centaur from Greek mythology who mentored heroes like Achilles and Heracles. **Already implemented** using the Gemini API free tier (zero cost), Chiron is part of the 1.0.0 release — not a premium feature.

Current capabilities:
- Q&A chat for exercise and training questions
- Context-aware responses based on user profile and training data
- Accessible via app bar icon (bottom sheet)

Chiron-related ideas for future expansion:
- **Conversational onboarding** — instead of the current form-based profile setup, Chiron could conduct a natural chat to understand the user's profile (goals, aesthetic, training style, experience level, equipment, etc.). The conversation format allows the user to ask *why* Chiron is asking each question and get contextual explanations, making the process more human and less like filling out a form. The structured setup would remain as a fallback/quick option. This approach also opens the door for Chiron to gather richer context that static forms can't capture (e.g. injury history, schedule preferences, past training experience).
- **Multi-provider AI** — integrate multiple free-tier AI providers (e.g. Groq, Mistral, Cohere, OpenRouter) as fallbacks to multiply daily request capacity. When one provider's free tier limit is reached, Chiron routes to the next available one. This keeps AI free for users while scaling capacity without cost.
- **Personalized workout suggestions** based on user profile, equipment, and history
- **Meal suggestions** based on caloric targets and food preferences (after Diet module)
- **Trend analysis** of training and caloric data with actionable recommendations

## Future Ideas

- **Health app integrations** — Apple Health, Google Fit, etc. for importing activity data and body metrics.
- **Kleos (κλέος)** — gamification system named after the Greek concept of eternal glory and renown that heroes pursued. Achievements, streaks, challenges, and progression rewards to keep users motivated on their journey.
- **Assessments** — physical evaluations, body measurements, bioimpedance records, and progress photos to enrich AI context and track body changes over time.
  - **Body metrics timeline** — weight (and other metrics like body fat %, measurements) should not be a single static value in the profile. Instead, each entry is a timestamped record, building a historical timeline. The profile displays the latest value, but the user can view trends, charts, and deltas over time. This is essential for tracking real progress and gives Chiron richer context for recommendations. The current `weight` field in the profile would become just a convenience shortcut to the latest recorded value.
- **Consultations** — log visits to nutritionists, personal trainers, and doctors, keeping all health-related records in one place.
