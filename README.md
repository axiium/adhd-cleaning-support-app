# Cleaning Support App

Early development documentation for a cross-platform mobile app designed to help people with ADHD-related task initiation and cleaning paralysis.

## Current status

The project has a working Android prototype and is ready for early user
testing. It is intentionally offline-first and stores data locally on the
device. The current build is not a production release and should not be used
as medical advice or as a replacement for professional care.

Completed product slices include:

- Daily, weekly, monthly, and yearly cleaning goals with custom schedules
- Small steps with editing, archiving, reordering, deletion confirmation, and undo
- Today view with progress, skip-for-now, timers, and energy-based rescue mode
- Optional gentle reminders with quiet hours, snooze, frequency limits, and persistence after repeated skips
- Completion history with filters, details, and a monthly calendar
- Room-based starter templates and first-run onboarding
- Accessibility preferences for text size, contrast, reduced motion, haptics, and screen-reader-friendly labels
- Task search and filters for room, energy, cadence, and duration
- Local JSON backup export and restore through the system file picker

Cross-platform cloud synchronization is deferred. No account or cloud service
is currently required.

## Development baseline

The prototype uses **Flutter and Dart** so Android and iOS can share one codebase. It starts with a dependency-light, feature-first structure and an offline-first product direction.

The initial runnable experience includes the core “Do one thing” loop and a
goal-creation flow. Users can add a goal with a cadence, room or area, and
typical energy level. Goals, small steps, and completion state are saved on the
device and restored when the app starts. Completed steps recur automatically
according to their goal's daily, weekly, monthly, or yearly cadence. Each due
step can also launch an optional focus timer with pause, finish-early, and
stop-without-penalty actions.

Goals and small steps can be edited, archived, restored, reordered, or removed
with an explicit warning. Archiving keeps completion history intact and keeps
the item out of Today; archiving a goal also pauses its reminder until the goal
is restored.

Weekly goals can use a preferred weekday, monthly goals a reliable date from
1–28, and yearly goals a month and day. A scheduled goal appears on that date
and remains available for the rest of its recurrence period, so missing one day
does not create an overdue state or hide the opportunity to begin. Optional
reminders follow the same preferred schedule.

Today also includes an energy-based rescue mode. The user can choose low,
medium, or high energy for the current moment and receive one due, unfinished
task. Exact matches are shown first, followed by gentler options; rescue mode
never recommends work above the selected energy and does not save or judge the
temporary choice.

Reminder controls include optional quiet hours, a cap on how many goals may
send reminders, and a configurable 15-, 30-, or 60-minute Snooze action on the
notification itself. Reminders that would occur during quiet hours wait until
the quiet period ends, including snoozed notifications.

For goals that need a little more support, gentle persistence can be enabled
per reminder. The user chooses how many explicit “Skip for now” actions trigger
a follow-up, how long to wait, and how many follow-ups are allowed in the
current recurrence period. Follow-ups remain silent, capped, and stop when the
task is completed.

### Local setup

Install Flutter and Android Studio with Android SDK command-line tools, then run:

```powershell
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter run
```

The application source is under `lib/`. The architecture and implementation
milestones are documented in `docs/ARCHITECTURE.md`.

### Android user-testing build

Create a fresh debug APK with:

```powershell
flutter build apk --debug
```

The APK is generated at
`build/app/outputs/flutter-apk/app-debug.apk`. Tester instructions are in
[`docs/USER_TESTING.md`](docs/USER_TESTING.md).

### Verification status

The current project passes Flutter analysis and the complete automated test
suite. The Android debug APK builds successfully on the development machine.

## 0. Remaining work

The next product work is early user testing with people who experience task
paralysis. Feedback should guide wording, task sizing, reminder behavior, and
onboarding before release preparation begins. Cloud synchronization remains
deferred until there is a clear privacy, security, and provider decision.

## 1. Product idea

The app helps users turn cleaning from an overwhelming, open-ended activity into a small number of clear next actions. Users can create cleaning goals across four time horizons:

- Daily
- Weekly
- Monthly
- Yearly

The app should be supportive and flexible. It is not intended to judge users, enforce perfect routines, or replace professional medical care.

## 2. Problem statement

Many people know that a space needs attention but struggle to decide where to begin, estimate the effort involved, or start the first task. A large cleaning goal can create avoidance, shame, and further paralysis.

The product should reduce the number of decisions required at the moment action is needed. It should answer:

> “What is one manageable thing I can do next?”

## 3. Target users

The initial audience is adults who experience ADHD-related executive-function challenges, especially:

- Task initiation difficulty
- Time blindness or poor effort estimation
- Feeling overwhelmed by multi-step chores
- Inconsistent energy, attention, or routines
- Shame or discouragement after missed tasks

The app should also be useful to anyone who benefits from gentle, highly actionable cleaning guidance.

## 4. Product principles

1. **Make the next action obvious.** Prefer one concrete action over a long list.
2. **Shrink tasks until they feel startable.** “Put away five items” is better than “clean the bedroom.”
3. **Support different energy levels.** A low-energy option should always be available.
4. **Use flexible progress.** Missed tasks should not create punishment or an impossible backlog.
5. **Encourage without shame.** The tone should be warm, practical, and neutral.
6. **Keep the interface calm.** Avoid unnecessary notifications, clutter, and competing choices.

## 5. MVP baseline

The first usable version should let a user:

1. Create a cleaning goal and assign it to a daily, weekly, monthly, or yearly schedule.
2. Break a goal into small tasks.
3. View a short “Today” list.
4. Get one recommended next task through a “Do one thing” action.
5. Mark a task complete, skip it, or defer it without losing progress.
6. Start an optional 2-, 5-, or 10-minute timer.
7. See simple progress for the current day and goal period.

The MVP should not initially depend on accounts, social features, complex gamification, or automatic judgment of cleanliness.

## 6. Core user experience

### Today

Shows a deliberately short list of suggested tasks. The user can choose a task or tap **Do one thing** to receive a recommendation.

### Do one thing

Presents one task with:

- A clear action verb
- An approximate effort or timer option
- A start button
- Complete, skip, and defer actions

### Goals

Allows users to create and review goals organized by frequency:

- Daily: maintain basic usability
- Weekly: reset or improve recurring areas
- Monthly: deeper cleaning or neglected areas
- Yearly: large projects and seasonal tasks

### Progress

Shows encouraging, low-pressure feedback such as completed tasks, time spent, or areas touched. Progress should not rely on streaks as the primary motivator.

## 7. Example goal model

**Goal:** Keep the kitchen usable

**Frequency:** Weekly

**Small tasks:**

- Put away five items
- Clear one section of the counter
- Wipe the table
- Take out the trash
- Load or unload five dishes

Tasks should be editable, repeatable, and small enough to complete independently.

## 8. Initial data concepts

The first data model will likely need:

- **Goal:** title, description, frequency, room/category, active status
- **Task:** title, goal, estimated duration, energy level, completion status
- **Schedule:** recurrence information and next suggested date
- **Completion:** task, timestamp, and optional duration
- **Reminder:** optional local schedule attached to one goal
- **User preferences:** default timer and tone/accessibility options

## 9. Success criteria for the first prototype

The prototype is successful if a new user can, without instruction:

- Create a goal in under two minutes
- Find a manageable task immediately
- Understand what to do next
- Complete or defer a task without confusion
- Return later without feeling punished for missed work
- Review completed steps without streak pressure or overdue messaging
- Adjust theme, text size, and motion without changing device-wide settings

The most important early measure is not total tasks completed. It is whether the app helps users begin.

## 10. Open questions

- Should the app ship with starter goals and task suggestions?
- How much customization is helpful before it becomes another source of overwhelm?
- Should tasks be selected randomly, by urgency, by energy level, or by room?
- What reminder behavior feels supportive rather than intrusive?
- Should “yearly” goals represent annual projects, seasonal routines, or both?
- Which accessibility features are needed first, such as large text, high contrast, sound, or vibration?

## 11. Suggested next step

Define the smallest clickable prototype around one loop:

> Create a goal → receive one small task → start or skip it → mark it complete → see gentle progress.

The next product slice is expanding completion history with useful filters and
detail while keeping it free of streak pressure.

---

**Status:** Early development idea  
**Document purpose:** Shared product baseline for exploration and prototyping  
**Last updated:** 2026-09-11
