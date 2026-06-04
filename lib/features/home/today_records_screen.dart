import "dart:async";

import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../core/kst_date_time.dart";
import "../../design_system/design_system.dart";
import "home_screen.dart";
import "../navigation/main_tab_shell.dart";
import "public_record_report_repository.dart";
import "../question/today_question_prompt_store.dart";
import "../question/today_question_store.dart";
import "public_today_records_repository.dart";

class TodayRecordsScreen extends StatefulWidget {
  const TodayRecordsScreen({
    super.key,
    this.questionDateKey,
    this.questionText,
    this.initialRecords = const <PublicTodayRecord>[],
  });

  final String? questionDateKey;
  final String? questionText;
  final List<PublicTodayRecord> initialRecords;

  @override
  State<TodayRecordsScreen> createState() => _TodayRecordsScreenState();
}

class _TodayRecordsScreenState extends State<TodayRecordsScreen>
    with WidgetsBindingObserver {
  static const String _hiddenRecordsPrefsKey =
      "today_records_hidden_record_ids";
  static const String _blockedAuthorsPrefsKey = "today_records_blocked_authors";
  static const String _likedRecordIdsPrefsKey =
      "today_records_liked_record_ids";
  bool _isLoading = true;
  List<_TodayRecordItem> _records = const <_TodayRecordItem>[];
  Set<String> _hiddenRecordIds = <String>{};
  Set<String> _blockedAuthors = <String>{};
  Set<String> _likedRecordIds = <String>{};
  String _questionText = "오늘의 질문";
  Timer? _dateRefreshTimer;
  late String _lastKstDateKey;
  StreamSubscription<List<PublicTodayRecord>>? _recordsSubscription;

  @override
  void initState() {
    super.initState();
    _lastKstDateKey = widget.questionDateKey ?? kstDateKeyNow();
    _questionText = widget.questionText ?? "오늘의 질문";
    _records = widget.initialRecords
        .map(
          (PublicTodayRecord item) => _TodayRecordItem(
            body: item.body,
            author: item.author,
            createdAt: item.createdAt,
            questionDateKey: item.questionDateKey.isEmpty
                ? _lastKstDateKey
                : item.questionDateKey,
            questionSlot: item.questionSlot,
            answerDocId: item.answerDocId,
            likeCount: item.likeCount,
            isLiked: _likedRecordIds.contains(_likeTargetId(item)),
          ),
        )
        .toList(growable: false);
    _isLoading = widget.initialRecords.isEmpty;
    WidgetsBinding.instance.addObserver(this);
    _loadHiddenRecordIds();
    _loadBlockedAuthors();
    _loadLikedRecordIds();
    _bindRecordsStream();
    unawaited(_loadQuestionText());
    _scheduleDateRefreshTimer();
  }

  Future<void> _loadHiddenRecordIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> saved =
        prefs.getStringList(_hiddenRecordsPrefsKey) ?? const <String>[];
    if (!mounted) {
      return;
    }
    setState(() {
      _hiddenRecordIds = saved.toSet();
      _records = _applyLocalFilters(_records);
    });
  }

  Future<void> _loadBlockedAuthors() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> saved =
        prefs.getStringList(_blockedAuthorsPrefsKey) ?? const <String>[];
    if (!mounted) {
      return;
    }
    setState(() {
      _blockedAuthors = saved.toSet();
      _records = _applyLocalFilters(_records);
    });
  }

  Future<void> _loadLikedRecordIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> saved =
        prefs.getStringList(_likedRecordIdsPrefsKey) ?? const <String>[];
    if (!mounted) {
      return;
    }
    setState(() {
      _likedRecordIds = saved.toSet();
      _records = _records
          .map(
            (item) => item.copyWith(
              isLiked: _likedRecordIds.contains(item.likeTargetId),
            ),
          )
          .toList(growable: false);
    });
  }

  Future<void> _loadQuestionText() async {
    await TodayQuestionPromptStore.instance.initialize();
    await TodayQuestionPromptStore.instance.reloadIfNeeded();
    if (!mounted) {
      return;
    }
    setState(() {
      _questionText =
          TodayQuestionPromptStore.instance.value.currentQuestionText;
    });
  }

  void _bindRecordsStream() {
    _recordsSubscription?.cancel();
    _recordsSubscription = PublicTodayRecordsRepository.instance
        .watchByDateKey(_lastKstDateKey)
        .listen(
          (List<PublicTodayRecord> remoteRecords) {
            if (!mounted) {
              return;
            }
            final List<PublicTodayRecord> mergedWithLocal =
                _mergeWithLocalPublicRecords(remoteRecords);
            final List<_TodayRecordItem> mergedRecords = mergedWithLocal
                .map(_toRecordItem)
                .toList(growable: false);
            setState(() {
              _records = _applyLocalFilters(mergedRecords);
              _isLoading = false;
            });
          },
          onError: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              final List<PublicTodayRecord> localOnly =
                  _mergeWithLocalPublicRecords(const <PublicTodayRecord>[]);
              _records = localOnly.map(_toRecordItem).toList(growable: false);
              _records = _applyLocalFilters(_records);
              _isLoading = false;
            });
          },
        );
  }

  List<_TodayRecordItem> _applyLocalFilters(List<_TodayRecordItem> source) {
    return source
        .where((item) {
          if (_hiddenRecordIds.contains(item.reportTargetId)) {
            return false;
          }
          if (_blockedAuthors.contains(item.author)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  Future<void> _hideRecordLocally(_TodayRecordItem item) async {
    final String targetId = item.reportTargetId;
    if (_hiddenRecordIds.contains(targetId)) {
      return;
    }
    setState(() {
      _hiddenRecordIds = <String>{..._hiddenRecordIds, targetId};
      _records = _applyLocalFilters(_records);
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _hiddenRecordsPrefsKey,
      _hiddenRecordIds.toList(growable: false),
    );
  }

  Future<void> _blockAuthorLocally(_TodayRecordItem item) async {
    final String author = item.author.trim();
    if (author.isEmpty || _blockedAuthors.contains(author)) {
      return;
    }
    setState(() {
      _blockedAuthors = <String>{..._blockedAuthors, author};
      _records = _applyLocalFilters(_records);
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _blockedAuthorsPrefsKey,
      _blockedAuthors.toList(growable: false),
    );
  }

  List<PublicTodayRecord> _mergeWithLocalPublicRecords(
    List<PublicTodayRecord> remoteRecords,
  ) {
    final Map<String, PublicTodayRecord> byKey = <String, PublicTodayRecord>{};
    for (final PublicTodayRecord item in remoteRecords) {
      byKey[_recordKey(item)] = item;
    }

    for (final record in TodayQuestionStore.instance.value) {
      if (!record.isPublic) {
        continue;
      }
      final String questionKey =
          (record.questionDateKey?.trim().isNotEmpty ?? false)
          ? record.questionDateKey!.trim()
          : kstDateKeyFromDateTime(record.createdAt);
      if (questionKey != _lastKstDateKey) {
        continue;
      }
      final PublicTodayRecord localAsPublic = PublicTodayRecord(
        body: record.answer,
        author: record.author,
        createdAt: record.createdAt,
        questionDateKey: questionKey,
        questionSlot: -1,
        answerDocId: "",
      );
      byKey.putIfAbsent(_recordKey(localAsPublic), () => localAsPublic);
    }

    final List<PublicTodayRecord> merged = byKey.values.toList(growable: false);
    merged.sort((PublicTodayRecord a, PublicTodayRecord b) {
      return b.createdAt.compareTo(a.createdAt);
    });
    return merged;
  }

  String _recordKey(PublicTodayRecord item) {
    return "${item.createdAt.millisecondsSinceEpoch}|${item.author}|${item.body}";
  }

  String _likeTargetId(PublicTodayRecord item) {
    if (item.canToggleLike) {
      return "${item.questionDateKey}/slot_${item.questionSlot}/${item.answerDocId}";
    }
    return _recordKey(item);
  }

  _TodayRecordItem _toRecordItem(PublicTodayRecord item) {
    final String questionDateKey = item.questionDateKey.isEmpty
        ? _lastKstDateKey
        : item.questionDateKey;
    final _TodayRecordItem recordItem = _TodayRecordItem(
      body: item.body,
      author: item.author,
      createdAt: item.createdAt,
      questionDateKey: questionDateKey,
      questionSlot: item.questionSlot,
      answerDocId: item.answerDocId,
      likeCount: item.likeCount,
      isLiked: _likedRecordIds.contains(_likeTargetId(item)),
    );
    return recordItem;
  }

  Future<_TodayRecordLikeUpdate> _toggleRecordLike(
    _TodayRecordItem item,
  ) async {
    if (!item.canToggleLike) {
      final bool nextLiked = !item.isLiked;
      final int nextCount = nextLiked
          ? item.likeCount + 1
          : (item.likeCount > 0 ? item.likeCount - 1 : 0);
      final Set<String> nextLikedRecordIds = <String>{..._likedRecordIds};
      if (nextLiked) {
        nextLikedRecordIds.add(item.likeTargetId);
      } else {
        nextLikedRecordIds.remove(item.likeTargetId);
      }

      if (mounted) {
        setState(() {
          _likedRecordIds = nextLikedRecordIds;
          _records = _records
              .map(
                (_TodayRecordItem current) =>
                    current.likeTargetId == item.likeTargetId
                    ? current.copyWith(isLiked: nextLiked, likeCount: nextCount)
                    : current,
              )
              .toList(growable: false);
        });
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _likedRecordIdsPrefsKey,
        nextLikedRecordIds.toList(growable: false),
      );

      return _TodayRecordLikeUpdate(isLiked: nextLiked, likeCount: nextCount);
    }

    final PublicRecordLikeResult result = await PublicTodayRecordsRepository
        .instance
        .toggleLike(item.toPublicRecord());
    final Set<String> nextLikedRecordIds = <String>{..._likedRecordIds};
    if (result.liked) {
      nextLikedRecordIds.add(item.likeTargetId);
    } else {
      nextLikedRecordIds.remove(item.likeTargetId);
    }

    if (mounted) {
      setState(() {
        _likedRecordIds = nextLikedRecordIds;
        _records = _records
            .map(
              (_TodayRecordItem current) =>
                  current.likeTargetId == item.likeTargetId
                  ? current.copyWith(
                      isLiked: result.liked,
                      likeCount: result.likeCount,
                    )
                  : current,
            )
            .toList(growable: false);
      });
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _likedRecordIdsPrefsKey,
      nextLikedRecordIds.toList(growable: false),
    );

    return _TodayRecordLikeUpdate(
      isLiked: result.liked,
      likeCount: result.likeCount,
    );
  }

  void _scheduleDateRefreshTimer() {
    _dateRefreshTimer?.cancel();
    _dateRefreshTimer = Timer(durationUntilNextKstDateChange(), () {
      if (!mounted) {
        return;
      }
      unawaited(_refreshIfKstDateChanged());
      _scheduleDateRefreshTimer();
    });
  }

  Future<void> _refreshIfKstDateChanged() async {
    final String currentKey = kstDateKeyNow();
    if (currentKey == _lastKstDateKey) {
      return;
    }
    setState(() {
      _isLoading = true;
      _lastKstDateKey = currentKey;
    });
    _bindRecordsStream();
    await _loadQuestionText();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshIfKstDateChanged());
      _scheduleDateRefreshTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dateRefreshTimer?.cancel();
    _recordsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      body: Padding(
        padding: EdgeInsets.zero,
        child: _isLoading
            ? const _RecordsLoadingView()
            : _RecordsListView(
                records: _records,
                questionText: _questionText,
                onHideRecord: _hideRecordLocally,
                onBlockAuthor: _blockAuthorLocally,
                onToggleLike: _toggleRecordLike,
              ),
      ),
    );
  }
}

class _RecordsLoadingView extends StatelessWidget {
  const _RecordsLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const AppLoadingIndicator(),
          const SizedBox(height: AppSpacing.s56),
          Text(
            "사람들의 생각을 불러오는 중입니다.",
            style: AppTypography.headingSmall.copyWith(
              color: AppNeutralColors.grey900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordsListView extends StatelessWidget {
  const _RecordsListView({
    required this.records,
    required this.questionText,
    required this.onHideRecord,
    required this.onBlockAuthor,
    required this.onToggleLike,
  });

  final List<_TodayRecordItem> records;
  final String questionText;
  final Future<void> Function(_TodayRecordItem item) onHideRecord;
  final Future<void> Function(_TodayRecordItem item) onBlockAuthor;
  final Future<_TodayRecordLikeUpdate> Function(_TodayRecordItem item)
  onToggleLike;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final TextTheme textTheme = Theme.of(context).textTheme;
    void goHome() {
      HomeScreen.goHome(context);
    }

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s20,
              114,
              AppSpacing.s20,
              AppNavigationBar.totalHeight(context) + AppSpacing.s20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                    vertical: AppSpacing.s24,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: brand.c200)),
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        questionText,
                        textAlign: TextAlign.center,
                        style: AppTypography.headingLarge.copyWith(
                          color: AppNeutralColors.grey900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Text(
                        "${records.length}명 기록중",
                        style: AppTypography.bodySmallRegular.copyWith(
                          color: AppNeutralColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                ...records.map(
                  (item) => _FullRecordCard(
                    item: item,
                    onHideRecord: onHideRecord,
                    onBlockAuthor: onBlockAuthor,
                    onToggleLike: onToggleLike,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: SizedBox(
            height: 114,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 49),
                SizedBox(
                  height: 65,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s20,
                    ),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: goHome,
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: AppNeutralColors.grey900,
                            size: 22,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        Expanded(
                          child: Text(
                            "오늘의 기록",
                            textAlign: TextAlign.center,
                            style:
                                textTheme.titleMedium?.copyWith(
                                  color: AppNeutralColors.grey900,
                                ) ??
                                AppTypography.headingXSmall.copyWith(
                                  color: AppNeutralColors.grey900,
                                ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AppNavigationBar(
            currentIndex: 0,
            onTap: (int index) {
              if (index == 0) {
                goHome();
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
              AppNavigationBarItemData(label: "더보기", icon: Icons.more_horiz),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayRecordItem {
  const _TodayRecordItem({
    required this.body,
    required this.author,
    required this.createdAt,
    required this.questionDateKey,
    required this.questionSlot,
    required this.answerDocId,
    required this.likeCount,
    required this.isLiked,
  });

  final String body;
  final String author;
  final DateTime createdAt;
  final String questionDateKey;
  final int questionSlot;
  final String answerDocId;
  final int likeCount;
  final bool isLiked;

  String get reportTargetId =>
      "${createdAt.millisecondsSinceEpoch}|$author|$body";

  String get likeTargetId {
    if (answerDocId.isNotEmpty && questionSlot >= 0) {
      return "$questionDateKey/slot_$questionSlot/$answerDocId";
    }
    return reportTargetId;
  }

  bool get canToggleLike => answerDocId.isNotEmpty && questionSlot >= 0;

  _TodayRecordItem copyWith({int? likeCount, bool? isLiked}) {
    return _TodayRecordItem(
      body: body,
      author: author,
      createdAt: createdAt,
      questionDateKey: questionDateKey,
      questionSlot: questionSlot,
      answerDocId: answerDocId,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  PublicTodayRecord toPublicRecord() {
    return PublicTodayRecord(
      body: body,
      author: author,
      createdAt: createdAt,
      questionDateKey: questionDateKey,
      questionSlot: questionSlot,
      answerDocId: answerDocId,
      likeCount: likeCount,
    );
  }
}

class _TodayRecordLikeUpdate {
  const _TodayRecordLikeUpdate({
    required this.isLiked,
    required this.likeCount,
  });

  final bool isLiked;
  final int likeCount;
}

enum _RecordMenuAction { report, hide, block }

class _FullRecordCard extends StatefulWidget {
  const _FullRecordCard({
    required this.item,
    required this.onHideRecord,
    required this.onBlockAuthor,
    required this.onToggleLike,
  });

  final _TodayRecordItem item;
  final Future<void> Function(_TodayRecordItem item) onHideRecord;
  final Future<void> Function(_TodayRecordItem item) onBlockAuthor;
  final Future<_TodayRecordLikeUpdate> Function(_TodayRecordItem item)
  onToggleLike;

  @override
  State<_FullRecordCard> createState() => _FullRecordCardState();
}

class _FullRecordCardState extends State<_FullRecordCard> {
  final PublicRecordReportRepository _reportRepository =
      PublicRecordReportRepository();
  _RecordMenuAction? _selectedAction;
  late bool _isLiked;
  late int _likeCount;
  bool _isTogglingLike = false;
  int _likeBurstKey = 0;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.item.isLiked;
    _likeCount = widget.item.likeCount;
  }

  @override
  void didUpdateWidget(covariant _FullRecordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.likeTargetId != widget.item.likeTargetId) {
      _isLiked = widget.item.isLiked;
      _likeCount = widget.item.likeCount;
      _isTogglingLike = false;
      _likeBurstKey = 0;
      return;
    }
    if (!_isTogglingLike) {
      _isLiked = widget.item.isLiked;
      _likeCount = widget.item.likeCount;
    }
  }

  Future<void> _selectAction(_RecordMenuAction action) async {
    setState(() {
      _selectedAction = action;
    });
    if (action == _RecordMenuAction.report) {
      await _openReportBottomSheet();
      return;
    }
    if (action == _RecordMenuAction.hide) {
      await _openHideBottomSheet();
      return;
    }
    if (action == _RecordMenuAction.block) {
      await _openBlockBottomSheet();
    }
  }

  Future<void> _toggleLike() async {
    if (_isTogglingLike) {
      return;
    }
    final bool wasLiked = _isLiked;
    final int previousCount = _likeCount;
    final bool nextLiked = !wasLiked;
    final int nextCount = nextLiked
        ? previousCount + 1
        : (previousCount > 0 ? previousCount - 1 : 0);

    setState(() {
      _isTogglingLike = true;
      _isLiked = nextLiked;
      _likeCount = nextCount;
      if (nextLiked) {
        _likeBurstKey += 1;
      }
    });

    try {
      final _TodayRecordLikeUpdate update = await widget.onToggleLike(
        widget.item,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isLiked = update.isLiked;
        _likeCount = update.likeCount;
        _isTogglingLike = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLiked = wasLiked;
        _likeCount = previousCount;
        _isTogglingLike = false;
      });
      _showToast("좋아요를 반영하지 못했어요. 잠시 후 다시 시도해주세요.");
    }
  }

  Future<void> _openActionListBottomSheet() async {
    final _RecordMenuAction?
    action = await showModalBottomSheet<_RecordMenuAction>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppPopupTokens.dimmed,
      elevation: 0,
      builder: (BuildContext sheetContext) {
        final double keyboardInset = MediaQuery.viewInsetsOf(
          sheetContext,
        ).bottom;
        final double bottomInset = MediaQuery.viewPaddingOf(
          sheetContext,
        ).bottom;
        final double safeBottomPadding =
            (bottomInset + AppSpacing.s24) < AppSpacing.s48
            ? AppSpacing.s48
            : (bottomInset + AppSpacing.s24);

        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppNeutralColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: AppPopupTokens.bottomSheetShadow,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s24,
              AppSpacing.s20,
              AppSpacing.s24,
              safeBottomPadding + keyboardInset,
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
                const SizedBox(height: AppSpacing.s16),
                Text(
                  "작업 선택",
                  style: AppTypography.headingXSmall.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                AppBottomSheetListItem(
                  label: "신고",
                  selected: _selectedAction == _RecordMenuAction.report,
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_RecordMenuAction.report),
                ),
                AppBottomSheetListItem(
                  label: "숨김",
                  selected: _selectedAction == _RecordMenuAction.hide,
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_RecordMenuAction.hide),
                ),
                AppBottomSheetListItem(
                  label: "차단",
                  selected: _selectedAction == _RecordMenuAction.block,
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_RecordMenuAction.block),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (action == null || !mounted) {
      return;
    }
    await _selectAction(action);
  }

  Future<void> _openHideBottomSheet() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext dialogContext) {
        final AppButtonMetrics buttonMetrics = AppButtonTokens.metrics(
          AppButtonSize.large,
        );
        final BrandScale brand = dialogContext.appBrandScale;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: AppNeutralColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.s16),
            ),
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  "이 답변을 숨기시겠어요?",
                  style: AppTypography.headingSmall.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  "숨기면 내 기기에서만 보이지 않아요.",
                  style: AppTypography.bodyMediumRegular.copyWith(
                    color: AppNeutralColors.grey500,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                SizedBox(
                  height: 56,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: AppNeutralColors.grey100,
                            foregroundColor: AppNeutralColors.grey600,
                            textStyle: buttonMetrics.textStyle,
                            overlayColor: Colors.transparent,
                            splashFactory: NoSplash.splashFactory,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s8,
                              ),
                            ),
                          ),
                          child: const Text("취소"),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: brand.c500,
                            foregroundColor: AppNeutralColors.white,
                            textStyle: buttonMetrics.textStyle,
                            overlayColor: Colors.transparent,
                            splashFactory: NoSplash.splashFactory,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s8,
                              ),
                            ),
                          ),
                          child: const Text("숨기기"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await widget.onHideRecord(widget.item);
    if (mounted) {
      _showToast("이 답변을 숨겼어요.");
    }
  }

  Future<void> _openBlockBottomSheet() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext dialogContext) {
        final AppButtonMetrics buttonMetrics = AppButtonTokens.metrics(
          AppButtonSize.large,
        );
        final BrandScale brand = dialogContext.appBrandScale;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: AppNeutralColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.s16),
            ),
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  "이 사용자를 차단하시겠어요?",
                  style: AppTypography.headingSmall.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  "차단하면 내 기기에서만 이 사용자의 글이 보이지 않아요.",
                  style: AppTypography.bodyMediumRegular.copyWith(
                    color: AppNeutralColors.grey500,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                SizedBox(
                  height: 56,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: AppNeutralColors.grey100,
                            foregroundColor: AppNeutralColors.grey600,
                            textStyle: buttonMetrics.textStyle,
                            overlayColor: Colors.transparent,
                            splashFactory: NoSplash.splashFactory,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s8,
                              ),
                            ),
                          ),
                          child: const Text("취소"),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: brand.c500,
                            foregroundColor: AppNeutralColors.white,
                            textStyle: buttonMetrics.textStyle,
                            overlayColor: Colors.transparent,
                            splashFactory: NoSplash.splashFactory,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s8,
                              ),
                            ),
                          ),
                          child: const Text("차단하기"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await widget.onBlockAuthor(widget.item);
    if (mounted) {
      _showToast("이 사용자를 차단했어요.");
    }
  }

  Future<void> _openReportBottomSheet() async {
    final TextEditingController reasonController = TextEditingController();
    final FocusNode reasonFocusNode = FocusNode();
    final bool? submitted = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppPopupTokens.dimmed,
      elevation: 0,
      builder: (BuildContext sheetContext) {
        final AppButtonMetrics buttonMetrics = AppButtonTokens.metrics(
          AppButtonSize.large,
        );
        final double keyboardInset = MediaQuery.viewInsetsOf(
          sheetContext,
        ).bottom;
        final double bottomInset = MediaQuery.viewPaddingOf(
          sheetContext,
        ).bottom;
        final double safeBottomPadding =
            (bottomInset + AppSpacing.s24) < AppSpacing.s48
            ? AppSpacing.s48
            : (bottomInset + AppSpacing.s24);
        final BrandScale brand = sheetContext.appBrandScale;

        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppNeutralColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: AppPopupTokens.bottomSheetShadow,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.s24,
              AppSpacing.s24,
              AppSpacing.s24,
              safeBottomPadding + keyboardInset,
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
                Text(
                  "이 답변을 신고하시겠어요?",
                  style: AppTypography.headingSmall.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  "아래 신고 사유를 간단하게 적어주세요.",
                  style: AppTypography.bodyMediumRegular.copyWith(
                    color: AppNeutralColors.grey500,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                AppEditableTextArea(
                  controller: reasonController,
                  focusNode: reasonFocusNode,
                  hintText: "신고사유",
                  height: 100,
                  backgroundColor: AppNeutralColors.grey50,
                  borderColor: Colors.transparent,
                  contentPadding: const EdgeInsets.all(10),
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: AppSpacing.s20),
                SizedBox(
                  height: 56,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(false),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: AppNeutralColors.grey100,
                            foregroundColor: AppNeutralColors.grey600,
                            textStyle: buttonMetrics.textStyle,
                            overlayColor: Colors.transparent,
                            splashFactory: NoSplash.splashFactory,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s8,
                              ),
                            ),
                          ),
                          child: const Text("취소"),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(sheetContext).pop(true),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: brand.c500,
                            foregroundColor: AppNeutralColors.white,
                            textStyle: buttonMetrics.textStyle,
                            overlayColor: Colors.transparent,
                            splashFactory: NoSplash.splashFactory,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.s8,
                              ),
                            ),
                          ),
                          child: const Text("보내기"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) {
      reasonFocusNode.dispose();
      reasonController.dispose();
      return;
    }

    if (submitted == true) {
      final String reason = reasonController.text.trim();
      if (reason.isEmpty) {
        _showToast("신고 사유를 입력해주세요.");
        reasonFocusNode.dispose();
        reasonController.dispose();
        return;
      }
      try {
        await _reportRepository.submit(
          reason: reason,
          targetId: widget.item.reportTargetId,
          targetType: "public_answer",
          questionDateKey: widget.item.questionDateKey,
          authorName: widget.item.author,
          answerPreview: widget.item.body,
        );
        if (mounted) {
          _showToast("신고가 접수되었습니다. 빠르게 확인할게요.");
        }
      } on PublicRecordReportSubmitException catch (error) {
        if (mounted) {
          _showToast(error.userMessage);
        }
      } catch (_) {
        if (mounted) {
          _showToast("신고 접수에 실패했어요. 잠시 후 다시 시도해주세요.");
        }
      }
    }
    reasonFocusNode.dispose();
    reasonController.dispose();
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            message,
            style: AppTypography.captionMedium.copyWith(
              color: AppNeutralColors.white,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.s16),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s32,
        vertical: AppSpacing.s24,
      ),
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: AppRadius.br16,
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: Text(
              widget.item.body,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMediumMedium.copyWith(
                color: AppNeutralColors.grey900,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _RecordLikeButton(
                  isLiked: _isLiked,
                  likeCount: _likeCount,
                  burstKey: _likeBurstKey,
                  onTap: _toggleLike,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.s20),
                    child: Text(
                      "${widget.item.author} 답변",
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmallSemiBold.copyWith(
                        color: brand.c500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: "더보기",
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => _openActionListBottomSheet(),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: Icon(
                        Icons.more_horiz,
                        size: 24,
                        color: AppNeutralColors.grey200,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordLikeButton extends StatelessWidget {
  const _RecordLikeButton({
    required this.isLiked,
    required this.likeCount,
    required this.burstKey,
    required this.onTap,
  });

  final bool isLiked;
  final int likeCount;
  final int burstKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final Color iconColor = isLiked ? brand.c500 : brand.c300;
    final Color countColor = brand.c500;
    return Semantics(
      button: true,
      label: isLiked ? "좋아요 취소" : "좋아요",
      value: "$likeCount",
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 24,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: <Widget>[
              if (burstKey > 0)
                Positioned(
                  left: -2,
                  top: -10,
                  child: _FloatingHeartsBurst(
                    key: ValueKey<int>(burstKey),
                    color: brand.c500,
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedScale(
                    scale: isLiked ? 1.08 : 1,
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutBack,
                    child: AppLikeIcon(
                      selected: isLiked,
                      size: AppIconSize.s20,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.18),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                    child: Text(
                      "$likeCount",
                      key: ValueKey<int>(likeCount),
                      style: AppTypography.captionMedium.copyWith(
                        color: countColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingHeartsBurst extends StatefulWidget {
  const _FloatingHeartsBurst({super.key, required this.color});

  final Color color;

  @override
  State<_FloatingHeartsBurst> createState() => _FloatingHeartsBurstState();
}

class _FloatingHeartsBurstState extends State<_FloatingHeartsBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 44,
        height: 44,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final double progress = Curves.easeOutCubic.transform(
              _controller.value,
            );
            final double opacity = 1 - progress;
            return Stack(
              children: <Widget>[
                _BurstHeart(
                  color: widget.color,
                  opacity: opacity,
                  size: 10,
                  offset: Offset(17 - (progress * 9), 22 - (progress * 28)),
                  rotation: -0.22,
                ),
                _BurstHeart(
                  color: widget.color,
                  opacity: opacity * 0.9,
                  size: 8,
                  offset: Offset(21 + (progress * 12), 24 - (progress * 24)),
                  rotation: 0.18,
                ),
                _BurstHeart(
                  color: widget.color,
                  opacity: opacity * 0.8,
                  size: 7,
                  offset: Offset(12 + (progress * 3), 26 - (progress * 18)),
                  rotation: 0.28,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BurstHeart extends StatelessWidget {
  const _BurstHeart({
    required this.color,
    required this.opacity,
    required this.size,
    required this.offset,
    required this.rotation,
  });

  final Color color;
  final double opacity;
  final double size;
  final Offset offset;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Opacity(
        opacity: opacity.clamp(0, 1),
        child: Transform.rotate(
          angle: rotation,
          child: AppLikeIcon(selected: true, size: size, color: color),
        ),
      ),
    );
  }
}
