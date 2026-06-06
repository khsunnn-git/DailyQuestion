import "package:flutter/widgets.dart";

import "daily_checkin_backup_service_io.dart"
    if (dart.library.js_interop) "daily_checkin_backup_service_web.dart"
    as service;

Future<void> startDailyCheckinBackupService() {
  return service.startDailyCheckinBackupService();
}

Future<void> syncDailyCheckinBackup({bool restoreRemoteOnConnect = false}) {
  return service.syncDailyCheckinBackup(
    restoreRemoteOnConnect: restoreRemoteOnConnect,
  );
}

Future<void> deleteRemoteDailyCheckinBackup({String? uid}) {
  return service.deleteRemoteDailyCheckinBackup(uid: uid);
}

Future<void> handleDailyCheckinBackupAppLifecycleState(
  AppLifecycleState state,
) {
  return service.handleDailyCheckinBackupAppLifecycleState(state);
}
