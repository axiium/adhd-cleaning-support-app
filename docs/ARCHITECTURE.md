# Architecture baseline

## Technical direction

- Flutter and Dart for a shared Android/iOS codebase
- Material 3 for the initial design system
- Feature-first folders so related UI, state, and domain code stay together
- Offline-first behavior for the first release
- No account or cloud dependency in the MVP

## Initial structure

```text
lib/
  main.dart
  app.dart
  home_shell.dart
  core/
    domain/
    state/
  features/
    goals/
      domain/
      presentation/
    timer/
      presentation/
    today/
      domain/
      presentation/
test/
```

New areas should be introduced as product features rather than generic technical
layers. Likely next features are `timer`, `history`, and `settings`.

## State and storage

The prototype uses one `CleaningAppController` for goals and steps so every
screen observes the same state. `CleaningAppScope` exposes that controller
without a third-party state-management dependency.

Persistence sits behind a `CleaningRepository` boundary. The production
implementation stores a versioned JSON snapshot with `shared_preferences`;
tests use an in-memory implementation. This keeps the MVP lightweight while
leaving a clear migration path to SQLite if scheduling and history queries
outgrow snapshot storage.

Tasks retain a completion history rather than a permanent completed flag. The
current completion state is derived from the parent goal's cadence and the
local calendar period. Weekly periods begin Monday; monthly and yearly periods
begin on the first day of their respective periods.

The focus timer is deliberately session-only: stopping it does not change the
task, while finishing early or confirming completion at zero records the task
through the shared controller. Its countdown is based on an end timestamp so it
can correct itself after application lifecycle pauses.

## First vertical slice

The first slice proves this loop:

1. Create a cleaning goal.
2. Add one or more small steps to that goal.
3. Present eligible steps on Today.
4. Let the user complete a step or choose another.
5. Update Today and goal progress from one shared source of truth.
6. End with permission to stop.

## Near-term milestones

1. Generate the Android platform project with the Flutter SDK. (Complete)
2. Add goal creation and cadence selection. (Complete)
3. Connect goal steps to Today and shared progress. (Complete)
4. Persist goals and task completions locally. (Complete)
5. Make completion recur by daily, weekly, monthly, or yearly period. (Complete)
6. Add optional timers. (Complete)
7. Add carefully controlled reminders.
8. Test the interaction with people who experience task paralysis.
