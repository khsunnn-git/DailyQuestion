import "package:flutter/widgets.dart";

import "user_answer_backup_service_io.dart"
    if (dart.library.js_interop) "user_answer_backup_service_web.dart"
    as service;

Future<void> startUserAnswerBackupService() =>
    service.startUserAnswerBackupService();

Future<void> syncPendingUserAnswers({bool restoreRemoteOnConnect = false}) {
  return service.syncPendingUserAnswers(
    restoreRemoteOnConnect: restoreRemoteOnConnect,
  );
}

Future<void> handleUserAnswerBackupAppLifecycleState(AppLifecycleState state) {
  return service.handleUserAnswerBackupAppLifecycleState(state);
}
