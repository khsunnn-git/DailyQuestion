import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:permission_handler/permission_handler.dart";

import "../../design_system/design_system.dart";
import "../more/notification_prefs_keys.dart";
import "daily_question_notification_scheduler.dart";

class RequiredAlarmPermissionGate extends StatefulWidget {
  const RequiredAlarmPermissionGate({super.key, required this.child});

  final Widget child;

  @override
  State<RequiredAlarmPermissionGate> createState() =>
      _RequiredAlarmPermissionGateState();
}

class _RequiredAlarmPermissionGateState
    extends State<RequiredAlarmPermissionGate>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _hasRequiredPermissions = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshPermissionState());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPermissionState());
    }
  }

  Future<void> _refreshPermissionState() async {
    final bool granted =
        await areDailyQuestionAlarmPermissionsGrantedOnDevice();
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      _hasRequiredPermissions = granted;
      if (granted) {
        _errorMessage = null;
      }
    });

    if (granted) {
      await refreshDailyQuestionNotificationSchedulerState();
    }
  }

  Future<void> _handleGrantPermissions() async {
    if (_submitting) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    bool granted = false;
    try {
      granted = await requestDailyQuestionAlarmPermissionsOnDevice();
      if (!granted) {
        await openAppSettings();
      }
    } catch (_) {
      granted = false;
    }

    await _refreshPermissionState();
    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
      if (!_hasRequiredPermissions && !granted) {
        _errorMessage = defaultTargetPlatform == TargetPlatform.android
            ? "알림과 정시 알람 권한을 모두 허용해야 계속할 수 있어요."
            : "알림 권한을 허용해야 계속할 수 있어요.";
      }
    });
  }

  String _defaultAlarmTimeLabel() {
    final TimeOfDay time = const TimeOfDay(
      hour: NotificationPrefsKeys.defaultTodayQuestionHour,
      minute: NotificationPrefsKeys.defaultTodayQuestionMinute,
    );
    final bool isAm = time.hour < 12;
    final int hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String minute = time.minute.toString().padLeft(2, "0");
    return "${isAm ? "오전" : "오후"} $hour12:$minute";
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || (!_loading && _hasRequiredPermissions)) {
      return widget.child;
    }

    final BrandScale brand = context.appBrandScale;
    final String permissionDescription =
        "알림을 받으려면 기기 알림 권한이 필요해요.\n권한을 허용하면 매일 설정한 시간, 설정 전이라면 기본 시간 ${_defaultAlarmTimeLabel()}에 알림을 보내드려요.";

    return Stack(
      children: <Widget>[
        widget.child,
        Positioned.fill(
          child: ColoredBox(
            color: AppNeutralColors.white,
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppPopupTokens.maxWidth,
                    ),
                    child: Container(
                      width: AppPopupTokens.maxWidth,
                      padding: AppPopupTokens.contentPadding,
                      decoration: BoxDecoration(
                        color: AppPopupTokens.background,
                        borderRadius: AppPopupTokens.radius,
                        boxShadow: AppPopupTokens.shadow,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            "알림 권한이 필요해요",
                            style: AppPopupTokens.titleStyle.copyWith(
                              color: AppPopupTokens.titleColor,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: AppPopupTokens.textGap),
                          Text(
                            permissionDescription,
                            style: AppPopupTokens.bodyStyle.copyWith(
                              color: AppPopupTokens.bodyColor,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: AppPopupTokens.contentGap),
                          SizedBox(
                            height: 56,
                            child: FilledButton(
                              onPressed: _submitting
                                  ? null
                                  : _handleGrantPermissions,
                              style: FilledButton.styleFrom(
                                backgroundColor: brand.c500,
                                foregroundColor: AppNeutralColors.white,
                                surfaceTintColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.s8,
                                  ),
                                ),
                                textStyle: AppTypography.buttonLarge,
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppNeutralColors.white,
                                      ),
                                    )
                                  : const Text("권한 설정하기"),
                            ),
                          ),
                          if (_errorMessage != null) ...<Widget>[
                            const SizedBox(height: AppSpacing.s12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmallRegular.copyWith(
                                color: AppSemanticColors.error500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
