import "dart:async";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";

import "../../core/kst_date_time.dart";
import "../../design_system/design_system.dart";
import "../bucket/bucket_list_screen.dart";
import "home_screen.dart";
import "../more/more_settings_screen.dart";
import "../question/today_question_prompt_store.dart";
import "../question/today_question_store.dart";
import "my_records_screen.dart";
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
  bool _isLoading = true;
  List<_TodayRecordItem> _records = const <_TodayRecordItem>[];
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
            questionDateKey: _lastKstDateKey,
          ),
        )
        .toList(growable: false);
    _isLoading = widget.initialRecords.isEmpty;
    WidgetsBinding.instance.addObserver(this);
    _bindRecordsStream();
    _loadQuestionText();
    _startDateRefreshTimer();
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
                .map(
                  (PublicTodayRecord item) => _TodayRecordItem(
                    body: item.body,
                    author: item.author,
                    createdAt: item.createdAt,
                    questionDateKey: _lastKstDateKey,
                  ),
                )
                .toList(growable: false);
            setState(() {
              _records = mergedRecords;
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
              _records = localOnly
                  .map(
                    (PublicTodayRecord item) => _TodayRecordItem(
                      body: item.body,
                      author: item.author,
                      createdAt: item.createdAt,
                      questionDateKey: _lastKstDateKey,
                    ),
                  )
                  .toList(growable: false);
              _isLoading = false;
            });
          },
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

  void _startDateRefreshTimer() {
    _dateRefreshTimer?.cancel();
    _dateRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      _refreshIfKstDateChanged();
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
      _refreshIfKstDateChanged();
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
            : _RecordsListView(records: _records, questionText: _questionText),
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
  const _RecordsListView({required this.records, required this.questionText});

  final List<_TodayRecordItem> records;
  final String questionText;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    final TextTheme textTheme = Theme.of(context).textTheme;
    void goHome() {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    }

    return Stack(
      children: <Widget>[
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
                ...records.map((item) => _FullRecordCard(item: item)),
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
              if (index == 1) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => const BucketListScreen(),
                  ),
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
    );
  }
}

class _TodayRecordItem {
  const _TodayRecordItem({
    required this.body,
    required this.author,
    required this.createdAt,
    required this.questionDateKey,
  });

  final String body;
  final String author;
  final DateTime createdAt;
  final String questionDateKey;

  String get reportTargetId =>
      "${createdAt.millisecondsSinceEpoch}|$author|$body";
}

enum _RecordMenuAction { report, hide, block }

class _FullRecordCard extends StatefulWidget {
  const _FullRecordCard({required this.item});

  final _TodayRecordItem item;

  @override
  State<_FullRecordCard> createState() => _FullRecordCardState();
}

class _FullRecordCardState extends State<_FullRecordCard> {
  final _UserReportRepository _reportRepository = _UserReportRepository();
  bool _showMoreMenu = false;
  _RecordMenuAction? _selectedAction;

  void _toggleMoreMenu() {
    setState(() {
      _showMoreMenu = !_showMoreMenu;
    });
  }

  Future<void> _selectAction(_RecordMenuAction action) async {
    setState(() {
      _selectedAction = action;
      _showMoreMenu = false;
    });
    if (action == _RecordMenuAction.report) {
      await _openReportBottomSheet();
    }
  }

  Future<void> _openReportBottomSheet() async {
    final TextEditingController reasonController = TextEditingController();
    final FocusNode reasonFocusNode = FocusNode();
    final AppButtonMetrics buttonMetrics = AppButtonTokens.metrics(
      AppButtonSize.large,
    );
    final bool? submitted = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppPopupTokens.dimmed,
      builder: (BuildContext sheetContext) {
        final double bottomInset = MediaQuery.viewPaddingOf(
          sheetContext,
        ).bottom;
        final double bottomPadding = bottomInset + AppSpacing.s24;
        final double safeBottomPadding = bottomPadding < AppSpacing.s48
            ? AppSpacing.s48
            : bottomPadding;
        final BrandScale brand = sheetContext.appBrandScale;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: DecoratedBox(
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
                safeBottomPadding,
              ),
              child: SingleChildScrollView(
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
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    SizedBox(
                      height: buttonMetrics.height,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: FilledButton(
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(false),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppNeutralColors.grey100,
                                foregroundColor: AppNeutralColors.grey600,
                                textStyle: buttonMetrics.textStyle,
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
                                  Navigator.of(sheetContext).pop(true),
                              style: FilledButton.styleFrom(
                                backgroundColor: brand.c500,
                                foregroundColor: AppNeutralColors.white,
                                textStyle: buttonMetrics.textStyle,
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
      padding: const EdgeInsets.all(AppSpacing.s32),
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: AppRadius.br16,
        boxShadow: AppElevation.level1,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Column(
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
              const SizedBox(height: AppSpacing.s24),
              SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Text(
                      widget.item.author,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmallSemiBold.copyWith(
                        color: brand.c500,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: IconButton(
                          onPressed: _toggleMoreMenu,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 20,
                            height: 20,
                          ),
                          icon: const Icon(
                            Icons.more_horiz,
                            size: 20,
                            color: AppNeutralColors.grey500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showMoreMenu)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() {
                  _showMoreMenu = false;
                }),
                child: const SizedBox.expand(),
              ),
            ),
          if (_showMoreMenu)
            Positioned(
              right: 0,
              bottom: 8,
              child: AppDropdownMenu(
                size: AppDropdownMenuSize.lg,
                items: <AppDropdownItem>[
                  AppDropdownItem(
                    label: "신고",
                    state: _selectedAction == _RecordMenuAction.report
                        ? AppDropdownItemState.selected
                        : AppDropdownItemState.defaultState,
                    onTap: () {
                      _selectAction(_RecordMenuAction.report);
                    },
                  ),
                  AppDropdownItem(
                    label: "숨김",
                    state: _selectedAction == _RecordMenuAction.hide
                        ? AppDropdownItemState.selected
                        : AppDropdownItemState.defaultState,
                    onTap: () {
                      _selectAction(_RecordMenuAction.hide);
                    },
                  ),
                  AppDropdownItem(
                    label: "차단",
                    state: _selectedAction == _RecordMenuAction.block
                        ? AppDropdownItemState.selected
                        : AppDropdownItemState.defaultState,
                    onTap: () {
                      _selectAction(_RecordMenuAction.block);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _UserReportRepository {
  _UserReportRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> submit({
    required String reason,
    required String targetId,
    required String targetType,
    required String questionDateKey,
    required String authorName,
    required String answerPreview,
  }) async {
    final User? user = _auth.currentUser;
    await _firestore.collection("reports").add(<String, dynamic>{
      "reason": reason,
      "targetId": targetId,
      "targetType": targetType,
      "questionDateKey": questionDateKey,
      "authorName": authorName,
      "answerPreview": answerPreview,
      "reporterUid": user?.uid,
      "status": "open",
      "source": "mobile_app",
      "reportedAt": DateTime.now().toUtc().toIso8601String(),
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }
}
