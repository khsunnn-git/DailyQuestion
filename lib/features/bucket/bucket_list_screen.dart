import "dart:async";
import "dart:io";
import "dart:ui" show ImageFilter;

import "package:flutter/material.dart";
import "package:isar_community/isar.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../data/local_db/entities/answer_record_entity.dart";
import "../../data/local_db/entities/bucket_category_entity.dart";
import "../../data/local_db/entities/bucket_item_entity.dart";
import "../../data/local_db/local_database.dart";
import "../../design_system/design_system.dart";
import "../home/home_character_assets.dart";
import "../home/home_theme_progression.dart";
import "../navigation/main_tab_shell.dart";
import "bucket_backup_service.dart";
import "bucket_add_screen.dart";
import "bucket_category_empty_screen.dart";
import "bucket_completion_screen.dart";
import "bucket_recommendation_screen.dart";
import "bucket_save_success_screen.dart";
import "../more/notification_prefs_keys.dart";
import "../notifications/daily_question_notification_scheduler.dart";

class BucketListScreen extends StatefulWidget {
  const BucketListScreen({super.key, this.showNavigationBar = true});

  final bool showNavigationBar;

  @override
  State<BucketListScreen> createState() => _BucketListScreenState();
}

class _BucketListScreenState extends State<BucketListScreen>
    with SingleTickerProviderStateMixin {
  static const String _emptyBucketFishAsset =
      "assets/images/bucket/bucketlist_empty_state_note_fish.webp";
  static const String _emptyBucketTreeAsset =
      "assets/images/bucket/bucketlist_empty_state_note_tree.webp";
  static const List<String> _bucketHelperMessages = <String>[
    "버킷리스트 너무 어려우신가요?",
    "제가 도움을 드릴게요! 눌러보세요!",
    "하고싶은 일을 적으면 됩니다",
  ];
  static const String _allCategoryName = "ALL";
  static const Color _allCategoryColor = AppNeutralColors.grey100;
  int _selectedTabIndex = 0;
  final List<_BucketEntry> _entries = <_BucketEntry>[];
  final List<BucketCategorySelection> _customCategories =
      <BucketCategorySelection>[];
  bool _isLoading = true;
  int _totalRecordCount = 0;
  int _helperMessageIndex = 0;
  late final PageController _pageController;
  late final ScrollController _tabScrollController;
  late final AnimationController _floatingController;
  late final Animation<double> _floatingOffset;
  Timer? _helperMessageTimer;
  StreamSubscription<void>? _bucketItemsSubscription;
  StreamSubscription<void>? _bucketCategoriesSubscription;
  int _persistedDataRequestId = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabScrollController = ScrollController();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _floatingOffset = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
    _helperMessageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _helperMessageIndex =
            (_helperMessageIndex + 1) % _bucketHelperMessages.length;
      });
    });
    unawaited(_watchPersistedDataChanges());
    unawaited(_loadPersistedData(syncNotifications: true));
  }

  @override
  void dispose() {
    _bucketItemsSubscription?.cancel();
    _bucketCategoriesSubscription?.cancel();
    _helperMessageTimer?.cancel();
    _pageController.dispose();
    _tabScrollController.dispose();
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

  BucketCategorySelection? _findCustomCategory(String name) {
    final String key = _normalizeCategoryKey(name);
    for (final BucketCategorySelection category in _customCategories) {
      if (_normalizeCategoryKey(category.name) == key) {
        return category;
      }
    }
    return null;
  }

  Color? _categoryColorFrom(
    String name,
    Iterable<BucketCategorySelection> categories,
  ) {
    final String key = _normalizeCategoryKey(name);
    for (final BucketCategorySelection category in categories) {
      if (_normalizeCategoryKey(category.name) == key) {
        return category.color;
      }
    }
    return null;
  }

  Future<List<_BucketEntry>> _applyCategoryColorsToEntries({
    required List<_BucketEntry> entries,
    required List<BucketCategorySelection> categories,
  }) async {
    final List<_BucketEntry> nextEntries = List<_BucketEntry>.from(entries);
    for (int index = 0; index < nextEntries.length; index++) {
      final _BucketEntry current = nextEntries[index];
      if (_isAllCategoryName(current.category)) {
        continue;
      }
      final Color? categoryColor = _categoryColorFrom(
        current.category,
        categories,
      );
      if (categoryColor == null ||
          categoryColor.toARGB32() == current.categoryColor.toARGB32()) {
        continue;
      }
      nextEntries[index] = await _putEntry(
        current.copyWith(categoryColor: categoryColor),
      );
    }
    return nextEntries;
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
    return _clampTabIndex(_selectedTabIndex, lastIndex: lastIndex);
  }

  int _clampTabIndex(int index, {int? lastIndex}) {
    final int last = lastIndex ?? _tabs.length - 1;
    if (index < 0) {
      return 0;
    }
    if (index > last) {
      return last;
    }
    return index;
  }

  List<_BucketEntry> _filteredEntriesForTab(int tabIndex) {
    final List<String> tabs = _tabs;
    final int lastIndex = tabs.length - 1;
    final int selectedTab = _clampTabIndex(tabIndex, lastIndex: lastIndex);
    if (selectedTab == 0) {
      return _entries.where((_BucketEntry e) => !e.isCompleted).toList();
    }
    if (selectedTab == tabs.length - 1) {
      return _entries.where((_BucketEntry e) => e.isCompleted).toList();
    }
    if (selectedTab > 0 && selectedTab < tabs.length - 1) {
      final List<_BucketEntry> entries = _entries
          .where((_BucketEntry e) => e.category == tabs[selectedTab])
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

  void _selectTab(int index) {
    final int target = _clampTabIndex(index);
    if (_selectedTabIndex != target) {
      setState(() {
        _selectedTabIndex = target;
      });
    }
    if (!_pageController.hasClients) {
      _scrollSelectedTabIntoView(target);
      return;
    }
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
    _scrollSelectedTabIntoView(target);
  }

  void _jumpToTabPage(int index) {
    if (!_pageController.hasClients) {
      return;
    }
    _pageController.jumpToPage(_clampTabIndex(index));
    _scrollSelectedTabIntoView(index);
  }

  void _scrollSelectedTabIntoView(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_tabScrollController.hasClients) {
        return;
      }
      final double maxOffset = _tabScrollController.position.maxScrollExtent;
      final double targetOffset = (index * 88.0).clamp(0.0, maxOffset);
      _tabScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _emptyBucketAssetFor(BrandScale brand) {
    return brand.c500 == AppBrandThemes.green.c500
        ? _emptyBucketTreeAsset
        : _emptyBucketFishAsset;
  }

  Future<void> _watchPersistedDataChanges() async {
    final isar = await LocalDatabase.instance.isar;
    if (!mounted) {
      return;
    }
    // The bucket tab lives inside an IndexedStack, so it stays mounted while
    // writers in other tabs update the local DB.
    _bucketItemsSubscription = isar.bucketItemEntitys.watchLazy().listen((_) {
      unawaited(_loadPersistedData(syncNotifications: true));
    });
    _bucketCategoriesSubscription = isar.bucketCategoryEntitys
        .watchLazy()
        .listen((_) {
          unawaited(_loadPersistedData());
        });
  }

  Future<void> _loadPersistedData({bool syncNotifications = false}) async {
    final int requestId = ++_persistedDataRequestId;
    final isar = await LocalDatabase.instance.isar;
    final List<BucketCategoryEntity> persistedCategories = await isar
        .bucketCategoryEntitys
        .where()
        .findAll();
    final List<BucketItemEntity> items = await isar.bucketItemEntitys
        .where()
        .findAll();
    final int totalRecordCount = await isar.answerRecordEntitys.where().count();
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
    if (!mounted || requestId != _persistedDataRequestId) {
      return;
    }
    final List<_BucketEntry> entries =
        items.map(_fromBucketEntity).toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final int nextLastTabIndex = categories.length + 1;
    final int nextSelectedTabIndex = _clampTabIndex(
      _selectedTabIndex,
      lastIndex: nextLastTabIndex,
    );
    setState(() {
      _customCategories
        ..clear()
        ..addAll(categories);
      _entries
        ..clear()
        ..addAll(entries);
      _selectedTabIndex = nextSelectedTabIndex;
      _totalRecordCount = totalRecordCount;
      _isLoading = false;
    });
    _jumpToTabPage(nextSelectedTabIndex);
    if (!_sameCategorySet(rawCategories, categories)) {
      await _saveCategories(categories: categories);
    }
    if (syncNotifications) {
      await _syncBucketDdayNotificationsFromPrefs();
    }
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
    unawaited(syncBucketBackup());
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
    entity.achievementImagePath = entry.achievementImagePath;
    entity.achievementNote = entry.achievementNote;
    entity.updatedAt = DateTime.now();
    final int savedId = await isar.writeTxn(() async {
      return isar.bucketItemEntitys.put(entity);
    });
    await _syncBucketDdayNotificationsFromPrefs();
    unawaited(syncBucketBackup());
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
    unawaited(syncBucketBackup());
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
      achievementImagePath: entity.achievementImagePath,
      achievementNote: entity.achievementNote,
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

    final List<BucketCategorySelection> nextCategories =
        _sanitizeCustomCategories(result.categories);
    final Color categoryColor =
        _categoryColorFrom(result.item.categoryName, nextCategories) ??
        result.item.categoryColor;
    final _BucketEntry saved = await _putEntry(
      _BucketEntry(
        title: result.item.title,
        category: result.item.categoryName,
        categoryColor: categoryColor,
        createdAt: result.item.createdAt,
        dueDate: result.item.dueDate,
        isCompleted: result.item.isCompleted,
        achievementImagePath: result.item.achievementImagePath,
        achievementNote: result.item.achievementNote,
      ),
    );
    if (!mounted) {
      return;
    }
    final List<_BucketEntry> recoloredEntries =
        await _applyCategoryColorsToEntries(
          entries: _entries,
          categories: nextCategories,
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _customCategories
        ..clear()
        ..addAll(nextCategories);
      _entries
        ..clear()
        ..addAll(<_BucketEntry>[saved, ...recoloredEntries]);
      _selectedTabIndex = 0;
    });
    _jumpToTabPage(0);
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
    final List<BucketCategorySelection> nextCategories =
        _sanitizeCustomCategories(result.categories);
    final List<_BucketEntry> recoloredEntries =
        await _applyCategoryColorsToEntries(
          entries: updatedEntries,
          categories: nextCategories,
        );
    if (!mounted) {
      return;
    }
    final int nextLastTabIndex = nextCategories.length + 1;
    final int nextSelectedTabIndex = _clampTabIndex(
      _selectedTabIndex,
      lastIndex: nextLastTabIndex,
    );
    setState(() {
      _customCategories
        ..clear()
        ..addAll(nextCategories);
      _entries
        ..clear()
        ..addAll(recoloredEntries);
      _selectedTabIndex = nextSelectedTabIndex;
    });
    _jumpToTabPage(nextSelectedTabIndex);
    await _saveCategories();
  }

  Future<void> _openRecommendationScreen() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BucketRecommendationScreen(
          onAddRecommendation: _addRecommendedBucket,
        ),
      ),
    );
  }

  Future<bool> _addRecommendedBucket(BucketRecommendationItem item) async {
    if (_entries.any(
      (_BucketEntry entry) => entry.title.trim() == item.title.trim(),
    )) {
      return false;
    }
    final BucketCategorySelection? matchingCategory = _findCustomCategory(
      item.category,
    );
    final Color categoryColor = matchingCategory?.color ?? item.color;
    final _BucketEntry saved = await _putEntry(
      _BucketEntry(
        title: item.title,
        category: item.category,
        categoryColor: categoryColor,
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) {
      return true;
    }
    final bool hasCategory = matchingCategory != null;
    setState(() {
      if (!hasCategory) {
        _customCategories.add(
          BucketCategorySelection(name: item.category, color: categoryColor),
        );
      }
      _entries.insert(0, saved);
      _selectedTabIndex = 0;
    });
    _jumpToTabPage(0);
    if (!hasCategory) {
      await _saveCategories();
    }
    return true;
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
        if (entry.isCompleted) {
          await _openCompletionEditor(entry);
          return;
        }
        await _openEditScreen(entry);
        return;
      case _BucketItemMenuAction.delete:
        await _deleteEntryWithConfirmation(entry);
        return;
      case _BucketItemMenuAction.complete:
        await _openCompleteScreen(entry);
        return;
    }
  }

  Future<void> _openCompleteScreen(_BucketEntry entry) async {
    await _openCompletionEditor(entry, showSuccess: true);
  }

  Future<void> _openCompletionEditor(
    _BucketEntry entry, {
    bool showSuccess = false,
  }) async {
    final int index = _entries.indexOf(entry);
    if (index < 0) {
      return;
    }
    final _BucketEntry current = _entries[index];
    final BucketCompletionResult? result = await Navigator.of(context)
        .push<BucketCompletionResult>(
          MaterialPageRoute<BucketCompletionResult>(
            builder: (_) => BucketCompletionScreen(
              title: current.title,
              category: BucketCategorySelection(
                name: current.category,
                color: current.categoryColor,
              ),
              completedDate: current.dueDate ?? DateTime.now(),
              initialImagePath: current.achievementImagePath,
              initialNote: current.achievementNote,
            ),
          ),
        );
    if (result == null || !mounted) {
      return;
    }
    final _BucketEntry updated = current.copyWith(
      isCompleted: true,
      dueDate: result.completedDate,
      achievementImagePath: result.imagePath,
      achievementNote: result.note,
    );
    final _BucketEntry saved = await _putEntry(updated);
    if (!mounted) {
      return;
    }
    setState(() {
      _entries[index] = saved;
      _selectedTabIndex = _tabs.length - 1;
    });
    _jumpToTabPage(_safeSelectedTabIndex);
    if (!showSuccess) {
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
  }

  Future<void> _openCompletionDetail(_BucketEntry entry) async {
    final String imagePath = (entry.achievementImagePath ?? "").trim();
    final String note = (entry.achievementNote ?? "").trim();
    if (!entry.isCompleted || imagePath.isEmpty || note.isEmpty) {
      await _openEditScreen(entry);
      return;
    }
    final BucketCompletionDetailAction? action = await Navigator.of(context)
        .push<BucketCompletionDetailAction>(
          MaterialPageRoute<BucketCompletionDetailAction>(
            builder: (_) => BucketCompletionDetailScreen(
              title: entry.title,
              category: entry.category,
              categoryColor: entry.categoryColor,
              completedDate: entry.dueDate,
              imagePath: imagePath,
              note: note,
            ),
          ),
        );
    if (action == null || !mounted) {
      return;
    }
    switch (action) {
      case BucketCompletionDetailAction.edit:
        await _openCompletionEditor(entry);
        return;
      case BucketCompletionDetailAction.delete:
        await _deleteEntryWithConfirmation(entry);
        return;
    }
  }

  Future<void> _deleteEntryWithConfirmation(_BucketEntry entry) async {
    final bool canDelete = await _confirmDeleteBucket();
    if (!canDelete || !mounted) {
      return;
    }
    setState(() {
      if (entry.id == null) {
        _entries.remove(entry);
      } else {
        _entries.removeWhere((_BucketEntry item) => item.id == entry.id);
      }
    });
    await _deleteEntry(entry);
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
                achievementImagePath: entry.achievementImagePath,
                achievementNote: entry.achievementNote,
              ),
              isEditing: true,
            ),
          ),
        );
    if (result == null || !mounted) {
      return;
    }

    final List<BucketCategorySelection> nextCategories =
        _sanitizeCustomCategories(result.categories);
    final Color categoryColor =
        _categoryColorFrom(result.item.categoryName, nextCategories) ??
        result.item.categoryColor;
    final _BucketEntry updated = _BucketEntry(
      id: entry.id,
      title: result.item.title,
      category: result.item.categoryName,
      categoryColor: categoryColor,
      createdAt: result.item.createdAt,
      dueDate: result.item.dueDate,
      isCompleted: result.item.isCompleted,
      achievementImagePath: result.item.achievementImagePath,
      achievementNote: result.item.achievementNote,
    );
    final _BucketEntry saved = await _putEntry(updated);
    if (!mounted) {
      return;
    }
    final List<_BucketEntry> entriesWithSaved = List<_BucketEntry>.from(
      _entries,
    );
    final int savedIndex = entriesWithSaved.indexOf(entry);
    if (savedIndex >= 0) {
      entriesWithSaved[savedIndex] = saved;
    }
    final List<_BucketEntry> recoloredEntries =
        await _applyCategoryColorsToEntries(
          entries: entriesWithSaved,
          categories: nextCategories,
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _customCategories
        ..clear()
        ..addAll(nextCategories);
      _entries
        ..clear()
        ..addAll(recoloredEntries);
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
          if (widget.showNavigationBar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppNavigationBar(
                currentIndex: 1,
                onTap: (int index) {
                  if (index == 1) {
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

  Widget _buildEmptyView(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
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
              IgnorePointer(
                child: SizedBox(
                  width: 308,
                  height: 308,
                  child: Center(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        // Figma blur 100 대응: sigma 50 적용
                        sigmaX: 50,
                        sigmaY: 50,
                      ),
                      child: Container(
                        width: 208,
                        height: 208,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppNeutralColors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
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
                      _emptyBucketAssetFor(brand),
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
                controller: _tabScrollController,
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
                        onTap: () => _selectTab(entry.key),
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
          child: PageView.builder(
            controller: _pageController,
            clipBehavior: Clip.none,
            itemCount: _tabs.length,
            onPageChanged: (int index) {
              setState(() {
                _selectedTabIndex = index;
              });
              _scrollSelectedTabIntoView(index);
            },
            itemBuilder: (BuildContext context, int tabIndex) {
              final List<_BucketEntry> entries = _filteredEntriesForTab(
                tabIndex,
              );
              return AnimatedBuilder(
                animation: _pageController,
                builder: (BuildContext context, Widget? child) {
                  double pageOffset = 0;
                  if (_pageController.hasClients &&
                      _pageController.position.haveDimensions) {
                    pageOffset = ((_pageController.page ?? tabIndex) - tabIndex)
                        .abs()
                        .clamp(0.0, 1.0)
                        .toDouble();
                  }
                  final double scale = 1 - (pageOffset * 0.015);
                  return Transform.scale(scale: scale, child: child);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s4,
                  ),
                  child: ListView.separated(
                    key: PageStorageKey<String>("bucket-tab-$tabIndex"),
                    padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                    itemCount: entries.length + 1,
                    separatorBuilder: (_, int index) => SizedBox(
                      height: index == entries.length - 1
                          ? (tabIndex == 0 ? AppSpacing.s16 : AppSpacing.s64)
                          : AppSpacing.s16,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == entries.length) {
                        return _BucketRecommendationHelper(
                          message:
                              _bucketHelperMessages[_helperMessageIndex %
                                  _bucketHelperMessages.length],
                          totalRecordCount: _totalRecordCount,
                          onTap: _openRecommendationScreen,
                        );
                      }
                      final _BucketEntry entry = entries[index];
                      return _BucketListCard(
                        entry: entry,
                        onTap: () => _openCompletionDetail(entry),
                        onMenuTapDown: (TapDownDetails details) {
                          _openEntryMenu(
                            entry: entry,
                            anchor: details.globalPosition,
                          );
                        },
                      );
                    },
                  ),
                ),
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
    this.achievementImagePath,
    this.achievementNote,
  });

  final int? id;
  final String title;
  final String category;
  final Color categoryColor;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isCompleted;
  final String? achievementImagePath;
  final String? achievementNote;

  _BucketEntry copyWith({
    int? id,
    String? title,
    String? category,
    Color? categoryColor,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isCompleted,
    String? achievementImagePath,
    String? achievementNote,
  }) {
    return _BucketEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      categoryColor: categoryColor ?? this.categoryColor,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      achievementImagePath: achievementImagePath ?? this.achievementImagePath,
      achievementNote: achievementNote ?? this.achievementNote,
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
        child: AppEmojiText(
          label,
          style: AppTypography.bodySmallSemiBold.copyWith(
            color: selected ? brand.c500 : AppNeutralColors.grey600,
          ),
        ),
      ),
    );
  }
}

class _BucketRecommendationHelper extends StatelessWidget {
  const _BucketRecommendationHelper({
    required this.message,
    required this.totalRecordCount,
    required this.onTap,
  });

  final String message;
  final int totalRecordCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final HomeCharacterType characterType = resolveHomeCharacterType(brand);
    final int growthRecordCount = homeGrowthRecordCountForCharacter(
      characterType: characterType,
      totalRecordCount: totalRecordCount,
    );
    final String characterAsset = HomeCharacterAssets.assetForRecordCount(
      characterType,
      growthRecordCount,
    );

    return Semantics(
      button: true,
      label: "추천 버킷리스트 열기",
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: AppSpeechBubble(
                    key: ValueKey<String>(message),
                    text: message,
                    direction: AppBubbleDirection.right,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Image.asset(
                characterAsset,
                width: 110,
                height: 110,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BucketListCard extends StatelessWidget {
  const _BucketListCard({
    required this.entry,
    required this.onTap,
    required this.onMenuTapDown,
  });

  final _BucketEntry entry;
  final VoidCallback onTap;
  final ValueChanged<TapDownDetails> onMenuTapDown;

  bool get _isNew =>
      DateTime.now().difference(entry.createdAt) < const Duration(days: 1);

  bool get _hasAchievement =>
      (entry.achievementImagePath ?? "").trim().isNotEmpty &&
      (entry.achievementNote ?? "").trim().isNotEmpty;

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

    if (entry.isCompleted && _hasAchievement) {
      return _CompletedBucketCard(
        entry: entry,
        dueText: dueText.replaceAll(" 완료", ""),
        onTap: onTap,
        onMenuTapDown: onMenuTapDown,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
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
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
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
      ),
    );
  }
}

class _CompletedBucketCard extends StatelessWidget {
  const _CompletedBucketCard({
    required this.entry,
    required this.dueText,
    required this.onTap,
    required this.onMenuTapDown,
  });

  final _BucketEntry entry;
  final String dueText;
  final VoidCallback onTap;
  final ValueChanged<TapDownDetails> onMenuTapDown;

  @override
  Widget build(BuildContext context) {
    final File imageFile = File(entry.achievementImagePath!.trim());
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 148,
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppNeutralColors.white,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: AppElevation.level1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.r8),
              child: SizedBox(
                width: 116,
                height: 116,
                child: imageFile.existsSync()
                    ? Image.file(imageFile, fit: BoxFit.cover)
                    : Container(
                        color: AppNeutralColors.grey100,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppNeutralColors.grey400,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _CardBadge(
                        label: entry.category,
                        color: entry.categoryColor,
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      const _CardBadge(
                        label: "완료",
                        color: AppSemanticColors.success100,
                      ),
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {},
                        onTapDown: onMenuTapDown,
                        child: const SizedBox(
                          width: AppSpacing.s24,
                          height: AppSpacing.s24,
                          child: Icon(
                            Icons.more_vert,
                            size: AppSpacing.s20,
                            color: AppNeutralColors.grey500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading2XSmall.copyWith(
                      color: AppNeutralColors.grey900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    entry.achievementNote!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmallRegular.copyWith(
                      color: AppNeutralColors.grey400,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppNeutralColors.grey500,
                      ),
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
          ],
        ),
      ),
    );
  }
}

class _CardBadge extends StatelessWidget {
  const _CardBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTypography.captionSmall.copyWith(
          color: AppNeutralColors.grey900,
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
