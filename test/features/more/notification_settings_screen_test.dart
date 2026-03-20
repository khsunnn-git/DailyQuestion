// ignore_for_file: depend_on_referenced_packages

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:dailyquestion/design_system/design_system.dart";
import "package:dailyquestion/features/more/notification_settings_screen.dart";

const MethodChannel _notificationsChannel = MethodChannel(
  "dexterous.com/flutter/local_notifications",
);
const MethodChannel _permissionsChannel = MethodChannel(
  "flutter.baseflow.com/permissions/methods",
);
const MethodChannel _timezoneChannel = MethodChannel("flutter_timezone");

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, (
          MethodCall methodCall,
        ) async {
          switch (methodCall.method) {
            case "initialize":
              return true;
            case "cancel":
              return null;
            case "zonedSchedule":
              return null;
            case "areNotificationsEnabled":
              return false;
            case "requestNotificationsPermission":
              return false;
            case "canScheduleExactNotifications":
              return true;
            case "requestExactAlarmsPermission":
              return true;
            case "checkPermissions":
              return <String, Object>{
                "isEnabled": false,
                "isAlertEnabled": false,
                "isBadgeEnabled": false,
                "isSoundEnabled": false,
                "isProvisionalEnabled": false,
                "isCriticalEnabled": false,
              };
            case "requestPermissions":
              return false;
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

  testWidgets("bucket dday toggle stays on even when permission is denied", (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 3200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.of(AppBrandTheme.blue),
        home: const NotificationSettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppIconToggle).at(1));
    await tester.pumpAndSettle();

    expect(find.text("3일 전"), findsOneWidget);
    await tester.tap(find.text("3일 전"));
    await tester.pumpAndSettle();

    expect(find.text("푸시 알림 설정"), findsOneWidget);
    await tester.tap(find.text("취소"));
    await tester.pumpAndSettle();

    final AppIconToggle toggle = tester.widget<AppIconToggle>(
      find.byType(AppIconToggle).at(1),
    );
    expect(toggle.value, isTrue);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool("notification_bucket_dday_enabled"), isTrue);
  });
}
