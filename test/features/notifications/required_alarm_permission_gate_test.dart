// ignore_for_file: depend_on_referenced_packages

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart";
import "package:flutter_test/flutter_test.dart";

import "package:dailyquestion/design_system/design_system.dart";
import "package:dailyquestion/features/notifications/required_alarm_permission_gate.dart";

const MethodChannel _notificationsChannel = MethodChannel(
  "dexterous.com/flutter/local_notifications",
);
const MethodChannel _permissionsChannel = MethodChannel(
  "flutter.baseflow.com/permissions/methods",
);
const MethodChannel _timezoneChannel = MethodChannel("flutter_timezone");

bool _notificationsEnabled = false;
bool _requestNotificationsPermissionResult = false;
bool _canScheduleExactNotifications = true;
bool _requestExactAlarmsPermissionResult = true;
int _requestExactAlarmsPermissionCallCount = 0;
int _openAppSettingsCallCount = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    _notificationsEnabled = false;
    _requestNotificationsPermissionResult = false;
    _canScheduleExactNotifications = true;
    _requestExactAlarmsPermissionResult = true;
    _requestExactAlarmsPermissionCallCount = 0;
    _openAppSettingsCallCount = 0;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, (
          MethodCall methodCall,
        ) async {
          switch (methodCall.method) {
            case "initialize":
              return true;
            case "areNotificationsEnabled":
              return _notificationsEnabled;
            case "requestNotificationsPermission":
              _notificationsEnabled = _requestNotificationsPermissionResult;
              return _requestNotificationsPermissionResult;
            case "canScheduleExactNotifications":
              return _canScheduleExactNotifications;
            case "requestExactAlarmsPermission":
              _requestExactAlarmsPermissionCallCount++;
              _canScheduleExactNotifications =
                  _requestExactAlarmsPermissionResult;
              return _requestExactAlarmsPermissionResult;
          }
          return null;
        });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissionsChannel, (
          MethodCall methodCall,
        ) async {
          switch (methodCall.method) {
            case "checkPermissionStatus":
              return 0;
            case "requestPermissions":
              return <int, int>{17: 0};
            case "openAppSettings":
              _openAppSettingsCallCount++;
              return true;
          }
          return null;
        });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_timezoneChannel, (
          MethodCall methodCall,
        ) async {
          return "Asia/Seoul";
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissionsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_timezoneChannel, null);
  });

  Widget buildGate() {
    return MaterialApp(
      theme: AppTheme.of(AppBrandTheme.blue),
      home: const RequiredAlarmPermissionGate(
        child: Scaffold(body: SizedBox.expand()),
      ),
    );
  }

  testWidgets("shows a blocking gate when notification permission is missing", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();

    expect(find.text("알림 권한이 필요해요"), findsOneWidget);
    expect(find.text("권한 설정하기"), findsOneWidget);
  });

  testWidgets("gate closes after required permissions are granted", (
    WidgetTester tester,
  ) async {
    _requestNotificationsPermissionResult = true;
    _canScheduleExactNotifications = false;
    _requestExactAlarmsPermissionResult = true;

    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();

    await tester.tap(find.text("권한 설정하기"));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text("알림 권한이 필요해요"), findsNothing);
    expect(_requestExactAlarmsPermissionCallCount, 1);
  });

  testWidgets("opens app settings when permission stays denied", (
    WidgetTester tester,
  ) async {
    _requestNotificationsPermissionResult = false;

    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();

    await tester.tap(find.text("권한 설정하기"));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(_openAppSettingsCallCount, 1);
    expect(find.text("알림 권한이 필요해요"), findsOneWidget);
  });

  testWidgets("does not block when only exact alarm permission is missing", (
    WidgetTester tester,
  ) async {
    _notificationsEnabled = true;
    _canScheduleExactNotifications = false;

    await tester.pumpWidget(buildGate());
    await tester.pumpAndSettle();

    expect(find.text("알림 권한이 필요해요"), findsNothing);
  });
}
