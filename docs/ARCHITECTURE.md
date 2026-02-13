# Architecture — Athlos

## Strategy

**Local-first, built to scale.** The app launches fully functional and free with no server dependency. The architecture is structured so that adding a remote backend later requires no rewrites — only swapping data source implementations.

## Stack

| Layer      | V1 (Local)              | Future (Remote)                      |
| ---------- | ----------------------- | ------------------------------------ |
| Frontend   | Flutter                 | Flutter                              |
| State      | Riverpod                | Riverpod                             |
| DI         | Riverpod                | Riverpod                             |
| Database   | SQLite via Drift        | PostgreSQL (remote) + SQLite (cache) |
| Navigation | go_router               | go_router                            |
| Backend    | —                       | REST API or GraphQL                  |
| Auth       | —                       | Supabase Auth / Firebase Auth        |
| AI         | —                       | LLM API (Quíron)                    |
| Design     | Material 3 (custom)     | Material 3 (custom)                  |
| i18n       | PT-BR (i18n ready)      | Multilingual via ARB                 |
| Platforms  | Android + iOS           | Android + iOS + Web (possible)       |

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
│   ├── theme/
│   │   ├── athlos_theme.dart          # Main ThemeData
│   │   ├── athlos_color_scheme.dart   # Color palette (golds, marble, dark)
│   │   ├── athlos_text_theme.dart     # Typography
│   │   └── athlos_extensions.dart     # Custom ThemeExtensions (spacing, etc.)
│   ├── widgets/                       # Global reusable widgets
│   ├── router/                        # go_router configuration
│   └── utils/                         # Helpers and constants
├── features/
│   ├── training/                      # Training module
│   │   ├── domain/                    # Entities + Repository interfaces
│   │   ├── data/
│   │   │   ├── datasources/           # Local (SQLite) and future Remote (API)
│   │   │   ├── models/                # Data models (serialization)
│   │   │   └── repositories/          # Concrete repository implementations
│   │   └── presentation/              # Screens, widgets, controllers
│   ├── diet/                          # Diet module (same structure)
│   └── profile/                       # User profile
├── l10n/                              # ARB internationalization files
└── main.dart
```

### Domain Layer (contracts)

Defines **what** the app does, not **how**. Contains:

- **Entities** — pure domain objects (Exercise, Workout, Equipment, etc.)
- **Repository interfaces** — contracts defining available operations

### Data Layer (implementation)

Defines **how** data is obtained. Contains:

- **Data Sources** — concrete data providers
  - `LocalDataSource` — reads/writes to SQLite (V1)
  - `RemoteDataSource` — calls the API (future)
- **Repositories** — decide where to pull data from (local, remote, or both)

### Presentation Layer (UI)

Flutter screens and widgets. Consumes repositories through interfaces only — never knows if data comes from SQLite or an API.

## Evolution Plan

### V1 — Local & Free

- Flutter app with local SQLite
- All core Training module features
- Zero infrastructure cost
- Published to stores (Google Play / App Store)

### V2 — Backend & Sync

- Add `RemoteDataSource` to repositories
- API + PostgreSQL (Supabase or custom infra)
- User authentication
- Cross-device sync
- Cloud backup

### V3 — AI & Integrations

- Quíron: AI assistant (chat + workout/diet suggestions)
- Apple Health / Google Fit integration
- Possible premium features to cover AI costs

## Database Schema (V1)

SQLite will be structured with the same entities and relations the remote database will have. This eases future migration.

### Main Entities (Training Module)

- **Exercise** — exercise with muscle group, specific muscles, muscle region
- **Equipment** — training equipment
- **Workout** — workout (set of exercises)
- **WorkoutExecution** — record of a workout execution
- **UserProfile** — user profile (weight, height, goal, body aesthetic)

### Relations

- Exercise ↔ Exercise (self-relation: variations/substitutes)
- Exercise ↔ Equipment (many-to-many)
- Workout ↔ Exercise (many-to-many, with sets/reps)
- WorkoutExecution → Workout (an execution belongs to a workout)
- UserProfile ↔ Equipment (equipment the user owns)
