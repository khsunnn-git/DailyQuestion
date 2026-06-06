// ignore_for_file: depend_on_referenced_packages

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:dailyquestion/design_system/design_system.dart";
import "package:dailyquestion/features/more/notification_settings_screen.dart";
import "package:dailyquestion/features/more/notification_prefs_keys.dart";

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
List<int> _scheduledNotificationIds = <int>[];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    _notificationsEnabled = false;
    _requestNotificationsPermissionResult = false;
    _canScheduleExactNotifications = true;
    _requestExactAlarmsPermissionResult = true;
    _requestExactAlarmsPermissionCallCount = 0;
    _scheduledNotificationIds = <int>[];
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
              final Object? rawArguments = methodCall.arguments;
              if (rawArguments is Map) {
                final Object? id = rawArguments["id"];
                if (id is int) {
                  _scheduledNotificationIds.add(id);
                }
              }
              return null;
            case "areNotificationsEnabled":
              return _notificationsEnabled;
            case "requestNotificationsPermission":
              return _requestNotificationsPermissionResult;
            case "canScheduleExactNotifications":
              return _canScheduleExactNotifications;
            case "requestExactAlarmsPermission":
              _requestExactAlarmsPermissionCallCount++;
              return _requestExactAlarmsPermissionResult;
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

  testWidgets(
    "today question card shows warning when notification permission is off",
    (WidgetTester tester) async {
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

      expect(find.text("기기 알림 권한이 꺼져 있어 실제 알림은 오지 않아요."), findsOneWidget);
    },
  );

  testWidgets("today question time keeps the saved minute value", (
    WidgetTester tester,
  ) async {
    _notificationsEnabled = true;
    SharedPreferences.setMockInitialValues(<String, Object>{
      NotificationPrefsKeys.settingsSchemaVersion:
          NotificationPrefsKeys.currentSettingsSchemaVersion,
      NotificationPrefsKeys.todayQuestionEnabled: true,
      NotificationPrefsKeys.todayQuestionHour: 21,
      NotificationPrefsKeys.todayQuestionMinute: 15,
    });

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

    expect(find.text("오후 9시 15분"), findsOneWidget);

    await tester.tap(find.text("오후 9시 15분"));
    await tester.pumpAndSettle();

    expect(find.text("오후"), findsOneWidget);
    expect(find.text("09"), findsOneWidget);
    expect(find.text("15"), findsOneWidget);

    await tester.tap(find.text("설정"));
    await tester.pumpAndSettle();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(NotificationPrefsKeys.todayQuestionHour), 21);
    expect(prefs.getInt(NotificationPrefsKeys.todayQuestionMinute), 15);
  });

  testWidgets(
    "today question card shows exact alarm warning on Android when permission is missing",
    (WidgetTester tester) async {
      _notificationsEnabled = true;
      _canScheduleExactNotifications = false;

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

      expect(
        find.text("정확한 알람 권한이 꺼져 있어 안드로이드에서는 알림이 조금 늦어질 수 있어요."),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    "daily question schedule still exists when exact alarm permission is missing",
    (WidgetTester tester) async {
      _notificationsEnabled = true;
      _canScheduleExactNotifications = false;

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

      expect(_scheduledNotificationIds, contains(10001));
      expect(_scheduledNotificationIds, contains(10003));
    },
  );

  testWidgets(
    "exact alarm banner opens allow dialog before requesting permission",
    (WidgetTester tester) async {
      _notificationsEnabled = true;
      _canScheduleExactNotifications = false;

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

      await tester.tap(find.text("⏰ 정시 알림 권한이 꺼져 있어요"));
      await tester.pumpAndSettle();

      expect(find.text("시스템 알람 허용"), findsOneWidget);
      expect(find.text("허용"), findsOneWidget);

      await tester.tap(find.text("허용"));
      await tester.pumpAndSettle();

      expect(_requestExactAlarmsPermissionCallCount, 1);
    },
  );
}
