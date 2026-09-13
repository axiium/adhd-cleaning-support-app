import '../../../core/persistence/cleaning_repository.dart';

abstract interface class SyncService {
  Future<void> connect();
  Future<void> disconnect();
  Future<void> upload(CleaningSnapshot snapshot);
  Future<CleaningSnapshot?> download();
}

/// Placeholder boundary for a future encrypted provider.
///
/// Keeping this interface separate means the app does not need to know
/// whether synchronization is eventually provided by a hosted service or a
/// user-controlled encrypted store.
class LocalOnlySyncService implements SyncService {
  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> upload(CleaningSnapshot snapshot) async {}

  @override
  Future<CleaningSnapshot?> download() async => null;
}
