import "package:flutter/widgets.dart";

Future<void> startUserAnswerBackupService() async {}

Future<void> syncPendingUserAnswers({
  bool restoreRemoteOnConnect = false,
}) async {}

Future<void> deleteRemoteUserAnswerBackup({String? uid}) async {}

Future<void> handleUserAnswerBackupAppLifecycleState(
  AppLifecycleState state,
) async {}
