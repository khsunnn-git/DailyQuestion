import "dart:async";

import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";

import "../../design_system/design_system.dart";
import "../auth/auth_service.dart";
import "../auth/login_screen.dart";
import "../home/home_character_assets.dart";
import "../navigation/main_tab_shell.dart";
import "../question/today_question_store.dart";
import "data_management_screen.dart";
import "more_profile_stats_store.dart";
import "feedback_send_screen.dart";
import "notice_list_screen.dart";
import "notification_settings_screen.dart";
import "../profile/nickname_setup_screen.dart";
import "../profile/user_profile_store.dart";

class MoreSettingsScreen extends StatefulWidget {
  const MoreSettingsScreen({super.key, this.showNavigationBar = true});

  final bool showNavigationBar;

  static void open(BuildContext context, {bool replace = false}) {
    final Route<void> route = MaterialPageRoute<void>(
      builder: (_) => const MoreSettingsScreen(),
    );
    if (replace) {
      Navigator.of(context).pushReplacement(route);
      return;
    }
    Navigator.of(context).push(route);
  }

  @override
  State<MoreSettingsScreen> createState() => _MoreSettingsScreenState();
}

class _MoreSettingsScreenState extends State<MoreSettingsScreen> {
  static const String _termsUrl = String.fromEnvironment(
    "TERMS_URL",
    defaultValue:
        "https://khsunnn-git.github.io/DailyQuestion/docs/policy/terms/",
  );
  static const String _privacyUrl = String.fromEnvironment(
    "PRIVACY_URL",
    defaultValue:
        "https://khsunnn-git.github.io/DailyQuestion/docs/policy/privacy/",
  );

  int _profileRefreshSeed = 0;
  StreamSubscription<Object?>? _authSubscription;
  bool _isResolvingAuthState = true;

  @override
  void initState() {
    super.initState();
    _authSubscription = AuthService.instance.authStateChanges.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
    unawaited(_restoreAuthState());
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _restoreAuthState() async {
    await AuthService.instance.waitForRestoredUser();
    if (!mounted) {
      _isResolvingAuthState = false;
      return;
    }
    setState(() {
      _isResolvingAuthState = false;
    });
  }

  Future<void> _openNicknameEdit() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NicknameSetupScreen(isEditMode: true),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _profileRefreshSeed += 1;
    });
  }

  Future<void> _openNotificationSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationSettingsScreen(
          onBackToSettings: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _openNoticeList() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const NoticeListScreen()));
  }

  Future<void> _openFeedbackSend() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const FeedbackSendScreen()));
  }

  Future<void> _openDataManagement() async {
    await DataManagementScreen.open(context);
    if (!mounted) {
      return;
    }
    setState(() {
      _profileRefreshSeed += 1;
    });
  }

  Future<void> _openTerms() async {
    await _openExternalUrl(_termsUrl, "이용약관");
  }

  Future<void> _openPrivacyPolicy() async {
    await _openExternalUrl(_privacyUrl, "개인정보처리방침");
  }

  Future<void> _openAccountConnect() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(
          mode: LoginScreenMode.accountConnect,
          onLoginSuccess: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _disconnectAccount() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext dialogContext) {
        return Center(
          child: AppPopup(
            width: AppPopupTokens.maxWidth,
            title: "계정 연동 해제",
            body: "이 기기에서 현재 연결된 계정을 해제할까요?",
            actions: <Widget>[
              SizedBox(
                width: 100,
                height: 48,
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
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppSemanticColors.error500,
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
                    "계정 연동 해제",
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
    if (confirmed != true) {
      return;
    }
    try {
      await AuthService.instance.disconnectConnectedProvider();
      if (!mounted) {
        return;
      }
      setState(() {});
    } on AuthActionException catch (error) {
      _showUrlError(error.userMessage);
    } catch (_) {
      _showUrlError("계정 연동 해제에 실패했어요. 잠시 후 다시 시도해주세요.");
    }
  }

  List<_SettingsItem> _buildAccountItems() {
    final bool hasConnectedProvider =
        !_isResolvingAuthState && AuthService.instance.hasConnectedProvider;
    final _SettingsItem versionItem = const _SettingsItem(
      title: "앱 버전",
      trailingText: "v.1.0.14 최신 버전",
    );

    if (_isResolvingAuthState) {
      return <_SettingsItem>[
        versionItem,
        const _SettingsItem(title: "계정 연결", trailingText: "연결 상태 확인 중"),
        _SettingsItem(title: "이용약관", onTap: _openTerms),
        _SettingsItem(title: "개인정보처리방침", onTap: _openPrivacyPolicy),
      ];
    }

    if (hasConnectedProvider) {
      return <_SettingsItem>[
        _SettingsItem(
          title: "계정연결",
          trailingText: AuthService.instance.currentProviderConnectionLabel,
        ),
        versionItem,
        _SettingsItem(title: "이용약관", onTap: _openTerms),
        _SettingsItem(title: "개인정보처리방침", onTap: _openPrivacyPolicy),
      ];
    }

    return <_SettingsItem>[
      versionItem,
      _SettingsItem(title: "계정 연결", onTap: _openAccountConnect),
      _SettingsItem(title: "이용약관", onTap: _openTerms),
      _SettingsItem(title: "개인정보처리방침", onTap: _openPrivacyPolicy),
    ];
  }

  Future<void> _openExternalUrl(String rawUrl, String label) async {
    final Uri? uri = Uri.tryParse(rawUrl);
    if (uri == null ||
        !(uri.scheme == "http" || uri.scheme == "https") ||
        uri.host.isEmpty) {
      _showUrlError("$label URL이 올바르지 않아요.");
      return;
    }
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      _showUrlError("$label 페이지를 열지 못했어요.");
    }
  }

  void _showUrlError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final bool hasConnectedProvider = AuthService.instance.hasConnectedProvider;
    return Scaffold(
      backgroundColor: brand.bg,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.s20,
                AppHeaderTokens.topInset + AppSpacing.s20,
                AppSpacing.s20,
                AppNavigationBar.totalHeight(context) + AppSpacing.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const SizedBox(
                        width: AppSpacing.s24,
                        height: AppSpacing.s24,
                      ),
                      Expanded(
                        child: Text(
                          "설정",
                          textAlign: TextAlign.center,
                          style: AppTypography.headingXSmall.copyWith(
                            color: AppNeutralColors.grey900,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: AppSpacing.s24,
                        height: AppSpacing.s24,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s32),
                  _ProfileSection(
                    refreshSeed: _profileRefreshSeed,
                    onEditPressed: _openNicknameEdit,
                  ),
                  const SizedBox(height: AppSpacing.s32),
                  _SettingsSectionCard(
                    title: "서비스 설정",
                    items: <_SettingsItem>[
                      _SettingsItem(
                        title: "알림 설정",
                        onTap: _openNotificationSettings,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _SettingsSectionCard(
                    title: "고객 센터",
                    items: <_SettingsItem>[
                      _SettingsItem(title: "공지사항", onTap: _openNoticeList),
                      _SettingsItem(title: "의견 보내기", onTap: _openFeedbackSend),
                      _SettingsItem(
                        title: "데이터 관리",
                        onTap: _openDataManagement,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _SettingsSectionCard(
                    title: "계정",
                    items: _buildAccountItems(),
                  ),
                  if (hasConnectedProvider) ...<Widget>[
                    const SizedBox(height: AppSpacing.s24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: _disconnectAccount,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.s4),
                          child: Text(
                            "계정 연동 해제",
                            style: AppTypography.buttonSmall.copyWith(
                              color: AppNeutralColors.grey500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (widget.showNavigationBar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppNavigationBar(
                currentIndex: 3,
                onTap: (int index) {
                  if (index == 3) {
                    return;
                  }
                  MainTabShell.replace(context, index: index);
                },
                items: const <AppNavigationBarItemData>[
                  AppNavigationBarItemData(
                    label: "오늘의 질문",
                    icon: Icons.home_outlined,
                  ),
                  AppNavigationBarItemData(
                    label: "버킷리스트",
                    icon: Icons.format_list_bulleted,
                  ),
                  AppNavigationBarItemData(
                    label: "나의기록",
                    icon: Icons.assignment_outlined,
                  ),
                  AppNavigationBarItemData(
                    label: "더보기",
                    icon: Icons.more_horiz,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.refreshSeed,
    required this.onEditPressed,
  });

  final int refreshSeed;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return ValueListenableBuilder<List<TodayQuestionRecord>>(
      valueListenable: TodayQuestionStore.instance,
      builder:
          (BuildContext context, List<TodayQuestionRecord> records, Widget? _) {
            final String profileFishAssetPath =
                HomeCharacterAssets.assetForRecordCount(
                  HomeCharacterType.fish,
                  records.length,
                );
            return FutureBuilder<_ProfileSnapshot>(
              future: _loadProfileSnapshot(refreshSeed),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<_ProfileSnapshot> snapshot,
                  ) {
                    final _ProfileSnapshot profile =
                        snapshot.data ?? const _ProfileSnapshot();
                    final String nickname =
                        (profile.nickname?.trim().isNotEmpty ?? false)
                        ? profile.nickname!.trim()
                        : "{닉네임}";
                    final String questionDaysText =
                        (profile.questionStreakDays ?? 0).toString();
                    final String bucketCountText = profile.bucketCount == null
                        ? "NNN"
                        : _formatBucketCount(profile.bucketCount!);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        ClipOval(
                          child: Image.asset(
                            profileFishAssetPath,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      nickname,
                                      style: AppTypography.headingSmall
                                          .copyWith(
                                            color: AppNeutralColors.grey900,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s8),
                                  GestureDetector(
                                    onTap: onEditPressed,
                                    behavior: HitTestBehavior.opaque,
                                    child: const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                        color: AppNeutralColors.grey900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.s6),
                              Row(
                                children: <Widget>[
                                  RichText(
                                    text: TextSpan(
                                      style: AppTypography.bodySmallMedium
                                          .copyWith(
                                            color: AppNeutralColors.grey900,
                                          ),
                                      children: <TextSpan>[
                                        const TextSpan(text: "질문 "),
                                        TextSpan(
                                          text: questionDaysText,
                                          style: AppTypography.bodySmallSemiBold
                                              .copyWith(color: brand.c500),
                                        ),
                                        const TextSpan(text: "일째"),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s8),
                                  Container(
                                    width: 1,
                                    height: 16,
                                    color: AppNeutralColors.grey200,
                                  ),
                                  const SizedBox(width: AppSpacing.s8),
                                  RichText(
                                    text: TextSpan(
                                      style: AppTypography.bodySmallMedium
                                          .copyWith(
                                            color: AppNeutralColors.grey900,
                                          ),
                                      children: <TextSpan>[
                                        const TextSpan(text: "버킷리스트 "),
                                        TextSpan(
                                          text: bucketCountText,
                                          style: AppTypography.bodySmallSemiBold
                                              .copyWith(color: brand.c500),
                                        ),
                                        const TextSpan(text: "개"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
            );
          },
    );
  }

  Future<_ProfileSnapshot> _loadProfileSnapshot(int refreshSeed) async {
    final String? nickname = await loadNickname();
    final MoreProfileStats stats = await loadMoreProfileStats();
    return _ProfileSnapshot(
      nickname: nickname,
      questionStreakDays: stats.questionStreakDays,
      bucketCount: stats.bucketCount,
    );
  }

  String _formatBucketCount(int count) {
    if (count >= 99) {
      return "99+";
    }
    return count.toString();
  }
}

class _ProfileSnapshot {
  const _ProfileSnapshot({
    this.nickname,
    this.questionStreakDays,
    this.bucketCount,
  });

  final String? nickname;
  final int? questionStreakDays;
  final int? bucketCount;
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({required this.title, required this.items});

  final String title;
  final List<_SettingsItem> items;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTypography.heading2XSmall.copyWith(
              color: AppNeutralColors.grey900,
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          ...List<Widget>.generate(items.length, (int index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == items.length - 1 ? 0 : AppSpacing.s24,
              ),
              child: _SettingsRow(item: items[index]),
            );
          }),
        ],
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({required this.title, this.trailingText, this.onTap});

  final String title;
  final String? trailingText;
  final VoidCallback? onTap;
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.item});

  final _SettingsItem item;

  @override
  Widget build(BuildContext context) {
    final Widget row = Row(
      children: <Widget>[
        Expanded(
          child: Text(
            item.title,
            style: AppTypography.bodyMediumMedium.copyWith(
              color: AppNeutralColors.grey900,
            ),
          ),
        ),
        if (item.trailingText != null)
          Text(
            item.trailingText!,
            textAlign: TextAlign.right,
            style: AppTypography.bodySmallMedium.copyWith(
              color: AppNeutralColors.grey500,
            ),
          )
        else
          const Icon(
            Icons.chevron_right,
            size: AppSpacing.s24,
            color: AppNeutralColors.grey900,
          ),
      ],
    );
    if (item.onTap == null) {
      return row;
    }
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: row,
    );
  }
}
