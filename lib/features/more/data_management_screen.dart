import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:share_plus/share_plus.dart";

import "../../design_system/design_system.dart";
import "../navigation/main_tab_shell.dart";
import "../splash/splash_screen.dart";
import "local_backup_service.dart";
import "data_management_service.dart";

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key, this.showNavigationBar = true});

  final bool showNavigationBar;

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DataManagementScreen()),
    );
  }

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  bool _isDeleting = false;

  Future<void> _backupLocalData() async {
    try {
      final file = await LocalBackupService.instance.exportBackupFile();
      final ShareResult result = await Share.shareXFiles(<XFile>[
        XFile(file.path),
      ], text: "Daily Question 백업 파일");
      if (!mounted) {
        return;
      }
      if (result.status == ShareResultStatus.success) {
        _showMessage("백업 파일을 내보냈어요.");
        return;
      }
      _showMessage("백업 파일 공유가 취소되었어요.");
    } on LocalBackupException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage("백업에 실패했어요. 잠시 후 다시 시도해주세요.");
    }
  }

  Future<void> _restoreLocalData() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext dialogContext) {
        final BrandScale brand = dialogContext.appBrandScale;
        return Center(
          child: AppPopup(
            width: AppPopupTokens.maxWidth,
            title: "복원하기",
            body: "복원하면 현재 기기 데이터가\n백업 파일 내용으로 교체돼요.",
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
                    "복원하기",
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
      final FilePickerResult? picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>["json"],
      );
      if (picked == null || picked.files.isEmpty) {
        return;
      }
      final PlatformFile file = picked.files.first;
      if (file.path != null) {
        await LocalBackupService.instance.restoreFromFilePath(file.path!);
      } else if (file.bytes != null) {
        await LocalBackupService.instance.restoreFromRawJson(
          String.fromCharCodes(file.bytes!),
        );
      } else {
        throw const LocalBackupException("복원 파일을 읽을 수 없어요.");
      }
      if (!mounted) {
        return;
      }
      _showMessage("복원이 완료됐어요. 앱을 다시 열면 최신 상태로 보여요.");
    } on LocalBackupException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage("복원에 실패했어요. 백업 파일을 확인해주세요.");
    }
  }

  Future<void> _confirmDeviceDataDelete() async {
    final bool? confirmed = await _showDeletePopup(
      title: "이 기기 데이터 삭제",
      body:
          "버킷리스트, 닉네임, 설정, 알림 예약 등을\n"
          "초기화합니다. 계정 연동을 해제하며, 다\n"
          "시 연동하면 데이터가 복원될 수 있습니다.",
    );
    if (confirmed == true) {
      await _deleteData(
        action: DataManagementService.instance.deleteDeviceData,
      );
    }
  }

  Future<void> _confirmAllDataDelete() async {
    final bool? confirmed = await _showDeletePopup(
      title: "모든 데이터 완전 삭제",
      body: "계정 연동을 해제하고, 모든 데이터를 삭제\n합니다. 정말로 삭제하시겠습니까?",
    );
    if (confirmed == true) {
      await _deleteData(action: DataManagementService.instance.deleteAllData);
    }
  }

  Future<bool?> _showDeletePopup({
    required String title,
    required String body,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext dialogContext) {
        return Center(
          child: AppPopup(
            width: AppPopupTokens.maxWidth,
            title: title,
            body: body,
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
                    "데이터 삭제",
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

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteData({required Future<void> Function() action}) async {
    if (_isDeleting) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await action();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => SplashScreen(
            firstDuration: const Duration(milliseconds: 320),
            secondDuration: const Duration(milliseconds: 320),
          ),
        ),
        (Route<dynamic> route) => false,
      );
    } on DataManagementException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage("데이터 삭제에 실패했어요. 잠시 후 다시 시도해주세요.");
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.s20,
                AppHeaderTokens.topInset + 70,
                AppSpacing.s20,
                (widget.showNavigationBar
                        ? AppNavigationBar.totalHeight(context)
                        : 0) +
                    AppSpacing.s24,
              ),
              child: _DataManagementCard(
                items: <_DataManagementItem>[
                  _DataManagementItem(
                    title: "백업하기",
                    onTap: _backupLocalData,
                    showChevron: true,
                  ),
                  _DataManagementItem(
                    title: "복원하기",
                    onTap: _restoreLocalData,
                    showChevron: true,
                  ),
                  _DataManagementItem(
                    title: "이 기기 데이터 삭제",
                    description: "이 작업은 되돌릴 수 없습니다",
                    titleColor: AppSemanticColors.error500,
                    descriptionColor: AppNeutralColors.grey300,
                    onTap: _confirmDeviceDataDelete,
                  ),
                  _DataManagementItem(
                    title: "모든 데이터 완전 삭제",
                    description: "연결된 계정의 백업 데이터도 함께 삭제됩니다",
                    titleColor: AppSemanticColors.error500,
                    descriptionColor: AppNeutralColors.grey300,
                    onTap: _confirmAllDataDelete,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: AppHeaderTokens.topInset,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s20),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: AppSpacing.s24,
                    height: AppSpacing.s24,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
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
                      "데이터 관리",
                      textAlign: TextAlign.center,
                      style: AppTypography.headingXSmall.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s24, height: AppSpacing.s24),
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
                    MainTabShell.replace(context, index: 3);
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
          if (_isDeleting)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0x66000000),
                child: const Center(child: AppLoadingIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _DataManagementCard extends StatelessWidget {
  const _DataManagementCard({required this.items});

  final List<_DataManagementItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.s12),
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        children: List<Widget>.generate(items.length, (int index) {
          final bool isLast = index == items.length - 1;
          return _DataManagementRow(item: items[index], isLast: isLast);
        }),
      ),
    );
  }
}

class _DataManagementItem {
  const _DataManagementItem({
    required this.title,
    required this.onTap,
    this.description,
    this.titleColor = AppNeutralColors.grey900,
    this.descriptionColor = AppNeutralColors.grey500,
    this.showChevron = false,
  });

  final String title;
  final String? description;
  final VoidCallback onTap;
  final Color titleColor;
  final Color descriptionColor;
  final bool showChevron;
}

class _DataManagementRow extends StatelessWidget {
  const _DataManagementRow({required this.item, required this.isLast});

  final _DataManagementItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppSpacing.s12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s20,
            vertical: AppSpacing.s20,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: AppTypography.bodyMediumMedium.copyWith(
                        color: item.titleColor,
                      ),
                    ),
                    if (item.description != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        item.description!,
                        style: AppTypography.bodySmallMedium.copyWith(
                          color: item.descriptionColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.showChevron) ...<Widget>[
                const SizedBox(width: AppSpacing.s12),
                const Icon(
                  Icons.chevron_right,
                  size: AppSpacing.s24,
                  color: AppNeutralColors.grey900,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
