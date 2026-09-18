# Home-screen widget plan

## Purpose

The next product update should add a small Android home-screen widget that
reduces the number of steps between feeling stuck and seeing one approachable,
low-energy task. The widget is an extension of Today, not a separate task
system. This scope comes directly from tester feedback: keep low-energy work on
the home screen, and open the full app when the user wants higher-energy work.

The first release should answer one question:

> What is one low-energy thing I can do right now?

## First-release scope

The initial widget should:

- Show one due, active, unfinished step marked **Low energy**.
- Show its estimated duration and room or goal for context.
- Offer **Done**, **Another**, and **Open app** actions.
- Record **Done** through the same completion rules and history used by the app.
- Make **Another** rotate suggestions without counting as a skip or triggering a
  persistent reminder.
- Open Today when the user taps the task or **Open app**, where medium- and
  high-energy choices remain available.
- Refresh after task, goal, schedule, archive, restore, backup-restore, and
  completion changes.
- Refresh when the recurrence period changes, including after local midnight.
- Work without an account or network connection.

Android is the implementation target for this update because it can be built
and tested on the current development machine. An iOS WidgetKit version should
remain a later compatibility slice requiring macOS, Xcode, signing, and iPhone
testing.

## Widget states

### Low-energy task available

- Heading: **One low-energy thing**
- Task title
- Supporting text: duration and room or goal
- Primary action: **Done**
- Secondary action: **Another**
- Tap elsewhere: open Today

### No low-energy task currently due

- Message: **No low-energy steps are ready right now.**
- Action: **Open app for more choices**
- Do not use overdue, missed-day, streak, or catch-up language.

### App data unavailable

- Message: **Open the app to refresh your tasks.**
- Action: **Open app**
- Do not show stale completion controls when the widget cannot safely read data.

## Behavior decisions

- Suggestions use the same active/due filtering as Today and then require an
  exact **Low energy** rating.
- The widget never falls back to medium- or high-energy tasks. Broader energy
  choices belong inside the app, where the user can make that decision.
- Archived and currently completed steps are never suggested.
- **Another** is session-like rotation only. It does not save a skip because a
  home-screen glance should not increase reminder persistence.
- **Done** preserves accidental-tap recovery. After completion, the widget
  should briefly expose **Undo**, or open the app to a completion confirmation
  if reliable inline Undo is not supported by the chosen platform approach.
- One-time steps remain completed until explicitly undone or restored; repeating
  steps follow their goal cadence.
- The widget should never start a timer or display reminder-pressure messaging.

## Privacy and accessibility

- Add a widget privacy setting with **Show task details** enabled by default and
  a **Hide task names** option for shared devices.
- When details are hidden, use neutral copy such as **A small step is ready** and
  keep the open-app action available.
- Support Android widget resizing, system text scaling, high contrast, and
  screen-reader labels.
- Keep touch targets at least 48 logical pixels and avoid meaning conveyed only
  by color.
- Do not place private task content in logs, analytics, or notification payloads.

## Technical approach

1. Extract task-selection ordering from Today into a reusable domain service so
   the app and widget cannot quietly choose from different task pools; expose a
   low-energy-only selection path for the widget.
2. Create a minimal, versioned widget projection containing only the selected
   task ID and display fields needed by the launcher.
3. Update that projection whenever the main controller successfully persists a
   relevant state change.
4. Add the Android widget receiver/provider and bridge its actions back to the
   shared completion behavior.
5. Schedule a lightweight calendar-boundary refresh and request a refresh when
   the app resumes.
6. Keep the platform bridge behind an interface with a no-op implementation so
   normal app tests and future iOS work remain isolated.

The implementation should select and pin a maintained Flutter/Android widget
integration package only after a short compatibility check against the current
Flutter, Android Gradle, and Kotlin setup.

## Testing and acceptance criteria

The slice is complete when:

1. A tester can add the widget from the Android launcher.
2. The widget shows an eligible unfinished low-energy task from Today and never
   substitutes a medium- or high-energy task.
3. **Another** changes to another low-energy suggestion without recording a
   skip.
4. **Done** updates Today, goal progress, and completion history exactly once.
5. Accidental completion has a tested recovery path.
6. Completing, archiving, restoring, editing, or deleting the displayed task
   refreshes the widget without leaving an invalid action behind.
7. The empty and unavailable states use gentle, non-judgmental wording.
8. The widget remains usable at supported resize bounds and enlarged text.
9. The feature works offline and introduces no account requirement.
10. Automated domain and widget-bridge tests pass, Flutter analysis is clean,
    and the README and user-testing guide are updated with the completed flow.

## Explicitly deferred

- Multiple simultaneous task widgets
- Goal- or room-pinned widgets
- Medium- or high-energy selection directly on the widget
- Power Hour controls
- Timers or countdowns
- Lock-screen widgets
- iOS WidgetKit implementation
- Cloud synchronization
