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
    history/
      domain/
      presentation/
    reminders/
      application/
      domain/
      infrastructure/
    settings/
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
layers. Likely next features are `settings`, `editing`, and `onboarding`.

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

The app refreshes recurrence state at local midnight and whenever it resumes
from the background. This keeps Today accurate across a calendar boundary
without rewriting or deleting completion history.

The focus timer is deliberately session-only: stopping it does not change the
task, while finishing early or confirming completion at zero records the task
through the shared controller. Its countdown is based on an end timestamp so it
can correct itself after application lifecycle pauses.

Each goal may have one opt-in local reminder. The app asks for notification
permission only after the user chooses a time, uses quiet notification settings,
and schedules with the device time zone. Reminder delivery is intentionally
inexact on Android so the app does not require exact-alarm access. Scheduling is
behind a `ReminderScheduler` boundary so permission denial and scheduling can be
tested without platform services. An explicit test action sends an immediate
notification so users can verify permission and presentation without waiting for
the next recurring time.

History is derived directly from task completion timestamps rather than stored
as a second copy of the data. Entries are sorted newest first and grouped by
local calendar day. The screen offers today and current-week totals while
deliberately avoiding streaks, overdue counts, or missed-day messaging.

Goal and step edits retain stable IDs and existing completion timestamps. Goal
removal cascades to its steps and cancels any scheduled reminder. Because removal
also erases associated history, both goal and step removal require an explicit
confirmation that describes the consequence.

Goals and tasks also carry an archive flag. Active-list order is represented by
the order of items in the persisted snapshot, avoiding a second ordering field.
Archived items remain in that snapshot so History can still resolve their names
and completion timestamps. Active views filter archived tasks and tasks whose
parent goal is archived. Goal archiving cancels its notification schedule;
restoring the goal schedules its retained reminder again.

Each goal owns a `GoalSchedule` in addition to its cadence. Daily goals are
always eligible; weekly, monthly, and yearly goals become eligible on their
preferred date and remain eligible through the current recurrence period. This
avoids a fragile one-day window and deliberately does not create overdue state.
Monthly choices are limited to days 1–28 so both availability and recurring
local notifications behave consistently in every month. Reminder recurrence is
aligned to the goal schedule whenever a goal is edited, and older snapshots are
migrated using their reminder date or the migration date as a fallback.

Reminder delivery preferences live in the same versioned `AppPreferences`
snapshot. Quiet hours adjust the next local delivery to the end of the quiet
window, and changing reminder preferences reschedules active goal reminders.
An active-reminder cap prevents enabling more notification streams than the
chosen limit. Android and iOS notification actions carry a small JSON payload
so Snooze can schedule a one-off local notification from either the foreground
or background callback; the payload includes quiet-hour settings so snoozed
delivery respects the same boundary without requiring an account or server.

Skip tracking is explicit rather than inferred from an unopened notification:
each task stores skip timestamps alongside completion timestamps. When a task’s
skip count reaches its goal reminder threshold, the controller schedules a
one-off escalation after the configured delay, capped by the configured maximum
for that recurrence period. Completion cancels outstanding escalation IDs.
This keeps “more persistent” opt-in, bounded, and reversible through normal
task completion.

Energy rescue mode is session-only UI state on Today. It receives the same due,
active, unfinished tasks already eligible for Today and orders exact energy
matches before lower-energy alternatives. Tasks above the selected energy are
excluded. The choice is intentionally not persisted because it describes the
current moment rather than a user profile or performance metric.

Completion is reversible within the current recurrence period. Undo filters out
only timestamps from that period, retaining older history. Today provides an
immediate snackbar action after completion, and task status icons act as explicit
complete/not-done toggles on both Today and goal detail screens.

App preferences are stored in the same versioned snapshot as goals and tasks.
Theme mode, an additional text-scale multiplier, and reduced-motion behavior are
applied at the app root so dialogs and feature screens inherit the same choices.
System text scaling remains the baseline rather than being replaced.

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
7. Add carefully controlled reminders. (Complete)
8. Add a gentle completion history. (Complete)
9. Add editing and confirmed removal for goals and steps. (Complete)
10. Make accidental completion reversible. (Complete)
11. Add persistent appearance and motion preferences. (Complete)
12. Finish goal and step management with archive, restore, and reorder. (Complete)
13. Add custom weekday, monthly-date, and annual-date scheduling. (Complete)
14. Add energy-based rescue mode. (Complete)
15. Finish quiet hours, snooze, and reminder frequency limits. (Complete)
16. Expand completion-history filtering and detail. (Complete)
17. Add starter templates organized by room. (Complete)
18. Add first-run onboarding for rooms, energy, and starter goals. (Complete)
19. Add accessibility settings for text, contrast, motion, haptics, and screen readers. (Complete)
20. Add task search and filters for room, duration, energy, and cadence. (Complete)
21. Add local backup and export/restore.
22. Test the interaction with people who experience task paralysis.
