# Development Flow — Athlos

How to implement features following Clean Architecture, from the innermost layer outward.

## Feature Implementation Order

### 1. Domain (innermost — pure Dart, no dependencies)

Define **what** the app does.

1. **Enums** — finite types needed by the entity (e.g. `MuscleGroup`, `TrainingGoal`)
   - Location: `features/<module>/domain/enums/`
2. **Entity** — pure data class representing the business concept
   - Location: `features/<module>/domain/entities/`
   - No framework imports — only Dart and other domain types
3. **Repository interface** — contract defining available operations
   - Location: `features/<module>/domain/repositories/`
   - Uses only domain entities and enums as types

### 2. Data (implementation — Drift, Riverpod)

Define **how** data is obtained and stored.

4. **Drift table** — database schema for the entity
   - Location: `features/<module>/data/datasources/tables/`
   - Table names in plural (`Equipments`, `Exercises`)
   - Use `textEnum<T>()` for enum columns
   - Create junction tables for many-to-many relations
5. **Register table** in `AppDatabase` — add to `@DriftDatabase(tables: [...])`
   - Location: `core/database/app_database.dart`
   - Import the enum if the table uses `textEnum`
6. **DAO** — queries organized by feature
   - Location: `features/<module>/data/datasources/daos/`
   - Annotate with `@DriftAccessor(tables: [...])`
   - Register in `AppDatabase` `daos: [...]`
7. **Repository implementation** — concrete class that implements the domain interface
   - Location: `features/<module>/data/repositories/`
   - Receives a DAO via constructor
   - Maps Drift generated classes → domain entities (`_toDomain`)
   - Import `app_database.dart` for Companion classes
8. **Providers** — Riverpod providers for DAO and repository
   - Location: `features/<module>/data/repositories/`
   - DAO provider watches `appDatabaseProvider`
   - Repository provider watches the DAO provider
   - Use `@riverpod` annotation

### 3. Code Generation

9. **Run build_runner** to generate `.g.dart` files:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
   Or use watch mode during development:
   ```bash
   dart run build_runner watch --delete-conflicting-outputs
   ```

### 4. Presentation (UI — Flutter, Riverpod)

Define **how** data is displayed and interacted with.

10. **Screen** — main page for the feature
    - Location: `features/<module>/presentation/screens/`
    - Use `ConsumerWidget` or `ConsumerStatefulWidget`
    - Consume repositories via `ref.watch(repositoryProvider)`
    - Use `AsyncValue.when(data:, error:, loading:)` for async state
11. **Widgets** — feature-specific reusable components
    - Location: `features/<module>/presentation/widgets/`
    - Global reusable widgets go in `core/widgets/`
12. **State providers** — UI-specific logic (if needed beyond repository calls)
    - Location: `features/<module>/presentation/`
    - Keep them small and focused
13. **Route** — register the screen in go_router
    - Add path constant to `core/router/route_paths.dart`
    - Add `GoRoute` to `core/router/app_router.dart`

### 5. Internationalization

14. **Strings** — add user-facing text to ARB file
    - Location: `l10n/app_pt.arb`
    - Use `AppLocalizations.of(context)!.keyName` in widgets
15. **Regenerate**:
    ```bash
    flutter gen-l10n
    ```

### 6. Validate

16. **Analyze** — check for errors and lint warnings:
    ```bash
    flutter analyze
    ```
17. **Test** (when applicable):
    ```bash
    flutter test
    ```

## Dependency Direction

```
Presentation → Domain ← Data
     ↓            ↑         ↓
  (widgets)   (entities)  (SQLite)
  (screens)  (interfaces) (DAOs)
  (providers) (enums)    (repos)
```

- **Domain** imports nothing from Data or Presentation
- **Data** imports Domain (to implement interfaces)
- **Presentation** imports Domain (to use interfaces via providers)
- **Presentation never accesses Data directly** — always through a repository provider

## Checklist Template

When implementing a new feature, copy this checklist:

```
- [ ] Domain enum(s)
- [ ] Domain entity
- [ ] Repository interface
- [ ] Drift table(s)
- [ ] Register in AppDatabase
- [ ] DAO
- [ ] Register DAO in AppDatabase
- [ ] Repository implementation
- [ ] Riverpod providers (DAO + Repository)
- [ ] build_runner
- [ ] Screen
- [ ] Widgets
- [ ] Route
- [ ] ARB strings
- [ ] flutter gen-l10n
- [ ] flutter analyze
```
