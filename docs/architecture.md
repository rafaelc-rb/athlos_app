# Architecture — Athlos

## Strategy

**Local-first, built to scale.** The app launches fully functional and free with no server dependency. The architecture is structured so that adding a remote backend later requires no rewrites — only swapping data source implementations.

## Stack

| Layer      | V1 (Local)              | V2 (Supabase)                        | V3 (AI & Integrations)               |
| ---------- | ----------------------- | ------------------------------------ | ------------------------------------ |
| Frontend   | Flutter                 | Flutter                              | Flutter                              |
| State      | Riverpod                | Riverpod                             | Riverpod                             |
| DI         | Riverpod                | Riverpod                             | Riverpod                             |
| Database   | SQLite via Drift        | PostgreSQL (Supabase) + SQLite (local cache) | PostgreSQL (Supabase) + SQLite |
| Navigation | go_router               | go_router                            | go_router                            |
| Backend    | —                       | Supabase (PostgREST + Edge Functions) | Supabase + Go API (custom logic)    |
| Auth       | —                       | Supabase Auth                        | Supabase Auth                        |
| AI         | —                       | —                                    | LLM API via Go (Quíron)             |
| IaC        | —                       | Terraform                            | Terraform                            |
| Design     | Material 3 (custom)     | Material 3 (custom)                  | Material 3 (custom)                  |
| i18n       | PT-BR (i18n ready)      | Multilingual via ARB                 | Multilingual via ARB                 |
| Platforms  | Android + iOS           | Android + iOS                        | Android + iOS + Web (possible)       |

## Technical Decisions

### Riverpod (state + DI)

Manages app state and dependency injection in a single package. Swapping `LocalDataSource` for `RemoteDataSource` is a simple provider override — no UI changes needed. Type-safe and decoupled from BuildContext.

### Drift (local database)

Type-safe ORM for SQLite with code generation. Native support for relations (essential for Athlos entities), built-in migration system to update the schema without data loss, and generates reusable SQL for the future PostgreSQL migration.

### go_router (navigation)

Declarative routing recommended by the Flutter team. Deep linking support ready for future use (opening a workout via notification/link). Lightweight with no additional code generation.

### Material 3 (design)

Material 3 as a solid accessible component base, customized with a Greek mythology-inspired palette (golds, marble tones, dark shades). Custom typography and iconography to reinforce the Athlos identity.

### Internationalization (i18n)

Strings centralized in ARB files from day one using `flutter_localizations`. The app launches in PT-BR, but adding new languages is just translating the file — no refactoring.

## App Structure

Clean Architecture with an abstracted data layer. Swapping from local SQLite to a remote API means replacing the data source implementation only.

```
lib/
├── core/
│   ├── errors/
│   │   ├── app_exception.dart         # Sealed exception hierarchy
│   │   └── result.dart                # Result<T> type (Success / Failure)
│   ├── theme/
│   │   ├── athlos_theme.dart          # Main ThemeData
│   │   ├── athlos_color_scheme.dart   # Color palette (golds, marble, dark)
│   │   ├── athlos_text_theme.dart     # Typography
│   │   ├── athlos_spacing.dart        # Spacing tokens
│   │   ├── athlos_radius.dart         # Border radius tokens
│   │   ├── athlos_durations.dart      # Animation duration tokens
│   │   └── athlos_elevation.dart      # Elevation tokens
│   ├── widgets/
│   │   ├── buttons/                   # Button variants
│   │   ├── cards/                     # Card variants
│   │   ├── inputs/                    # Text fields, search bars, selectors
│   │   ├── feedback/                  # Dialogs, empty states, loading indicators
│   │   ├── layout/                    # Section headers, spacing helpers
│   │   └── overlays/                  # Bottom sheets, modals
│   ├── presentation/
│   │   └── screens/                   # Core screens (SplashScreen)
│   ├── router/                        # go_router configuration
│   └── utils/                         # Helpers and constants
├── features/
│   ├── training/                      # Training module
│   │   ├── domain/
│   │   │   ├── entities/              # Pure domain objects
│   │   │   ├── enums/                 # Domain enums (MuscleGroup, etc.)
│   │   │   ├── repositories/          # Repository interfaces (contracts)
│   │   │   └── usecases/              # Business logic operations
│   │   ├── data/
│   │   │   ├── datasources/           # Local (SQLite) and future Remote (API)
│   │   │   ├── models/                # Data models / DTOs (serialization)
│   │   │   └── repositories/          # Concrete repository implementations
│   │   └── presentation/
│   │       ├── screens/               # Full pages
│   │       ├── widgets/               # Module-specific components
│   │       ├── providers/             # UI state providers (AsyncNotifiers)
│   │       └── helpers/               # Presentation helpers (l10n, formatters)
│   ├── diet/                          # Diet module (same structure)
│   └── profile/                       # User profile (shared across modules)
├── l10n/                              # ARB internationalization files
└── main.dart
```

### Domain Layer (contracts + business logic)

Defines **what** the app does, not **how**. Contains:

- **Entities** — pure domain objects (Exercise, Workout, Equipment, etc.)
- **Enums** — finite domain types (MuscleGroup, TrainingGoal, etc.)
- **Repository interfaces** — contracts defining available data operations
- **Use Cases** — single-responsibility business operations that orchestrate repositories

### Data Layer (implementation)

Defines **how** data is obtained. Contains:

- **Data Sources** — concrete data providers
  - `LocalDataSource` — reads/writes to SQLite (V1)
  - `RemoteDataSource` — calls the API (future)
- **Models / DTOs** (future) — in V1, Drift row types are mapped directly to domain entities in repositories via `_toDomain()`. In V2, JSON models for API serialization will live in `data/models/`.
- **Repositories** — implement domain interfaces, decide where to pull data from (local, remote, or both)

### Presentation Layer (UI)

Flutter screens and widgets. Consumes **Use Cases** (or repository providers for simple CRUD) — never accesses data sources directly.

- **Screens** — full pages, equivalent to "Pages" in Atomic Design
- **Widgets** — module-specific components that depend on domain types from that feature
- **Providers** — `AsyncNotifier` / `Notifier` providers managing UI state, calling Use Cases
- **Helpers** — presentation-specific helper functions (l10n helpers, formatters, etc.)

## Error Handling

Errors flow through layers using a `Result<T>` sealed type and a sealed `AppException` hierarchy. This keeps error handling explicit, type-safe, and consistent across all features.

### Result Type

```dart
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final AppException exception;
  const Failure(this.exception);
}
```

### Exception Hierarchy

```dart
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

class DatabaseException extends AppException {
  const DatabaseException(super.message);
}

class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;
  const ValidationException(super.message, {this.fieldErrors});
}

class ConflictException extends AppException {
  const ConflictException(super.message);
}
```

New exception types can be added as needed (e.g. `NetworkException` in V2).

### Error Flow Across Layers

```
Repository (Data)       → returns Result<T>
Use Case (Domain)       → receives Result<T>, can compose/transform, returns Result<T>
Provider (Presentation)   → unwraps Result<T> via getOrThrow()
UI (Presentation)       → consumes AsyncValue.when(data:, error:, loading:)
```

**Repositories** catch data-layer exceptions (Drift errors, future API errors) and wrap them into `Result.failure(AppException)`. Repositories never throw.

**Use Cases** receive `Result<T>` from repositories. They can short-circuit on failure, compose multiple results, or add validation logic. They return `Result<T>`.

**Providers** (AsyncNotifiers) call Use Cases and unwrap the Result using `getOrThrow()`:

- In `build()` methods, `getOrThrow()` is idiomatic — Riverpod automatically catches exceptions and converts them to `AsyncError`.
- In mutation methods (`create`, `delete`, etc.), `getOrThrow()` propagates the exception to the caller (UI).

```dart
// In build() — Riverpod handles the exception automatically
@override
Future<List<Workout>> build() async {
  final result = await repository.getAll();
  return result.getOrThrow();
}

// In mutations — exception propagates to the UI caller
Future<void> deleteWorkout(int id) async {
  final result = await repository.delete(id);
  result.getOrThrow();
  ref.invalidateSelf();
}
```

**UI** consumes `AsyncValue.when()` for read state. For mutations, the UI wraps calls in `try/catch` and shows error feedback (snackbar):

```dart
try {
  await ref.read(provider.notifier).deleteWorkout(id);
  // show success snackbar
} on Exception catch (_) {
  // show error snackbar
}
```

## Use Cases

Use Cases encapsulate **single business operations**. They live in the Domain layer and are the boundary between Presentation and Data.

### Structure

```dart
class CreateWorkoutUseCase {
  final WorkoutRepository _workoutRepository;
  final ExerciseRepository _exerciseRepository;

  const CreateWorkoutUseCase(this._workoutRepository, this._exerciseRepository);

  Future<Result<Workout>> call(CreateWorkoutParams params) async {
    // Validate, orchestrate, return Result
  }
}
```

### Rules

- **One public method** — `call()` (makes the class callable: `useCase(params)`)
- **One responsibility** — a Use Case does one thing. If it's doing too much, split it.
- **No framework imports** — pure Dart only. No Flutter, no Riverpod, no Drift.
- **Receives repositories via constructor** — injected through Riverpod providers
- **Parameters via dedicated class** when more than 2 params — e.g. `CreateWorkoutParams`
- **Returns `Result<T>`** — never throws

### When to Use vs. When to Skip

| Scenario | Use Case needed? |
| --- | --- |
| Simple CRUD with no logic (get list, delete by id) | No — controller calls repository directly via provider |
| Operation with validation or business rules | Yes |
| Operation that touches multiple repositories | Yes |
| Operation that will grow in complexity (e.g. log execution) | Yes — even if simple now |

For simple CRUD, the controller can consume the repository provider directly. Use Cases are not mandatory for every operation — they exist to encapsulate **business logic**, not to be a pass-through layer.

## Design Tokens

The visual identity of Athlos is built on **Design Tokens** — primitive values that ensure consistency across all components and modules.

### Token Categories

| Token | File | Examples |
| --- | --- | --- |
| Colors | `athlos_color_scheme.dart` | Primary gold, marble, dark shades |
| Typography | `athlos_text_theme.dart` | Font family, sizes, weights |
| Spacing | `athlos_spacing.dart` | `xs: 4`, `sm: 8`, `md: 16`, `lg: 24`, `xl: 32`, `xxl: 48` |
| Radius | `athlos_radius.dart` | `sm: 8`, `md: 12`, `lg: 16`, `full: 999` |
| Elevation | `athlos_elevation.dart` | `none: 0`, `sm: 1`, `md: 3`, `lg: 6` |
| Durations | `athlos_durations.dart` | `fast: 150ms`, `normal: 300ms`, `slow: 500ms` |

### Usage

Tokens are defined as `abstract class` with static constants (no instantiation). Every widget uses tokens instead of hardcoded values:

```dart
// Good
Padding(padding: EdgeInsets.all(AthlosSpacing.md))
BorderRadius.circular(AthlosRadius.sm)

// Bad
Padding(padding: EdgeInsets.all(16))
BorderRadius.circular(8)
```

Colors and typography are consumed through `Theme.of(context)` as before — tokens complement the theme, they don't replace it.

## Widget Organization

Global reusable widgets live in `core/widgets/`, organized by **type** (not abstraction level):

```
core/widgets/
├── buttons/       → Button variants (icon buttons, primary, outline, etc.)
├── cards/         → Card variants (stat card, module card, info card, etc.)
├── inputs/        → Text fields, search bars, selectors, pickers
├── feedback/      → Dialogs, snackbars, empty states, loading indicators
├── layout/        → Section headers, dividers, content spacing helpers
└── overlays/      → Bottom sheets, modals, dropdown menus
```

### Placement Rules

| Question | Location |
| --- | --- |
| Does it depend on a domain type from a specific feature? | `features/<module>/presentation/widgets/` |
| Is it purely visual and reusable across modules? | `core/widgets/<type>/` |
| Is it a full page with a route? | `features/<module>/presentation/screens/` |

**Rule of thumb**: if a widget imports anything from `features/*/domain/`, it belongs to that feature's `presentation/widgets/`, not to `core/widgets/`.

### Naming

All global widgets are prefixed with `Athlos` to avoid collisions with Material widgets and to make them easily discoverable:

- `AthlosPrimaryButton`, `AthlosIconButton`
- `AthlosStatCard`, `AthlosModuleCard`
- `AthlosSearchBar`, `AthlosConfirmDialog`

Feature-specific widgets don't need the prefix — their location already provides context.

### Growing the Design System

Don't create components speculatively. Extract a widget into `core/widgets/` when it appears in **two or more features** with the same structure. Until then, it lives in the feature that uses it.

## Inter-Module Communication

Modules are independent, but some data is shared. The rules for cross-module communication:

### Shared Domain (`core/`)

Entities and interfaces that span multiple modules live in `core/`:

- `UserProfile` — used by Training (goals, body metrics), Diet (caloric targets), and future modules
- `BodyMetric` (future) — timestamped records (weight, body fat %) consumed by multiple modules

```
core/
├── domain/
│   ├── entities/          # Shared entities (UserProfile, etc.)
│   └── repositories/      # Shared repository interfaces
```

### Cross-Module Data Access

When a module needs data from another module (e.g. Diet needs caloric expenditure from Training):

1. Define a **shared interface** in `core/domain/repositories/` describing the data contract
2. The source module implements that interface in its `data/repositories/`
3. The consuming module depends on the **interface**, never on the source module's internals

```
core/domain/repositories/
  └── caloric_data_repository.dart    # Interface: getCaloriesSpent(date)

features/training/data/repositories/
  └── training_caloric_data_repository.dart  # Implements the interface using training data
```

This keeps modules decoupled — if Training is replaced or refactored, only its implementation changes.

### Rules

- **Modules never import each other's domain or data layers directly**
- **Shared contracts live in `core/domain/`** — both sides depend on the abstraction
- **Feature-specific entities stay in the feature** — only truly shared concepts go to `core/`
- **When in doubt, keep it in the feature** — premature sharing creates tight coupling

### Known Exception: AppDatabase

`core/database/app_database.dart` imports tables and DAOs from all features because Drift requires a single central database class with all tables registered. This creates a `core → features` dependency that violates the general rule. This is an accepted trade-off — the alternative (one database per feature) would prevent cross-feature transactions and complicate migrations.

## Complex Scenarios

### Transactions (atomic operations)

When a user action must write to multiple tables atomically (e.g. creating a workout with exercises and sets), use Drift's `transaction()`:

```dart
Future<Result<Workout>> createWorkout(CreateWorkoutParams params) async {
  try {
    final workout = await db.transaction(() async {
      final workoutId = await _workoutDao.insert(params.workout);
      await _workoutExerciseDao.insertAll(params.exercises, workoutId);
      await _setDao.insertAll(params.sets, workoutId);
      return _workoutDao.getById(workoutId);
    });
    return Success(workout.toDomain());
  } on Exception catch (e) {
    return Failure(DatabaseException('Failed to create workout: $e'));
  }
}
```

Transactions live in the **Repository** (Data layer) — the Domain and Presentation don't know about them.

### Multi-Step Form State

Complex forms (e.g. Workout Builder) use a dedicated `Notifier` that accumulates state across steps:

```dart
@riverpod
class WorkoutBuilderController extends _$WorkoutBuilderController {
  @override
  WorkoutBuilderState build() => const WorkoutBuilderState.initial();

  void setName(String name) { ... }
  void addExercise(Exercise exercise) { ... }
  void configureSets(ExerciseId id, List<SetConfig> sets) { ... }
  Future<Result<Workout>> save() async { ... }
}
```

The state object (`WorkoutBuilderState`) holds all intermediate data. The final `save()` calls the Use Case with the accumulated params.

### Pagination

For large lists (e.g. exercise catalog), use a paginated provider:

- Drift: `limit()` + `offset()` queries in the DAO
- Riverpod: an `AsyncNotifier` that holds the current page and a `fetchNext()` method
- UI: infinite scroll with a `ScrollController` listener that triggers `fetchNext()`

### Navigation Pattern

Hub-based architecture using go_router:

- **Splash** — shown at `/splash` while the app resolves initial async state (e.g. `hasProfileProvider`). GoRouter redirect navigates away once resolved. `FlutterNativeSplash` covers the gap before the Flutter engine is ready.
- **Hub** — central screen with module cards. Uses a simple `GoRoute`.
- **Module shells** — each module uses `ShellRoute` with its own `NavigationBar` (bottom bar). Tabs are specific to each module. Data is preserved across tab switches via Riverpod providers; `StatefulShellRoute` can be adopted later if tabs need to preserve local widget state (scroll position, text fields, etc.).
- **Profile** — accessible from the Hub's app bar, not tied to any module.

```
/splash                 → Splash (startup loading)
/                       → Hub (Olympus)
/profile                → User profile
/training               → Training shell
/training/home          → Training dashboard
/training/workouts      → Workout list
/training/exercises     → Exercise catalog
/training/history       → Execution history
/diet                   → Diet shell
/diet/home              → Diet dashboard
/diet/meals             → Meal list
/diet/foods             → Food catalog
/diet/log               → Daily log
```

## Evolution Plan

### V1 — Local & Free

- Flutter app with local SQLite
- Training module (full feature set)
- Diet module (full feature set)
- Manual data export/import for backup (JSON)
- Zero infrastructure cost — everything runs on-device
- Published to stores (Google Play / App Store) to build a user base
- Freemium model: all core features free, premium features defined but not gated yet

### V2 — Supabase & Premium

No custom API. Supabase provides everything V2 needs:

- **Supabase Auth** — email/password + OAuth (Google, Apple)
- **PostgREST** — auto-generated REST API from PostgreSQL schema (no endpoints to write)
- **Realtime** — websocket subscriptions for multi-device sync
- **RLS Policies** — row-level security on PostgreSQL (authorization without server code)
- **Edge Functions** — Deno/TypeScript for custom logic (e.g. local-to-cloud data migration)
- **Terraform** — infrastructure as code for provisioning and portability

Flutter changes:
- Add `RemoteDataSource` using Supabase SDK (implements same repository interfaces)
- Repositories orchestrate local (Drift) + remote (Supabase) data sources
- SQLite becomes a local cache; Supabase PostgreSQL becomes the source of truth

Premium features unlocked:
- Cloud sync and automatic backup
- Multi-device support
- Advanced progression charts

### V3 — Go API, AI & Integrations

Custom **Go API** for logic that exceeds Supabase's capabilities:

- **Quíron** — AI orchestration (LLM context management, prompt engineering, response streaming)
- **Health integrations** — Apple Health / Google Fit (server-side OAuth + data processing)
- **Async jobs** — trend analysis, report generation, heavy computations
- **Kleos** — gamification system (achievements, streaks, challenges)

Supabase continues handling CRUD, auth, sync, and realtime. Go API handles premium intelligence and integrations. Both managed via Terraform.

## Database Schema (V1)

SQLite will be structured with the same entities and relations the remote database will have. This eases future migration.

> **Migration note:** During early development, `onUpgrade` recreates all tables (destructive). Before the first public release, this must be replaced with incremental versioned migrations to preserve user data.

### Main Entities

**Training Module:**

- **Exercise** — exercise with muscle group, specific muscles, muscle region
- **Equipment** — training equipment
- **Workout** — workout (set of exercises)
- **WorkoutExecution** — record of a workout execution

**Diet Module:**

- **Food** — food item with macronutrient data (kcal, protein, carbs, fat)
- **Meal** — a collection of foods with quantities
- **DailyLog** — aggregated meals and caloric data for a given day

**Shared:**

- **UserProfile** — user profile (weight, height, goal, body aesthetic)

### Relations

- Exercise ↔ Exercise (self-relation: variations/substitutes)
- Exercise ↔ Equipment (many-to-many)
- Workout ↔ Exercise (many-to-many, with sets/reps)
- WorkoutExecution → Workout (an execution belongs to a workout)
- UserProfile ↔ Equipment (equipment the user owns)
- Meal ↔ Food (many-to-many, with quantity)
- DailyLog ↔ Meal (one-to-many)
