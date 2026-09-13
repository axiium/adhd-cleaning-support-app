# Synchronization contract

Synchronization is intentionally not active yet. The current app remains
local-only, with file backup and restore available under Settings.

When a provider is selected, it must meet these requirements before the
connection UI is enabled:

- Explicit opt-in and an easy disconnect path.
- End-to-end encryption for snapshot contents in transit and at rest.
- No upload until the user connects a device.
- A clear last-synced time and an understandable error state.
- Conflict handling that preserves data rather than silently overwriting it.
- Delete-account and delete-cloud-data controls.
- Android and iOS support without changing the local backup format.

The sync boundary is represented by `SyncService`. A provider should exchange
the same `CleaningSnapshot` used by local persistence, so goals, small steps,
completion history, skips, reminders, and accessibility preferences remain
portable across devices.
