import "package:flutter/widgets.dart";

import "bucket_backup_service_io.dart"
    if (dart.library.js_interop) "bucket_backup_service_web.dart"
    as service;

Future<void> startBucketBackupService() => service.startBucketBackupService();

Future<void> syncBucketBackup({bool restoreRemoteOnConnect = false}) {
  return service.syncBucketBackup(
    restoreRemoteOnConnect: restoreRemoteOnConnect,
  );
}

Future<void> deleteRemoteBucketBackup({String? uid}) {
  return service.deleteRemoteBucketBackup(uid: uid);
}

Future<void> handleBucketBackupAppLifecycleState(AppLifecycleState state) {
  return service.handleBucketBackupAppLifecycleState(state);
}
