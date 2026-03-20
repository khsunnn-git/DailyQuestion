import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
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
  bool _todayQuestionEnabled =
      NotificationPrefsKeys.defaultTodayQuestionEnabled;
  bool _bucketDdayEnabled = false;
  int _bucketDdayDaysBefore = NotificationPrefsKeys.defaultBucketDdayDaysBefore;
  bool _hasNotificationPermission = false;
  bool _hasExactAlarmPermission = true;
  bool _showDeviceNotificationBanner = true;
  bool _showExactAlarmBanner = false;
  bool _openingSystemSettings = false;
  TimeOfDay _todayQuestionTime = const TimeOfDay(
    hour: NotificationPrefsKeys.defaultTodayQuestionHour,
    minute: NotificationPrefsKeys.defaultTodayQuestionMinute,
  );

  void _logNotificationSettings(String message) {
    if (kDebugMode) {
      debugPrint("[notification_settings] $message");
    }
  }

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
        _hasNotificationPermission = false;
        _hasExactAlarmPermission = true;
        _showDeviceNotificationBanner = false;
        _showExactAlarmBanner = false;
      });
      return;
    }

    final bool hasNotificationPermission =
        await areNotificationsEnabledOnDevice();
    final bool hasExactAlarmPermission =
        hasNotificationPermission &&
            defaultTargetPlatform == TargetPlatform.android
        ? await canScheduleExactAlarmsOnDevice()
        : true;

    if (!mounted) {
      return;
    }

    setState(() {
      _hasNotificationPermission = hasNotificationPermission;
      _hasExactAlarmPermission = hasExactAlarmPermission;
      _showDeviceNotificationBanner = !_hasNotificationPermission;
      _showExactAlarmBanner =
          _hasNotificationPermission &&
          defaultTargetPlatform == TargetPlatform.android &&
          !_hasExactAlarmPermission;
    });
    _logNotificationSettings(
      "notificationGranted=$_hasNotificationPermission exactAlarmGranted=$_hasExactAlarmPermission notificationBanner=$_showDeviceNotificationBanner exactAlarmBanner=$_showExactAlarmBanner",
    );
    await _syncNotificationSchedules();
  }

  Future<void> _openNotificationPermissionSettings() async {
    if (kIsWeb) {
      return;
    }
    if (_openingSystemSettings) {
      return;
    }
    if (mounted) {
      setState(() {
        _openingSystemSettings = true;
      });
    } else {
      _openingSystemSettings = true;
    }
    try {
      await openAppSettings();
    } catch (_) {
      await openAppSettings();
    } finally {
      if (mounted) {
        setState(() {
          _openingSystemSettings = false;
        });
      } else {
        _openingSystemSettings = false;
      }
    }
    await _refreshNotificationPermissionBanner();
  }

  Future<bool?> _showNotificationPermissionDialog() {
    final BrandScale brand = context.appBrandScale;
    return showDialog<bool>(
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
  }

  Future<bool> _ensureNotificationPermission() async {
    if (kIsWeb) {
      return false;
    }

    final bool hasPermission = await areNotificationsEnabledOnDevice();
    if (hasPermission) {
      await _refreshNotificationPermissionBanner();
      return true;
    }

    final bool granted = await requestNotificationPermissionOnDevice();
    if (granted) {
      await _refreshNotificationPermissionBanner();
      return true;
    }

    if (!mounted) {
      return false;
    }

    final bool? shouldOpenSettings = await _showNotificationPermissionDialog();
    if (!mounted || shouldOpenSettings != true) {
      await _refreshNotificationPermissionBanner();
      return false;
    }

    await _openNotificationPermissionSettings();
    return _hasNotificationPermission;
  }

  Future<void> _ensureExactAlarmPermissionIfNeeded() async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        !_hasNotificationPermission) {
      return;
    }
    final bool canScheduleExact = await canScheduleExactAlarmsOnDevice();
    if (canScheduleExact) {
      if (!mounted) {
        _hasExactAlarmPermission = true;
        _showExactAlarmBanner = false;
        return;
      }
      setState(() {
        _hasExactAlarmPermission = true;
        _showExactAlarmBanner = false;
      });
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _hasExactAlarmPermission = false;
      _showExactAlarmBanner = true;
    });
  }

  Future<void> _openExactAlarmSettings() async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        _openingSystemSettings) {
      return;
    }
    setState(() {
      _openingSystemSettings = true;
    });
    try {
      final bool opened = await requestExactAlarmPermissionOnDevice();
      _logNotificationSettings("request exact alarm permission result=$opened");
    } on PlatformException catch (error) {
      _logNotificationSettings("request exact alarm permission failed: $error");
      await openAppSettings();
    } catch (_) {
      await openAppSettings();
    } finally {
      if (mounted) {
        setState(() {
          _openingSystemSettings = false;
        });
      } else {
        _openingSystemSettings = false;
      }
    }
    await _refreshNotificationPermissionBanner();
  }

  Future<void> _loadNotificationSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool todayEnabled =
        prefs.getBool(NotificationPrefsKeys.todayQuestionEnabled) ??
        NotificationPrefsKeys.defaultTodayQuestionEnabled;
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
    _logNotificationSettings(
      "load prefs todayEnabled=$todayEnabled time=${hour.toString().padLeft(2, "0")}:${minute.toString().padLeft(2, "0")} bucketEnabled=$bucketEnabled bucketDaysBefore=$bucketDdayDaysBefore",
    );

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
    _logNotificationSettings(
      "sync schedules todayEnabled=$_todayQuestionEnabled time=${_todayQuestionTime.hour.toString().padLeft(2, "0")}:${_todayQuestionTime.minute.toString().padLeft(2, "0")} bucketEnabled=$_bucketDdayEnabled bucketDaysBefore=$_bucketDdayDaysBefore hasPermission=$_hasNotificationPermission",
    );
    await updateDailyQuestionNotificationSchedule(
      enabled: _hasNotificationPermission && _todayQuestionEnabled,
      hour: _todayQuestionTime.hour,
      minute: _todayQuestionTime.minute,
    );
    await syncBucketDdayNotificationSchedule(
      enabled: _hasNotificationPermission && _bucketDdayEnabled,
      daysBefore: _bucketDdayDaysBefore,
    );
    await syncWeeklyReportNotificationSchedule(
      enabled: _hasNotificationPermission,
    );
  }

  Future<void> _onDeviceNotificationBannerTap() async {
    final bool? shouldOpenSettings = await _showNotificationPermissionDialog();

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

  Future<void> _handleTodayQuestionToggle(bool enabled) async {
    if (enabled) {
      final bool granted = await _ensureNotificationPermission();
      if (!mounted) {
        return;
      }
      setState(() {
        _todayQuestionEnabled = granted;
      });
      _logNotificationSettings("toggle today question enabled=$granted");
      await _saveTodayQuestionEnabled(granted);
      if (granted) {
        await _ensureExactAlarmPermissionIfNeeded();
      }
      await _syncNotificationSchedules();
      return;
    }

    setState(() {
      _todayQuestionEnabled = false;
    });
    _logNotificationSettings("toggle today question enabled=false");
    await _saveTodayQuestionEnabled(false);
    await _syncNotificationSchedules();
  }

  Future<void> _selectTodayQuestionTime() async {
    bool isAm = _todayQuestionTime.hour < 12;
    int selectedHour12 = _todayQuestionTime.hourOfPeriod == 0
        ? 12
        : _todayQuestionTime.hourOfPeriod;
    int selectedMinute = _todayQuestionTime.minute;

    final TimeOfDay? picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      useSafeArea: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext sheetContext) {
        final BrandScale brand = sheetContext.appBrandScale;
        final double bottomInset = MediaQuery.viewPaddingOf(
          sheetContext,
        ).bottom;
        final double bottomPadding = bottomInset + AppSpacing.s20;
        final double safeBottomPadding = bottomPadding < AppSpacing.s48
            ? AppSpacing.s48
            : bottomPadding;

        Widget buildArrowButton({
          required IconData icon,
          required VoidCallback onTap,
          required double width,
        }) {
          return SizedBox(
            width: width,
            height: 47,
            child: IconButton(
              onPressed: onTap,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s8,
              ),
              splashRadius: 24,
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppNeutralColors.grey500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: Icon(
                icon,
                size: AppSpacing.s24,
                color: AppNeutralColors.grey500,
              ),
            ),
          );
        }

        Widget buildSelectedPill({
          required String text,
          required double width,
        }) {
          return Container(
            width: width,
            height: 47,
            decoration: BoxDecoration(
              color: brand.c100,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: AppTypography.headingMediumExtraBold.copyWith(
                color: AppNeutralColors.grey900,
              ),
            ),
          );
        }

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
                const SizedBox(height: AppSpacing.s28),
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter setModalState) {
                    return Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            buildArrowButton(
                              icon: Icons.keyboard_arrow_up,
                              width: 71,
                              onTap: () {
                                setModalState(() {
                                  isAm = !isAm;
                                });
                              },
                            ),
                            const SizedBox(width: AppSpacing.s32),
                            Row(
                              children: <Widget>[
                                buildArrowButton(
                                  icon: Icons.keyboard_arrow_up,
                                  width: 55,
                                  onTap: () {
                                    setModalState(() {
                                      selectedHour12 = selectedHour12 == 12
                                          ? 1
                                          : selectedHour12 + 1;
                                    });
                                  },
                                ),
                                const SizedBox(width: AppSpacing.s16),
                                const SizedBox(width: 7),
                                const SizedBox(width: AppSpacing.s16),
                                buildArrowButton(
                                  icon: Icons.keyboard_arrow_up,
                                  width: 59,
                                  onTap: () {
                                    setModalState(() {
                                      selectedMinute =
                                          (selectedMinute + 1) % 60;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            buildSelectedPill(
                              text: isAm ? "오전" : "오후",
                              width: 71,
                            ),
                            const SizedBox(width: AppSpacing.s32),
                            Row(
                              children: <Widget>[
                                buildSelectedPill(
                                  text: selectedHour12.toString(),
                                  width: 55,
                                ),
                                const SizedBox(width: AppSpacing.s16),
                                Text(
                                  ":",
                                  style: AppTypography.headingMediumExtraBold
                                      .copyWith(
                                        color: AppNeutralColors.grey900,
                                      ),
                                ),
                                const SizedBox(width: AppSpacing.s16),
                                buildSelectedPill(
                                  text: selectedMinute.toString().padLeft(
                                    2,
                                    "0",
                                  ),
                                  width: 59,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            buildArrowButton(
                              icon: Icons.keyboard_arrow_down,
                              width: 71,
                              onTap: () {
                                setModalState(() {
                                  isAm = !isAm;
                                });
                              },
                            ),
                            const SizedBox(width: AppSpacing.s32),
                            Row(
                              children: <Widget>[
                                buildArrowButton(
                                  icon: Icons.keyboard_arrow_down,
                                  width: 55,
                                  onTap: () {
                                    setModalState(() {
                                      selectedHour12 = selectedHour12 == 1
                                          ? 12
                                          : selectedHour12 - 1;
                                    });
                                  },
                                ),
                                const SizedBox(width: AppSpacing.s16),
                                const SizedBox(width: 7),
                                const SizedBox(width: AppSpacing.s16),
                                buildArrowButton(
                                  icon: Icons.keyboard_arrow_down,
                                  width: 59,
                                  onTap: () {
                                    setModalState(() {
                                      selectedMinute =
                                          (selectedMinute + 59) % 60;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.s28),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppNeutralColors.grey100,
                            foregroundColor: AppNeutralColors.grey600,
                            textStyle: AppTypography.buttonMedium,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s8,
                              ),
                            ),
                            surfaceTintColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Text("취소"),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: () {
                            final int hour24 = isAm
                                ? (selectedHour12 % 12)
                                : (selectedHour12 % 12) + 12;
                            Navigator.of(sheetContext).pop(
                              TimeOfDay(hour: hour24, minute: selectedMinute),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: brand.c500,
                            foregroundColor: AppNeutralColors.white,
                            textStyle: AppTypography.buttonMedium,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s8,
                              ),
                            ),
                            surfaceTintColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Text("설정"),
                        ),
                      ),
                    ),
                  ],
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
    if (enabled) {
      final bool granted = await _ensureNotificationPermission();
      if (!mounted) {
        return;
      }
      if (!granted) {
        setState(() {
          _bucketDdayEnabled = false;
        });
        _logNotificationSettings("toggle bucket dday enabled=false");
        await _saveBucketDdayEnabled(false);
        await _syncNotificationSchedules();
        return;
      }
      await _ensureExactAlarmPermissionIfNeeded();
    }

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
      await _syncNotificationSchedules();
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
                              AppEmojiText(
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
              if (_showExactAlarmBanner) ...<Widget>[
                GestureDetector(
                  onTap: _openExactAlarmSettings,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s20,
                      vertical: AppSpacing.s12,
                    ),
                    decoration: BoxDecoration(
                      color: AppSemanticColors.warning100,
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
                                "⏰ 정시 알림 권한이 꺼져 있어요",
                                style: AppTypography.heading2XSmall.copyWith(
                                  color: AppNeutralColors.grey900,
                                ),
                              ),
                              Text(
                                "실기기에서 제시간에 받으려면 정확한 알람 권한을 켜주세요.",
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
                onChanged: _handleTodayQuestionToggle,
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
