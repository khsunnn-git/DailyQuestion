import "package:flutter/material.dart";
import "package:isar/isar.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../data/local_db/entities/bucket_category_entity.dart";
import "../../data/local_db/entities/bucket_item_entity.dart";
import "../../data/local_db/local_database.dart";
import "../../design_system/design_system.dart";
import "../home/home_screen.dart";
import "../more/more_settings_screen.dart";
import "bucket_add_screen.dart";
import "bucket_category_empty_screen.dart";
import "bucket_save_success_screen.dart";
import "../home/my_records_screen.dart";
import "../more/notification_prefs_keys.dart";
import "../notifications/daily_question_notification_scheduler.dart";

class BucketListScreen extends StatefulWidget {
  const BucketListScreen({super.key});

  @override
  State<BucketListScreen> createState() => _BucketListScreenState();
}

class _BucketListScreenState extends State<BucketListScreen>
    with SingleTickerProviderStateMixin {
  static const String _emptyBucketAsset =
      "assets/images/bucket/bucketlist_empty_state_note.png";
  static const String _allCategoryName = "ALL";
  static const Color _allCategoryColor = AppNeutralColors.grey100;
  int _selectedTabIndex = 0;
  final List<_BucketEntry> _entries = <_BucketEntry>[];
  final List<BucketCategorySelection> _customCategories =
      <BucketCategorySelection>[];
  bool _isLoading = true;
  late final AnimationController _floatingController;
  late final Animation<double> _floatingOffset;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _floatingOffset = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
    _loadPersistedData();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  bool _isAllCategoryName(String name) {
    return name.trim().toUpperCase() == _allCategoryName;
  }

  String _normalizeCategoryKey(String name) {
    return name.trim().toLowerCase();
  }

  List<BucketCategorySelection> _sanitizeCustomCategories(
    Iterable<BucketCategorySelection> categories,
  ) {
    final Set<String> seen = <String>{};
    final List<BucketCategorySelection> sanitized = <BucketCategorySelection>[];
    for (final BucketCategorySelection category in categories) {
      final String trimmedName = category.name.trim();
      if (trimmedName.isEmpty || _isAllCategoryName(trimmedName)) {
        continue;
      }
      final String key = _normalizeCategoryKey(trimmedName);
      if (!seen.add(key)) {
        continue;
      }
      sanitized.add(
        BucketCategorySelection(name: trimmedName, color: category.color),
      );
    }
    return sanitized;
  }

  bool _sameCategorySet(
    List<BucketCategorySelection> before,
    List<BucketCategorySelection> after,
  ) {
    if (before.length != after.length) {
      return false;
    }
    for (int i = 0; i < before.length; i++) {
      final BucketCategorySelection prev = before[i];
      final BucketCategorySelection next = after[i];
      if (_normalizeCategoryKey(prev.name) !=
          _normalizeCategoryKey(next.name)) {
        return false;
      }
      if (prev.color.toARGB32() != next.color.toARGB32()) {
        return false;
      }
    }
    return true;
  }

  List<String> get _tabs {
    return <String>[
      _allCategoryName,
      ..._customCategories.map((BucketCategorySelection e) => e.name),
      "완료🎉",
    ];
  }

  int get _safeSelectedTabIndex {
    final int lastIndex = _tabs.length - 1;
    if (_selectedTabIndex < 0) {
      return 0;
    }
    if (_selectedTabIndex > lastIndex) {
      return lastIndex;
    }
    return _selectedTabIndex;
  }

  List<_BucketEntry> get _filteredEntries {
    final int selectedTab = _safeSelectedTabIndex;
    if (selectedTab == 0) {
      return _entries.where((_BucketEntry e) => !e.isCompleted).toList();
    }
    if (selectedTab == _tabs.length - 1) {
      return _entries.where((_BucketEntry e) => e.isCompleted).toList();
    }
    if (selectedTab > 0 && selectedTab < _tabs.length - 1) {
      final List<_BucketEntry> entries = _entries
          .where((_BucketEntry e) => e.category == _tabs[selectedTab])
          .toList();
      entries.sort((_BucketEntry a, _BucketEntry b) {
        if (a.isCompleted == b.isCompleted) {
          return 0;
        }
        return a.isCompleted ? 1 : -1;
      });
      return entries;
    }
    return <_BucketEntry>[];
  }

  Future<void> _loadPersistedData() async {
    final isar = await LocalDatabase.instance.isar;
    final List<BucketCategoryEntity> persistedCategories = await isar
        .bucketCategoryEntitys
        .where()
        .findAll();
    final List<BucketItemEntity> items = await isar.bucketItemEntitys
        .where()
        .findAll();
    final List<BucketCategorySelection> rawCategories = persistedCategories
        .map((BucketCategoryEntity item) {
          return BucketCategorySelection(
            name: item.name,
            color: Color(item.colorValue),
          );
        })
        .toList(growable: false);
    final List<BucketCategorySelection> categories = _sanitizeCustomCategories(
      rawCategories,
    );
    if (!mounted) {
      return;
    }
    final List<_BucketEntry> entries =
        items.map(_fromBucketEntity).toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _customCategories
        ..clear()
        ..addAll(categories);
      _entries
        ..clear()
        ..addAll(entries);
      _isLoading = false;
    });
    if (!_sameCategorySet(rawCategories, categories)) {
      await _saveCategories(categories: categories);
    }
    await _syncBucketDdayNotificationsFromPrefs();
  }

  Future<void> _saveCategories({
    List<BucketCategorySelection>? categories,
  }) async {
    final isar = await LocalDatabase.instance.isar;
    final List<BucketCategorySelection> source = _sanitizeCustomCategories(
      categories ?? _customCategories,
    );
    final List<BucketCategoryEntity> entities = source
        .map((BucketCategorySelection item) {
          final BucketCategoryEntity entity = BucketCategoryEntity();
          entity.name = item.name;
          entity.colorValue = item.color.toARGB32();
          return entity;
        })
        .toList(growable: false);
    await isar.writeTxn(() async {
      await isar.bucketCategoryEntitys.clear();
      if (entities.isEmpty) {
        return;
      }
      await isar.bucketCategoryEntitys.putAll(entities);
    });
  }

  Future<void> _syncBucketDdayNotificationsFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool enabled =
        prefs.getBool(NotificationPrefsKeys.bucketDdayEnabled) ?? false;
    final int daysBefore =
        prefs.getInt(NotificationPrefsKeys.bucketDdayDaysBefore) ??
        NotificationPrefsKeys.defaultBucketDdayDaysBefore;
    await syncBucketDdayNotificationSchedule(
      enabled: enabled,
      daysBefore: daysBefore,
    );
  }

  Future<_BucketEntry> _putEntry(_BucketEntry entry) async {
    final isar = await LocalDatabase.instance.isar;
    final BucketItemEntity entity = BucketItemEntity();
    if (entry.id != null) {
      entity.id = entry.id!;
    }
    entity.title = entry.title;
    entity.category = entry.category;
    entity.categoryColorValue = entry.categoryColor.toARGB32();
    entity.createdAt = entry.createdAt;
    entity.dueDate = entry.dueDate;
    entity.isCompleted = entry.isCompleted;
    entity.updatedAt = DateTime.now();
    final int savedId = await isar.writeTxn(() async {
      return isar.bucketItemEntitys.put(entity);
    });
    await _syncBucketDdayNotificationsFromPrefs();
    return entry.copyWith(id: savedId);
  }

  Future<void> _deleteEntry(_BucketEntry entry) async {
    if (entry.id == null) {
      return;
    }
    final isar = await LocalDatabase.instance.isar;
    await isar.writeTxn(() async {
      await isar.bucketItemEntitys.delete(entry.id!);
    });
    await _syncBucketDdayNotificationsFromPrefs();
  }

  _BucketEntry _fromBucketEntity(BucketItemEntity entity) {
    return _BucketEntry(
      id: entity.id,
      title: entity.title,
      category: entity.category,
      categoryColor: Color(entity.categoryColorValue),
      createdAt: entity.createdAt,
      dueDate: entity.dueDate,
      isCompleted: entity.isCompleted,
    );
  }

  Future<void> _openAddScreen() async {
    final BucketAddResult? result = await Navigator.of(context)
        .push<BucketAddResult>(
          MaterialPageRoute<BucketAddResult>(
            builder: (_) =>
                BucketAddScreen(initialCategories: _customCategories),
          ),
        );
    if (result == null || !mounted) {
      return;
    }

    final _BucketEntry saved = await _putEntry(
      _BucketEntry(
        title: result.item.title,
        category: result.item.categoryName,
        categoryColor: result.item.categoryColor,
        createdAt: result.item.createdAt,
        dueDate: result.item.dueDate,
        isCompleted: result.item.isCompleted,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _customCategories
        ..clear()
        ..addAll(_sanitizeCustomCategories(result.categories));
      _entries.insert(0, saved);
      _selectedTabIndex = 0;
    });
    await _saveCategories();
  }

  Future<void> _openCategoryScreen() async {
    final BucketCategoryResult? result = await Navigator.of(context)
        .push<BucketCategoryResult>(
          MaterialPageRoute<BucketCategoryResult>(
            builder: (_) =>
                BucketCategoryEmptyScreen(initialCategories: _customCategories),
          ),
        );
    if (result == null || !mounted) {
      return;
    }
    final Set<String> previousCategoryNames = _customCategories
        .map((BucketCategorySelection e) => e.name)
        .toSet();
    final Set<String> nextCategoryNames = result.categories
        .map((BucketCategorySelection e) => e.name)
        .toSet();
    final Set<String> removedCategoryNames = previousCategoryNames.difference(
      nextCategoryNames,
    );
    final List<_BucketEntry> updatedEntries = removedCategoryNames.isEmpty
        ? List<_BucketEntry>.from(_entries)
        : await _reassignEntriesToAll(removedCategoryNames);
    if (!mounted) {
      return;
    }
    setState(() {
      _customCategories
        ..clear()
        ..addAll(_sanitizeCustomCategories(result.categories));
      _entries
        ..clear()
        ..addAll(updatedEntries);
    });
    await _saveCategories();
  }

  Future<List<_BucketEntry>> _reassignEntriesToAll(
    Set<String> removedCategoryNames,
  ) async {
    final List<_BucketEntry> nextEntries = List<_BucketEntry>.from(_entries);
    for (int index = 0; index < nextEntries.length; index++) {
      final _BucketEntry current = nextEntries[index];
      if (!removedCategoryNames.contains(current.category)) {
        continue;
      }
      final _BucketEntry reassigned = current.copyWith(
        category: _allCategoryName,
        categoryColor: _allCategoryColor,
      );
      nextEntries[index] = await _putEntry(reassigned);
    }
    return nextEntries;
  }

  Future<void> _onEntryMenuAction(
    _BucketItemMenuAction action,
    _BucketEntry entry,
  ) async {
    if (!mounted) {
      return;
    }
    switch (action) {
      case _BucketItemMenuAction.edit:
        await _openEditScreen(entry);
        return;
      case _BucketItemMenuAction.delete:
        final bool canDelete = await _confirmDeleteBucket();
        if (!canDelete || !mounted) {
          return;
        }
        setState(() {
          _entries.remove(entry);
        });
        await _deleteEntry(entry);
        return;
      case _BucketItemMenuAction.complete:
        final bool confirmed = await _confirmMoveToCompleted();
        if (!confirmed || !mounted) {
          return;
        }
        final int index = _entries.indexOf(entry);
        if (index < 0) {
          return;
        }
        final _BucketEntry updated = _entries[index].copyWith(
          isCompleted: true,
          dueDate: _entries[index].dueDate ?? DateTime.now(),
        );
        final _BucketEntry saved = await _putEntry(updated);
        setState(() {
          _entries[index] = saved;
          _selectedTabIndex = _tabs.length - 1;
        });
        if (!mounted) {
          return;
        }
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const BucketSaveSuccessScreen(
              title: "멋져요!\n버킷리스트 달성완료!",
              subtitle: "완료 카테고리로 이동되었습니다!",
              imageAsset: BucketSaveSuccessScreen.completionAsset,
              autoCloseDuration: Duration(seconds: 1),
            ),
          ),
        );
        return;
    }
  }

  Future<bool> _confirmMoveToCompleted() async {
    final BrandScale brand = context.appBrandScale;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext dialogContext) {
        return Center(
          child: AppPopup(
            width: AppPopupTokens.maxWidth,
            contentPadding: const EdgeInsets.fromLTRB(
              AppSpacing.s20,
              AppSpacing.s32,
              AppSpacing.s20,
              AppSpacing.s20,
            ),
            actionTopGap: AppSpacing.s20,
            title: "해당 버킷리스트를 완료 카테고리\n로 이동하시겠습니까?",
            body: "완료 날짜는 자동으로 오늘로 설정됩니다.\n바꾸고 싶을 땐 수정하기 버튼을 눌러주세요.",
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
                    "이동하기",
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
    return confirmed == true;
  }

  Future<bool> _confirmDeleteBucket() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext dialogContext) {
        return Center(
          child: AppPopup(
            width: AppPopupTokens.maxWidth,
            contentPadding: const EdgeInsets.fromLTRB(
              AppSpacing.s20,
              AppSpacing.s32,
              AppSpacing.s20,
              AppSpacing.s20,
            ),
            actionTopGap: AppSpacing.s20,
            title: "선택한 버킷리스트를\n삭제하시겠습니까?",
            body: "",
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
                    "삭제하기",
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
    return confirmed == true;
  }

  Future<void> _openEditScreen(_BucketEntry entry) async {
    final List<BucketCategorySelection> categories =
        List<BucketCategorySelection>.from(_customCategories);
    final bool hasEntryCategory = categories.any(
      (BucketCategorySelection e) => e.name == entry.category,
    );
    if (!hasEntryCategory) {
      categories.add(
        BucketCategorySelection(
          name: entry.category,
          color: entry.categoryColor,
        ),
      );
    }

    final BucketAddResult? result = await Navigator.of(context)
        .push<BucketAddResult>(
          MaterialPageRoute<BucketAddResult>(
            builder: (_) => BucketAddScreen(
              initialCategories: categories,
              initialItem: BucketCreatedItem(
                title: entry.title,
                categoryName: entry.category,
                categoryColor: entry.categoryColor,
                createdAt: entry.createdAt,
                isCompleted: entry.isCompleted,
                dueDate: entry.dueDate,
              ),
              isEditing: true,
            ),
          ),
        );
    if (result == null || !mounted) {
      return;
    }

    final _BucketEntry updated = _BucketEntry(
      id: entry.id,
      title: result.item.title,
      category: result.item.categoryName,
      categoryColor: result.item.categoryColor,
      createdAt: result.item.createdAt,
      dueDate: result.item.dueDate,
      isCompleted: result.item.isCompleted,
    );
    final _BucketEntry saved = await _putEntry(updated);
    if (!mounted) {
      return;
    }
    setState(() {
      _customCategories
        ..clear()
        ..addAll(_sanitizeCustomCategories(result.categories));
      final int index = _entries.indexOf(entry);
      if (index >= 0) {
        _entries[index] = saved;
      }
    });
    await _saveCategories();
  }

  Future<void> _openEntryMenu({
    required _BucketEntry entry,
    required Offset anchor,
  }) async {
    int? selectedIndex;
    final _BucketItemMenuAction? action =
        await showGeneralDialog<_BucketItemMenuAction>(
          context: context,
          barrierDismissible: true,
          barrierLabel: "dismiss",
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 120),
          pageBuilder:
              (
                BuildContext pageContext,
                Animation<double> primaryAnimation,
                Animation<double> secondaryAnimation,
              ) => const SizedBox.shrink(),
          transitionBuilder:
              (
                BuildContext dialogContext,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
                Widget child,
              ) {
                final Size screen = MediaQuery.of(dialogContext).size;
                const double horizontalSafeMargin = 20;
                const double verticalGapFromIcon = 8;
                final double menuWidth = AppDropdownTokens.menuStyle(
                  AppDropdownMenuSize.lg,
                ).width;
                final double top = anchor.dy + verticalGapFromIcon;
                final double preferredLeft =
                    anchor.dx - menuWidth + (AppSpacing.s24 / 2);
                final double left = preferredLeft.clamp(
                  horizontalSafeMargin,
                  screen.width - horizontalSafeMargin - menuWidth,
                );
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setModalState) {
                    Future<void> selectAndClose(
                      int index,
                      _BucketItemMenuAction value,
                    ) async {
                      setModalState(() {
                        selectedIndex = index;
                      });
                      await Future<void>.delayed(
                        const Duration(milliseconds: 120),
                      );
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(context).pop(value);
                    }

                    return Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => Navigator.of(dialogContext).pop(),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        Positioned(
                          top: top,
                          left: left,
                          child: FadeTransition(
                            opacity: animation,
                            child: Material(
                              color: Colors.transparent,
                              child: AppDropdownMenu(
                                size: AppDropdownMenuSize.lg,
                                items: <AppDropdownItem>[
                                  AppDropdownItem(
                                    label: "수정하기",
                                    state: selectedIndex == 0
                                        ? AppDropdownItemState.selected
                                        : AppDropdownItemState.defaultState,
                                    onTap: () => selectAndClose(
                                      0,
                                      _BucketItemMenuAction.edit,
                                    ),
                                  ),
                                  AppDropdownItem(
                                    label: "삭제하기",
                                    state: selectedIndex == 1
                                        ? AppDropdownItemState.selected
                                        : AppDropdownItemState.defaultState,
                                    onTap: () => selectAndClose(
                                      1,
                                      _BucketItemMenuAction.delete,
                                    ),
                                  ),
                                  AppDropdownItem(
                                    label: "완료하기",
                                    state: selectedIndex == 2
                                        ? AppDropdownItemState.selected
                                        : AppDropdownItemState.defaultState,
                                    onTap: () => selectAndClose(
                                      2,
                                      _BucketItemMenuAction.complete,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
        );

    if (action == null || !mounted) {
      return;
    }
    await _onEntryMenuAction(action, entry);
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: brand.bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final bool isEmpty = _entries.isEmpty;
    final double bottomInset =
        AppNavigationBar.totalHeight(context) + AppSpacing.s24;

    return Scaffold(
      backgroundColor: isEmpty ? brand.c100 : brand.bg,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.s20,
                AppHeaderTokens.topInset,
                AppSpacing.s20,
                isEmpty
                    ? AppNavigationBar.totalHeight(context) + 80
                    : bottomInset,
              ),
              child: isEmpty
                  ? _buildEmptyView(context)
                  : _buildMainView(context),
            ),
          ),
          if (isEmpty)
            Positioned(
              left: AppSpacing.s20,
              right: AppSpacing.s20,
              bottom: AppNavigationBar.totalHeight(context) + AppSpacing.s32,
              child: SizedBox(
                height: AppButtonTokens.metrics(AppButtonSize.large).height,
                child: FilledButton(
                  onPressed: _openAddScreen,
                  style: FilledButton.styleFrom(
                    backgroundColor: brand.c500,
                    foregroundColor: AppNeutralColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppButtonTokens.metrics(
                        AppButtonSize.large,
                      ).radius,
                    ),
                    textStyle: AppButtonTokens.metrics(
                      AppButtonSize.large,
                    ).textStyle,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s24,
                    ),
                  ),
                  child: const Text("버킷리스트 추가"),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppNavigationBar(
              currentIndex: 1,
              onTap: (int index) {
                if (index == 0) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                    (Route<dynamic> route) => false,
                  );
                  return;
                }
                if (index == 2) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const MyRecordsScreen(),
                    ),
                  );
                  return;
                }
                if (index == 3) {
                  MoreSettingsScreen.open(context, replace: true);
                }
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
                AppNavigationBarItemData(label: "더보기", icon: Icons.more_horiz),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: AppHeaderTokens.height,
          child: Row(
            children: <Widget>[
              const SizedBox(width: 24, height: 24),
              Expanded(
                child: Text(
                  "버킷리스트",
                  textAlign: TextAlign.center,
                  style: AppTypography.headingXSmall.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
              ),
              const SizedBox(width: 24, height: 24),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 308,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: 308,
                height: 308,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppNeutralColors.white.withValues(alpha: 0.56),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppNeutralColors.white.withValues(alpha: 0.75),
                      blurRadius: 100,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 235,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s8,
                    ),
                    decoration: BoxDecoration(
                      color: AppNeutralColors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppElevation.level1,
                    ),
                    child: Text(
                      "아직 저장된 버킷리스트가 없어요\n추가해볼까요?!",
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmallMedium.copyWith(
                        color: AppNeutralColors.grey700,
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: const Size(10, 6),
                    painter: _BubbleTailPainter(),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  AnimatedBuilder(
                    animation: _floatingOffset,
                    builder: (BuildContext context, Widget? child) {
                      return Transform.translate(
                        offset: Offset(0, _floatingOffset.value),
                        child: child,
                      );
                    },
                    child: Image.asset(
                      _emptyBucketAsset,
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildMainView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: AppHeaderTokens.height,
          child: Row(
            children: <Widget>[
              const SizedBox(width: 24, height: 24),
              Expanded(
                child: Text(
                  "버킷리스트",
                  textAlign: TextAlign.center,
                  style: AppTypography.headingXSmall.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _openAddScreen,
                child: const Icon(
                  Icons.edit_outlined,
                  size: AppSpacing.s24,
                  color: AppNeutralColors.grey900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Row(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _tabs.asMap().entries.map((
                    MapEntry<int, String> entry,
                  ) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: entry.key == _tabs.length - 1
                            ? 0
                            : AppSpacing.s8,
                      ),
                      child: _BucketTabChip(
                        label: entry.value,
                        selected: entry.key == _safeSelectedTabIndex,
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = entry.key;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            GestureDetector(
              onTap: _openCategoryScreen,
              child: Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: AppNeutralColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: AppElevation.level2,
                ),
                child: const Icon(
                  Icons.add,
                  size: 20,
                  color: AppNeutralColors.grey900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s32),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _filteredEntries.length,
            separatorBuilder: (_, int index) =>
                const SizedBox(height: AppSpacing.s16),
            itemBuilder: (BuildContext context, int index) {
              final _BucketEntry entry = _filteredEntries[index];
              return _BucketListCard(
                entry: entry,
                onMenuTapDown: (TapDownDetails details) {
                  _openEntryMenu(entry: entry, anchor: details.globalPosition);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

enum _BucketItemMenuAction { edit, delete, complete }

class _BucketEntry {
  const _BucketEntry({
    this.id,
    required this.title,
    required this.category,
    required this.categoryColor,
    required this.createdAt,
    this.dueDate,
    this.isCompleted = false,
  });

  final int? id;
  final String title;
  final String category;
  final Color categoryColor;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isCompleted;

  _BucketEntry copyWith({
    int? id,
    String? title,
    String? category,
    Color? categoryColor,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return _BucketEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      categoryColor: categoryColor ?? this.categoryColor,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class _BucketTabChip extends StatelessWidget {
  const _BucketTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s20,
          vertical: AppSpacing.s6,
        ),
        decoration: BoxDecoration(
          color: selected ? brand.c100 : AppNeutralColors.white,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: selected ? Border.all(color: brand.c500) : null,
          boxShadow: AppElevation.level1,
        ),
        child: Text(
          label,
          style: AppTypography.bodySmallSemiBold.copyWith(
            color: selected ? brand.c500 : AppNeutralColors.grey600,
          ),
        ),
      ),
    );
  }
}

class _BucketListCard extends StatelessWidget {
  const _BucketListCard({required this.entry, required this.onMenuTapDown});

  final _BucketEntry entry;
  final ValueChanged<TapDownDetails> onMenuTapDown;

  bool get _isNew =>
      DateTime.now().difference(entry.createdAt) < const Duration(days: 1);

  @override
  Widget build(BuildContext context) {
    String dueText = "-";
    if (entry.dueDate != null) {
      final DateTime dueDate = entry.dueDate!;
      dueText =
          "${dueDate.year.toString().padLeft(4, "0")}."
          "${dueDate.month.toString().padLeft(2, "0")}."
          "${dueDate.day.toString().padLeft(2, "0")}";
      if (entry.isCompleted) {
        dueText = "$dueText 완료";
      } else {
        final DateTime today = DateTime.now();
        final DateTime dueDateOnly = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
        );
        final DateTime todayOnly = DateTime(today.year, today.month, today.day);
        final int remainDays = dueDateOnly.difference(todayOnly).inDays;
        if (remainDays > 0) {
          dueText = "$dueText (D-$remainDays)";
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppElevation.level1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (_isNew && !entry.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8,
                            vertical: AppSpacing.s2,
                          ),
                          decoration: BoxDecoration(
                            color: AppAccentColors.lemon,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            "NEW",
                            style: AppTypography.captionSmall.copyWith(
                              color: AppNeutralColors.grey900,
                            ),
                          ),
                        ),
                      if (_isNew && !entry.isCompleted)
                        const SizedBox(width: AppSpacing.s4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s8,
                          vertical: AppSpacing.s2,
                        ),
                        decoration: BoxDecoration(
                          color: entry.categoryColor,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          entry.category,
                          style: AppTypography.captionSmall.copyWith(
                            color: AppNeutralColors.grey900,
                          ),
                        ),
                      ),
                      if (entry.isCompleted)
                        const SizedBox(width: AppSpacing.s4),
                      if (entry.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8,
                            vertical: AppSpacing.s2,
                          ),
                          decoration: BoxDecoration(
                            color: AppSemanticColors.success500,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            "완료",
                            style: AppTypography.captionSmall.copyWith(
                              color: AppNeutralColors.grey900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading2XSmall.copyWith(
                      color: AppNeutralColors.grey900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Row(
                    children: <Widget>[
                      if (!entry.isCompleted)
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: AppNeutralColors.grey500,
                        ),
                      if (!entry.isCompleted)
                        const SizedBox(width: AppSpacing.s4),
                      Text(
                        dueText,
                        style: AppTypography.bodySmallMedium.copyWith(
                          color: AppNeutralColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              onTapDown: onMenuTapDown,
              child: const SizedBox(
                width: AppSpacing.s24,
                height: AppSpacing.s24,
                child: Icon(
                  Icons.more_vert,
                  size: AppSpacing.s24,
                  color: AppNeutralColors.grey500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = AppNeutralColors.white;
    final Path path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
