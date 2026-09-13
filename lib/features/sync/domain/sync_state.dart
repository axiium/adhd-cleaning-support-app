enum SyncState {
  localOnly,
  connecting,
  synced,
  needsAttention,
}

extension SyncStateLabel on SyncState {
  String get label => switch (this) {
        SyncState.localOnly => 'Local only',
        SyncState.connecting => 'Connecting',
        SyncState.synced => 'Synced',
        SyncState.needsAttention => 'Needs attention',
      };
}
