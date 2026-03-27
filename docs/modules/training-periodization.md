# Training Periodization

> Status: 📋 Planned — design phase.

Evolution of the training module to support real-world periodization concepts, structured progression, and advanced training metrics — while keeping the experience simple for casual users.

## Design Principle

**Depth for those who seek it, simplicity for those who don't.** Casual users open the app, execute their workout, log weight and reps, done. Advanced users get RPE, PRs, weekly volume, periodization — all available but never in the way.

## Problems with the Current Model

### 1. Rest days in the cycle are artificial

`CycleStepType.rest` treats rest as a programmed step in the cycle. In reality, rest is simply the day the user doesn't train. The cycle should be a queue of workouts (A → B → C), not a sequence of workouts and rest days.

If the user skips a day (sick, gym closed, travel), the cycle loses sync. Users who train 6x/week (e.g. PPL) have no rest in their cycle — it's Push → Pull → Legs → repeat.

### 2. No concept of a training program (mesocycle)

Workouts exist in isolation. There's no grouping by purpose, duration, or training phase. A personal trainer builds a **program** — a package of workouts with a goal, a duration, and progression rules. The app doesn't have this.

### 3. No structured progression

No rules like "+2.5kg per week on squat" or "+1 set per week". All progression is reactive (user remembers, or Chiron notices from history) rather than proactive.

### 4. No awareness of training phases

No distinction between hypertrophy, strength, endurance, or deload blocks. These phases dictate volume, intensity, rep ranges, and rest — but the app treats every session identically.

## Planned Features

### Phase 1: Simplify the Cycle

**Remove `CycleStepType.rest`** — the cycle becomes a simple ordered list of workout IDs. When the user executes, they pick up the next workout in the queue. Rest is implicit.

- Remove `CycleStepType` enum
- `cycle_steps` table becomes: `id`, `orderIndex`, `workoutId` (non-nullable)
- Migration: drop existing rest steps, compact ordering
- Update Chiron's `setCycle` tool accordingly

### Phase 2: Training Program (Mesocycle)

Introduce the **Program** entity — a named, time-bound container for the training cycle.

```
Program
├── name: "PPL Hipertrofia"
├── focus: hypertrophy | strength | endurance | deload | custom
├── durationMode: sessions | rotations
├── durationValue: 12 (sessions) or 4 (rotations)
├── currentProgress: 7 (sessions completed)
├── deloadEvery: 4 (rotations, nullable)
├── isActive: true
├── createdAt / archivedAt
└── cycle: [Push, Pull, Legs] (ordered workout IDs)
```

**Key behaviors:**
- Only one active program at a time
- When the program's duration is reached, prompt for review (Chiron or UI)
- Archiving a program preserves it and its execution history
- Starting a new program archives the previous one
- Programs are optional — users can still train without one (free cycle mode)

### Phase 3: Progression Rules

Per-exercise progression rules within a program:

```
ProgressionRule
├── programId
├── exerciseId
├── type: incrementWeight | incrementReps | incrementSets
├── value: 2.5 (kg) or 1 (rep/set)
├── frequency: everySession | everyRotation | everyWeek
```

**Key behaviors:**
- When starting a session, the app suggests the target weight/reps based on progression rules + last execution
- Chiron can create progression rules when building a program
- Rules are optional — users who don't set them get the current behavior (manual)

### Phase 4: Training Metrics

New data points and computed analytics to enrich the training experience.

#### 4a. RPE / RIR (optional per set)

- Add optional `rpe` field (integer 1-10) to `ExecutionSet`
- UI: small optional input after completing a set (skip = not recorded)
- Chiron uses RPE data for better load recommendations

#### 4b. Estimated 1RM and PRs

- Computed from execution history using Epley formula: `1RM = weight × (1 + reps/30)`
- Show per-exercise PR badge in history and exercise detail
- Chiron can reference 1RM for percentage-based programming

#### 4c. Weekly Volume per Muscle Group

- Aggregate sets × muscle group from executions in the last 7 days
- Display on Training Home dashboard (optional card)
- Flag under-volume or over-volume based on experience level guidelines

#### 4d. Bodyweight as Load for Bodyweight Exercises

- For exercises marked as bodyweight (pull-ups, dips, etc.), total load = body weight (from profile) + added weight (from execution)
- Used in volume and 1RM calculations

### Phase 5: Warmup Sets

- Add `isWarmup` boolean to `ExecutionSet` (default: false)
- Warmup sets are visually distinct during execution (dimmed, smaller)
- Excluded from volume calculations, load suggestions, and progression tracking
- Optional: Chiron can suggest a warmup ramp based on the working weight

### Phase 6: Execution Notes per Exercise

- Add optional `notes` field to `ExecutionSet` (or per exercise within execution)
- Allows context like "shoulder pain on last rep", "try wider grip next time"
- Chiron can read these notes for future recommendations

### Phase 7: Body Weight Timeline

- New `body_metrics` table: `id`, `weight`, `bodyFatPercent` (nullable), `recordedAt`
- Profile `weight` becomes a convenience getter for the latest record
- Weekly prompt to record weight (dismissible, non-intrusive)
- Chart view in Profile showing weight trend over time
- Chiron uses the timeline for cutting/bulking analysis

## Chiron Integration

With periodization, Chiron gains **proactive triggers**:

- "Teu bloco de hipertrofia acabou (12 sessões). Quer que eu monte um bloco de força agora?"
- "Já são 4 rotações sem deload. Recomendo uma semana leve."
- "Teu agachamento deveria estar em 75kg essa semana pela progressão. Bora?"
- "Teu volume de peito tá em 8 séries/semana — abaixo do ideal pra hipertrofia. Quer que eu ajuste?"
- "Teu peso caiu 2kg nas últimas 3 semanas. Se tá em cutting, tá funcionando. Se não, revisa a dieta."

New Chiron tools:
- `createProgram` / `archiveProgram`
- `setProgressionRule`
- `getWeeklyVolume`
- `getEstimated1RM`

## UX Principles

- **All new features are optional** — casual users are unaffected
- **No new mandatory fields** — RPE, warmup toggle, notes are all skippable
- **Calculated metrics are passive** — shown in dedicated screens/cards, never blocking flows
- **Progressive disclosure** — program/periodization is there for who wants it; free cycle mode remains the default
- **Chiron as guide** — advanced features are discoverable through conversation ("Chiron, monta um programa pra mim")

## Migration Strategy

Each phase is a separate schema version bump. Phases are independent enough to ship incrementally:

1. Phase 1 (cycle simplification) can ship alone — it's a fix, not a feature
2. Phase 2 (program) depends on Phase 1
3. Phase 3 (progression) depends on Phase 2
4. Phases 4-7 (metrics) are independent of each other and of Phases 2-3

Recommended order: **1 → 4a → 5 → 6 → 2 → 3 → 4b → 4c → 4d → 7**

Rationale: start with the fix (1), then low-effort high-value additions (RPE, warmup, notes), then the bigger structural changes (program, progression), then computed metrics, then body weight timeline (which benefits from Diet module later).
