import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:permission_handler/permission_handler.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../design_system/design_system.dart";
import "../notifications/daily_question_notification_scheduler.dart";
import "notification_prefs_keys.dart";

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, this.onBackToSettings});

  final VoidCallback? onBackToSettings;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  bool _todayQuestionEnabled = false;
  bool _bucketDdayEnabled = false;
  int _bucketDdayDaysBefore = NotificationPrefsKeys.defaultBucketDdayDaysBefore;
  bool _hasNotificationPermission = false;
  bool _showDeviceNotificationBanner = true;
  TimeOfDay _todayQuestionTime = const TimeOfDay(
    hour: NotificationPrefsKeys.defaultTodayQuestionHour,
    minute: NotificationPrefsKeys.defaultTodayQuestionMinute,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshNotificationPermissionBanner();
    _loadNotificationSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNotificationPermissionBanner();
    }
  }

  Future<void> _refreshNotificationPermissionBanner() async {
    if (kIsWeb) {
      if (!mounted) {
        return;
      }
      setState(() {
        _showDeviceNotificationBanner = false;
      });
      return;
    }

    PermissionStatus status;
    try {
      status = await Permission.notification.status;
    } catch (_) {
      status = PermissionStatus.denied;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _hasNotificationPermission =
          status == PermissionStatus.granted ||
          status == PermissionStatus.provisional;
      _showDeviceNotificationBanner = !_hasNotificationPermission;
    });
    await _syncNotificationSchedules();
  }

  Future<void> _openNotificationPermissionSettings() async {
    if (kIsWeb) {
      return;
    }
    try {
      final PermissionStatus status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    } catch (_) {}
    await openAppSettings();
    await _refreshNotificationPermissionBanner();
  }

  Future<void> _loadNotificationSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool todayEnabled =
        prefs.getBool(NotificationPrefsKeys.todayQuestionEnabled) ?? false;
    final bool bucketEnabled =
        prefs.getBool(NotificationPrefsKeys.bucketDdayEnabled) ?? false;
    final int hour =
        prefs.getInt(NotificationPrefsKeys.todayQuestionHour) ??
        NotificationPrefsKeys.defaultTodayQuestionHour;
    final int minute =
        prefs.getInt(NotificationPrefsKeys.todayQuestionMinute) ??
        NotificationPrefsKeys.defaultTodayQuestionMinute;
    final int bucketDdayDaysBefore =
        prefs.getInt(NotificationPrefsKeys.bucketDdayDaysBefore) ??
        NotificationPrefsKeys.defaultBucketDdayDaysBefore;

    if (!mounted) {
      return;
    }

    setState(() {
      _todayQuestionEnabled = todayEnabled;
      _bucketDdayEnabled = bucketEnabled;
      _todayQuestionTime = TimeOfDay(hour: hour, minute: minute);
      _bucketDdayDaysBefore = bucketDdayDaysBefore;
    });
    await _syncNotificationSchedules();
  }

  Future<void> _saveTodayQuestionEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationPrefsKeys.todayQuestionEnabled, value);
  }

  Future<void> _saveBucketDdayEnabled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationPrefsKeys.bucketDdayEnabled, value);
  }

  Future<void> _saveBucketDdayDaysBefore(int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(NotificationPrefsKeys.bucketDdayDaysBefore, value);
  }

  Future<void> _saveTodayQuestionTime(TimeOfDay time) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(NotificationPrefsKeys.todayQuestionHour, time.hour);
    await prefs.setInt(NotificationPrefsKeys.todayQuestionMinute, time.minute);
  }

  Future<void> _syncNotificationSchedules() async {
    await updateDailyQuestionNotificationSchedule(
      enabled: _hasNotificationPermission && _todayQuestionEnabled,
      hour: _todayQuestionTime.hour,
      minute: _todayQuestionTime.minute,
    );
    await syncBucketDdayNotificationSchedule(
      enabled: _hasNotificationPermission && _bucketDdayEnabled,
      daysBefore: _bucketDdayDaysBefore,
    );
  }

  Future<void> _onDeviceNotificationBannerTap() async {
    final BrandScale brand = context.appBrandScale;
    final bool? shouldOpenSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext dialogContext) {
        return Center(
          child: AppPopup(
            width: AppPopupTokens.maxWidth,
            title: "푸시 알림 설정",
            body: "‘알림’을 활성화하면\n푸시 알림을 받을 수 있어요.",
            actions: <Widget>[
              SizedBox(
                width: 100,
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppNeutralColors.grey100,
                    foregroundColor: AppNeutralColors.grey600,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    overlayColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.s8),
                    ),
                    textStyle: AppTypography.buttonLarge,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    "취소",
                    style: AppTypography.buttonLarge.copyWith(
                      color: AppNeutralColors.grey600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 170,
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: brand.c500,
                    foregroundColor: AppNeutralColors.white,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    overlayColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.s8),
                    ),
                    textStyle: AppTypography.buttonLarge,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    "설정하기",
                    style: AppTypography.buttonLarge.copyWith(
                      color: AppNeutralColors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || shouldOpenSettings != true) {
      return;
    }
    await _openNotificationPermissionSettings();
  }

  String _formatKoreanTime(TimeOfDay time) {
    final bool isAm = time.hour < 12;
    final int hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String minute = time.minute.toString().padLeft(2, "0");
    return "${isAm ? "오전" : "오후"} $hour12:$minute";
  }

  Future<void> _selectTodayQuestionTime() async {
    final DateTime now = DateTime.now();
    DateTime selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _todayQuestionTime.hour,
      _todayQuestionTime.minute,
    );

    final TimeOfDay? picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext sheetContext) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppNeutralColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: AppPopupTokens.bottomSheetShadow,
          ),
          child: SizedBox(
            height: 320,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s20,
                    AppSpacing.s16,
                    AppSpacing.s20,
                    AppSpacing.s12,
                  ),
                  child: Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(
                          "취소",
                          style: AppTypography.bodyMediumSemiBold.copyWith(
                            color: AppNeutralColors.grey500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "오늘의 질문 알림 시간",
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMediumSemiBold.copyWith(
                            color: AppNeutralColors.grey900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(
                          TimeOfDay(
                            hour: selectedDateTime.hour,
                            minute: selectedDateTime.minute,
                          ),
                        ),
                        child: Text(
                          "확인",
                          style: AppTypography.bodyMediumSemiBold.copyWith(
                            color: context.appBrandScale.c500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppNeutralColors.grey100,
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: false,
                    initialDateTime: selectedDateTime,
                    onDateTimeChanged: (DateTime value) {
                      selectedDateTime = value;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _todayQuestionTime = picked;
    });
    await _saveTodayQuestionTime(picked);
    await _syncNotificationSchedules();
  }

  Future<void> _openBucketDdaySettingBottomSheet() async {
    const List<int> options = <int>[1, 3, 7, 14, 30];
    int selectedValue = options.contains(_bucketDdayDaysBefore)
        ? _bucketDdayDaysBefore
        : NotificationPrefsKeys.defaultBucketDdayDaysBefore;

    final int? selected = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext sheetContext) {
        final double bottomInset = MediaQuery.viewPaddingOf(
          sheetContext,
        ).bottom;
        final double bottomPadding = bottomInset + AppSpacing.s20;
        final double safeBottomPadding = bottomPadding < AppSpacing.s48
            ? AppSpacing.s48
            : bottomPadding;

        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppNeutralColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: AppPopupTokens.bottomSheetShadow,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s20,
              AppSpacing.s16,
              AppSpacing.s20,
              safeBottomPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppNeutralColors.grey300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                ...options.map((int value) {
                  return AppBottomSheetListItem(
                    label: "$value일 전",
                    selected: value == selectedValue,
                    onTap: () => Navigator.of(sheetContext).pop(value),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }
    setState(() {
      _bucketDdayDaysBefore = selected;
    });
    await _saveBucketDdayDaysBefore(selected);
    await _syncNotificationSchedules();
  }

  Future<void> _handleBucketDdayToggle(bool enabled) async {
    setState(() {
      _bucketDdayEnabled = enabled;
      if (enabled && _bucketDdayDaysBefore <= 0) {
        _bucketDdayDaysBefore =
            NotificationPrefsKeys.defaultBucketDdayDaysBefore;
      }
    });
    await _saveBucketDdayEnabled(enabled);

    if (enabled) {
      await _saveBucketDdayDaysBefore(_bucketDdayDaysBefore);
      await _openBucketDdaySettingBottomSheet();
      return;
    }

    await _syncNotificationSchedules();
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s20,
            AppSpacing.s20,
            AppSpacing.s20,
            AppSpacing.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(
                    width: AppSpacing.s24,
                    height: AppSpacing.s24,
                    child: IconButton(
                      onPressed: () {
                        if (widget.onBackToSettings != null) {
                          widget.onBackToSettings!();
                          return;
                        }
                        Navigator.of(context).maybePop();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: AppSpacing.s24,
                        height: AppSpacing.s24,
                      ),
                      icon: const Icon(
                        Icons.arrow_back,
                        size: AppSpacing.s24,
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "알림 설정",
                      textAlign: TextAlign.center,
                      style: AppTypography.headingXSmall.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s24, height: AppSpacing.s24),
                ],
              ),
              const SizedBox(height: AppSpacing.s32),
              if (_showDeviceNotificationBanner) ...<Widget>[
                GestureDetector(
                  onTap: _onDeviceNotificationBannerTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s20,
                      vertical: AppSpacing.s12,
                    ),
                    decoration: BoxDecoration(
                      color: AppSemanticColors.info100,
                      borderRadius: BorderRadius.circular(AppSpacing.s16),
                      boxShadow: AppElevation.level1,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "🔔 기기 알림이 꺼져 있어요!",
                                style: AppTypography.heading2XSmall.copyWith(
                                  color: AppNeutralColors.grey900,
                                ),
                              ),
                              Text(
                                "설정에서 알림을 켜고 소식을 받아보세요.",
                                style: AppTypography.captionSmall.copyWith(
                                  color: AppNeutralColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppNeutralColors.grey700,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
              ],
              _TodayQuestionNotificationCard(
                title: "오늘의 질문",
                description: "정해진 시간에 오늘의 질문을 보내드려요",
                enabled: _todayQuestionEnabled,
                showTimeRow:
                    _hasNotificationPermission && _todayQuestionEnabled,
                timeLabel: _formatKoreanTime(_todayQuestionTime),
                onTimeTap: _selectTodayQuestionTime,
                onChanged: (bool value) {
                  setState(() {
                    _todayQuestionEnabled = value;
                  });
                  _saveTodayQuestionEnabled(value);
                  _syncNotificationSchedules();
                },
              ),
              const SizedBox(height: AppSpacing.s16),
              _BucketDdayNotificationCard(
                title: "버킷리스트 디데이",
                description: "다가오는 디데이를 미리 알려드려요",
                enabled: _bucketDdayEnabled,
                showDdayRow: _bucketDdayEnabled,
                ddayLabel: "$_bucketDdayDaysBefore일 전",
                onDdayTap: _openBucketDdaySettingBottomSheet,
                onChanged: _handleBucketDdayToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BucketDdayNotificationCard extends StatelessWidget {
  const _BucketDdayNotificationCard({
    required this.title,
    required this.description,
    required this.enabled,
    required this.showDdayRow,
    required this.ddayLabel,
    required this.onDdayTap,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool enabled;
  final bool showDdayRow;
  final String ddayLabel;
  final VoidCallback onDdayTap;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.s12),
        boxShadow: AppElevation.level1,
      ),
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTypography.bodyMediumSemiBold.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      description,
                      style: AppTypography.bodySmallMedium.copyWith(
                        color: AppNeutralColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              AppIconToggle(value: enabled, onChanged: onChanged),
            ],
          ),
          if (showDdayRow) ...<Widget>[
            const SizedBox(height: AppSpacing.s24),
            GestureDetector(
              onTap: onDdayTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      "디데이 설정",
                      style: AppTypography.bodyMediumSemiBold.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        ddayLabel,
                        style: AppTypography.bodySmallSemiBold.copyWith(
                          color: AppNeutralColors.grey600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      const Icon(
                        Icons.chevron_right,
                        size: AppSpacing.s24,
                        color: AppNeutralColors.grey900,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayQuestionNotificationCard extends StatelessWidget {
  const _TodayQuestionNotificationCard({
    required this.title,
    required this.description,
    required this.enabled,
    required this.showTimeRow,
    required this.timeLabel,
    required this.onTimeTap,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool enabled;
  final bool showTimeRow;
  final String timeLabel;
  final VoidCallback onTimeTap;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.s12),
        boxShadow: AppElevation.level1,
      ),
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTypography.bodyMediumSemiBold.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      description,
                      style: AppTypography.bodySmallMedium.copyWith(
                        color: AppNeutralColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              AppIconToggle(value: enabled, onChanged: onChanged),
            ],
          ),
          if (showTimeRow) ...<Widget>[
            const SizedBox(height: AppSpacing.s24),
            GestureDetector(
              onTap: onTimeTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      "오늘의 질문 알림 시간",
                      style: AppTypography.bodyMediumSemiBold.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        timeLabel,
                        style: AppTypography.bodySmallSemiBold.copyWith(
                          color: AppNeutralColors.grey600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      const Icon(
                        Icons.chevron_right,
                        size: AppSpacing.s24,
                        color: AppNeutralColors.grey900,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
