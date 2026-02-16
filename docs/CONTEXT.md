# Athlos — Project Context

## Name Origin

The name **Athlos** comes from *Dodekathlos* (Δωδέκαθλος) — the Twelve Labors of Heracles in Greek mythology. The word *athlos* (ἆθλος) means "labor", "trial", or "heroic feat". The app's visual identity and theme follow this Greek mythological line.

## Overview

Athlos is a modular health and fitness app built around independent modules. The initial focus is on the **Training** module, with **Diet** and other modules planned for future releases.

The app is designed as a **hub-based** system: a central screen (the Hub) provides access to each module. Each module is a self-contained experience with its own home dashboard and navigation. New modules can be added without restructuring the app.

## Modules

| Module       | Status        | Description                                         |
| ------------ | ------------- | --------------------------------------------------- |
| Training     | 🔨 Priority   | Workout registration, planning, and tracking        |
| Diet         | 📋 Planned    | Food registration, meals, and caloric control       |
| Assessments  | 💡 Idea       | Physical assessments, body measurements, progress photos |
| Progress     | 💡 Idea       | Consolidated dashboard across all modules           |

See each module's documentation for details:

- [Training Module](./modules/TRAINING.md)
- [Diet Module](./modules/DIET.md)

## Navigation

### Hub ("Olympus")

The Hub is the app's main screen — a central point from which the user accesses each module. Each module is represented as a card with a quick summary (e.g. last workout, today's macros). Profile/Settings is accessible from the Hub's app bar.

### Module Navigation

Each module has its own bottom navigation bar with sections relevant to that module. Entering a module takes the user into a focused experience; they can return to the Hub at any time.

```
Hub (Olympus)
├── Training → [Home] [Workouts] [Exercises] [History]
├── Diet     → [Home] [Meals]    [Foods]     [Log]
├── (future modules follow the same pattern)
└── Profile (via Hub app bar)
```

Each module's **Home** tab is a dashboard showing relevant summary data for that module.

## Future Ideas

- **AI assistant (Chiron / Χείρων)** — inspired by Chiron, the wise centaur from Greek mythology who mentored heroes like Achilles and Heracles. The idea is to use Chiron as the AI persona, reinforcing the mythological theme. Features include personalized workout/diet suggestions and a Q&A chat. Could have its own card on the Hub.
  - **Conversational onboarding** — instead of the current form-based profile setup, Chiron could conduct a natural chat to understand the user's profile (goals, aesthetic, training style, experience level, equipment, etc.). The conversation format allows the user to ask *why* Chiron is asking each question and get contextual explanations, making the process more human and less like filling out a form. The structured setup would remain as a fallback/quick option. This approach also opens the door for Chiron to gather richer context that static forms can't capture (e.g. injury history, schedule preferences, past training experience).
- **Health app integrations** — Apple Health, Google Fit, etc. for importing activity data and body metrics.
- **Kleos (κλέος)** — gamification system named after the Greek concept of eternal glory and renown that heroes pursued. Achievements, streaks, challenges, and progression rewards to keep users motivated on their journey.
- **Assessments** — physical evaluations, body measurements, bioimpedance records, and progress photos to enrich AI context and track body changes over time.
- **Consultations** — log visits to nutritionists, personal trainers, and doctors, keeping all health-related records in one place.
