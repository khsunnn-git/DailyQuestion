import "dart:io";
import "dart:typed_data";

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:flutter_image_compress/flutter_image_compress.dart";
import "package:image/image.dart" as image_lib;
import "package:path_provider/path_provider.dart";
import "package:pro_image_editor/pro_image_editor.dart";

import "../../design_system/design_system.dart";
import "bucket_category_empty_screen.dart";

class BucketCompletionResult {
  const BucketCompletionResult({
    required this.imagePath,
    required this.note,
    required this.completedDate,
  });

  final String imagePath;
  final String note;
  final DateTime completedDate;
}

enum BucketCompletionDetailAction { edit, delete }

class BucketCompletionScreen extends StatefulWidget {
  const BucketCompletionScreen({
    super.key,
    required this.title,
    required this.category,
    required this.completedDate,
    this.initialImagePath,
    this.initialNote,
    this.onChangeCategory,
    this.onChangeCompletedDate,
  });

  final String title;
  final BucketCategorySelection category;
  final DateTime completedDate;
  final String? initialImagePath;
  final String? initialNote;
  final Future<BucketCategorySelection?> Function()? onChangeCategory;
  final Future<DateTime?> Function(DateTime current)? onChangeCompletedDate;

  @override
  State<BucketCompletionScreen> createState() => _BucketCompletionScreenState();
}

class _BucketCompletionScreenState extends State<BucketCompletionScreen> {
  late final TextEditingController _noteController;
  late BucketCategorySelection _category;
  late DateTime _completedDate;
  String? _imagePath;
  bool _isSavingImage = false;

  bool get _canSave =>
      (_imagePath ?? "").trim().isNotEmpty &&
      _noteController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote ?? "");
    _category = widget.category;
    _completedDate = widget.completedDate;
    _imagePath = widget.initialImagePath;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    final String? selectedPath = result?.files.single.path;
    if (selectedPath == null || selectedPath.trim().isEmpty) {
      return;
    }
    setState(() {
      _isSavingImage = true;
    });
    try {
      final File editableInput = await _createEditableImageFile(selectedPath);
      if (!mounted) {
        return;
      }
      setState(() {
        _isSavingImage = false;
      });
      final Uint8List? editedBytes = await _openImageEditor(editableInput);
      if (!mounted || editedBytes == null || editedBytes.isEmpty) {
        return;
      }
      setState(() {
        _isSavingImage = true;
      });
      final Directory documents = await getApplicationDocumentsDirectory();
      final Directory imageDir = Directory(
        "${documents.path}/bucket_achievements",
      );
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      final String fileName =
          "bucket_${DateTime.now().microsecondsSinceEpoch}.jpg";
      final File output = File("${imageDir.path}/$fileName");
      await _writeEditedImageBytes(editedBytes: editedBytes, output: output);
      if (!mounted) {
        return;
      }
      setState(() {
        _imagePath = output.path;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingImage = false;
        });
      }
    }
  }

  Future<File> _createEditableImageFile(String sourcePath) async {
    final Directory tempDir = await getTemporaryDirectory();
    final File output = File(
      "${tempDir.path}/bucket_edit_${DateTime.now().microsecondsSinceEpoch}.jpg",
    );
    await _copyImageWithBakedOrientation(
      sourcePath: sourcePath,
      output: output,
    );
    return output;
  }

  Future<Uint8List?> _openImageEditor(File source) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute<Uint8List>(
        fullscreenDialog: true,
        builder: (BuildContext editorContext) {
          bool didCompleteEditing = false;
          return ProImageEditor.file(
            source,
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (Uint8List bytes) async {
                didCompleteEditing = true;
                Navigator.of(editorContext).pop(bytes);
              },
              onCloseEditor: (_) {
                if (!didCompleteEditing) {
                  Navigator.of(editorContext).maybePop();
                }
              },
            ),
            configs: _buildImageEditorConfigs(),
          );
        },
      ),
    );
  }

  ProImageEditorConfigs _buildImageEditorConfigs() {
    final BrandScale brand = context.appBrandScale;
    return ProImageEditorConfigs(
      theme: Theme.of(context).copyWith(
        colorScheme: Theme.of(
          context,
        ).colorScheme.copyWith(primary: brand.c500),
      ),
      i18n: const I18n(
        cancel: "취소",
        done: "완료",
        undo: "실행 취소",
        redo: "다시 실행",
        remove: "삭제",
        doneLoadingMsg: "사진을 저장하고 있어요",
        paintEditor: I18nPaintEditor(
          bottomNavigationBarText: "그리기",
          moveAndZoom: "이동/확대",
          freestyle: "자유선",
          arrow: "화살표",
          line: "선",
          rectangle: "사각형",
          circle: "원",
          dashLine: "점선",
          dashDotLine: "점선",
          blur: "블러",
          pixelate: "픽셀",
          lineWidth: "두께",
          eraser: "지우개",
          toggleFill: "채우기",
          changeOpacity: "투명도",
          color: "색상",
          opacity: "투명도",
          strokeWidth: "선 두께",
          fill: "채우기",
          back: "뒤로",
          cancel: "취소",
          done: "완료",
          undo: "실행 취소",
          redo: "다시 실행",
          smallScreenMoreTooltip: "더보기",
        ),
        textEditor: I18nTextEditor(
          bottomNavigationBarText: "텍스트",
          inputHintText: "텍스트를 입력하세요",
          back: "뒤로",
          done: "완료",
          textAlign: "정렬",
          fontScale: "크기",
          backgroundMode: "배경",
          smallScreenMoreTooltip: "더보기",
        ),
        cropRotateEditor: I18nCropRotateEditor(
          bottomNavigationBarText: "자르기",
          rotate: "회전",
          flip: "뒤집기",
          ratio: "비율",
          back: "뒤로",
          cancel: "취소",
          done: "완료",
          reset: "초기화",
          undo: "실행 취소",
          redo: "다시 실행",
          smallScreenMoreTooltip: "더보기",
        ),
        tuneEditor: I18nTuneEditor(
          bottomNavigationBarText: "보정",
          back: "뒤로",
          done: "완료",
          brightness: "밝기",
          contrast: "대비",
          saturation: "채도",
          exposure: "노출",
          hue: "색조",
          temperature: "온도",
          sharpness: "선명도",
          fade: "페이드",
          luminance: "휘도",
          undo: "실행 취소",
          redo: "다시 실행",
        ),
        filterEditor: I18nFilterEditor(
          bottomNavigationBarText: "필터",
          back: "뒤로",
          done: "완료",
          filters: I18nFilters(none: "없음"),
        ),
        blurEditor: I18nBlurEditor(
          bottomNavigationBarText: "블러",
          back: "뒤로",
          done: "완료",
        ),
        emojiEditor: I18nEmojiEditor(
          bottomNavigationBarText: "이모지",
          search: "검색",
          categoryRecent: "최근",
          categorySmileys: "표정",
          categoryAnimals: "동물",
          categoryFood: "음식",
          categoryActivities: "활동",
          categoryTravel: "여행",
          categoryObjects: "사물",
          categorySymbols: "기호",
          categoryFlags: "깃발",
        ),
        stickerEditor: I18nStickerEditor(bottomNavigationBarText: "스티커"),
      ),
      mainEditor: const MainEditorConfigs(
        tools: <SubEditorMode>[
          SubEditorMode.paint,
          SubEditorMode.text,
          SubEditorMode.cropRotate,
          SubEditorMode.tune,
          SubEditorMode.filter,
          SubEditorMode.blur,
          SubEditorMode.emoji,
          SubEditorMode.sticker,
        ],
      ),
      cropRotateEditor: const CropRotateEditorConfigs(
        initAspectRatio: 1,
        aspectRatios: <AspectRatioItem>[AspectRatioItem(text: "1:1", value: 1)],
        tools: <CropRotateTool>[
          CropRotateTool.rotate,
          CropRotateTool.flip,
          CropRotateTool.aspectRatio,
          CropRotateTool.reset,
        ],
      ),
    );
  }

  Future<void> _writeEditedImageBytes({
    required Uint8List editedBytes,
    required File output,
  }) async {
    final image_lib.Image? decoded = image_lib.decodeImage(editedBytes);
    if (decoded == null) {
      await output.writeAsBytes(editedBytes);
      return;
    }
    final image_lib.Image oriented = image_lib.bakeOrientation(decoded);
    await output.writeAsBytes(image_lib.encodeJpg(oriented, quality: 92));
  }

  Future<void> _copyImageWithBakedOrientation({
    required String sourcePath,
    required File output,
  }) async {
    final File source = File(sourcePath);
    final Uint8List? nativeCorrected =
        await FlutterImageCompress.compressWithFile(
          sourcePath,
          quality: 92,
          format: CompressFormat.jpeg,
          keepExif: false,
          autoCorrectionAngle: true,
        );
    if (nativeCorrected != null && nativeCorrected.isNotEmpty) {
      await output.writeAsBytes(nativeCorrected);
      return;
    }

    final Uint8List bytes = await source.readAsBytes();
    final image_lib.Image? decoded = image_lib.decodeImage(bytes);
    if (decoded == null) {
      await source.copy(output.path);
      return;
    }
    final image_lib.Image oriented = image_lib.bakeOrientation(decoded);
    await output.writeAsBytes(image_lib.encodeJpg(oriented, quality: 92));
  }

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, "0")}."
        "${date.month.toString().padLeft(2, "0")}."
        "${date.day.toString().padLeft(2, "0")}";
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      body: Column(
        children: <Widget>[
          const SizedBox(height: 49),
          SizedBox(
            height: 65,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    color: AppNeutralColors.grey900,
                    iconSize: AppSpacing.s24,
                    splashRadius: AppSpacing.s20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: AppSpacing.s24,
                      height: AppSpacing.s24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "버킷리스트 완료",
                      textAlign: TextAlign.center,
                      style: AppTypography.headingXSmall.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s24),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
              child: Column(
                children: <Widget>[
                  _AchievementImagePicker(
                    imagePath: _imagePath,
                    isSaving: _isSavingImage,
                    onTap: _pickImage,
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  _CompletionInfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _RequiredTitle(label: "제목"),
                        const SizedBox(height: AppSpacing.s6),
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMediumMedium.copyWith(
                            color: AppNeutralColors.grey900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Container(height: 1, color: AppNeutralColors.grey900),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  _CompletionInfoCard(
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      height: _noteController.text.trim().isEmpty ? 140 : null,
                      child: TextField(
                        controller: _noteController,
                        onChanged: (_) => setState(() {}),
                        minLines: 5,
                        maxLines: 12,
                        cursorColor: brand.c500,
                        style:
                            (_noteController.text.trim().isEmpty
                                    ? AppTypography.captionMedium
                                    : AppTypography.bodyLargeRegular)
                                .copyWith(
                                  color: _noteController.text.trim().isEmpty
                                      ? AppNeutralColors.grey300
                                      : AppNeutralColors.grey800,
                                ),
                        decoration: InputDecoration(
                          hintText: "버킷리스트를 완료한 소감을 써보세요",
                          hintStyle: AppTypography.captionMedium.copyWith(
                            color: AppNeutralColors.grey300,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(AppSpacing.s16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  _CompletionInfoCard(
                    onTap: widget.onChangeCategory == null
                        ? null
                        : () async {
                            final BucketCategorySelection? selected =
                                await widget.onChangeCategory!.call();
                            if (selected == null || !mounted) {
                              return;
                            }
                            setState(() {
                              _category = selected;
                            });
                          },
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _RequiredTitle(label: "카테고리"),
                              const SizedBox(height: AppSpacing.s2),
                              Text(
                                "나만의 카테고리를 설정해보세요.",
                                style: AppTypography.bodySmallMedium.copyWith(
                                  color: AppNeutralColors.grey500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _CategoryBadge(category: _category),
                        const SizedBox(width: AppSpacing.s4),
                        const Icon(
                          Icons.chevron_right,
                          size: AppSpacing.s24,
                          color: AppNeutralColors.grey900,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  _CompletionInfoCard(
                    onTap: widget.onChangeCompletedDate == null
                        ? null
                        : () async {
                            final DateTime? selected = await widget
                                .onChangeCompletedDate!
                                .call(_completedDate);
                            if (selected == null || !mounted) {
                              return;
                            }
                            setState(() {
                              _completedDate = selected;
                            });
                          },
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            "완료일 설정",
                            style: AppTypography.bodyMediumSemiBold.copyWith(
                              color: AppNeutralColors.grey900,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(_completedDate),
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
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(
              AppSpacing.s20,
              AppSpacing.s20,
              AppSpacing.s20,
              AppSpacing.s12,
            ),
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSave
                    ? () {
                        Navigator.of(context).pop(
                          BucketCompletionResult(
                            imagePath: _imagePath!.trim(),
                            note: _noteController.text.trim(),
                            completedDate: _completedDate,
                          ),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: brand.c500,
                  disabledBackgroundColor: Color.alphaBlend(
                    AppTransparentColors.light64,
                    brand.c500,
                  ),
                  foregroundColor: AppNeutralColors.white,
                  disabledForegroundColor: brand.c100,
                  textStyle: AppTypography.buttonLarge,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.s8),
                  ),
                ),
                child: const Text("저장하기"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BucketCompletionDetailScreen extends StatelessWidget {
  const BucketCompletionDetailScreen({
    super.key,
    required this.title,
    required this.category,
    required this.categoryColor,
    required this.completedDate,
    required this.imagePath,
    required this.note,
  });

  final String title;
  final String category;
  final Color categoryColor;
  final DateTime? completedDate;
  final String imagePath;
  final String note;

  String _formatDate(DateTime? date) {
    if (date == null) {
      return "-";
    }
    return "${date.year.toString().padLeft(4, "0")}."
        "${date.month.toString().padLeft(2, "0")}."
        "${date.day.toString().padLeft(2, "0")}";
  }

  Future<void> _openMenu(BuildContext context, Offset anchor) async {
    int? selectedIndex;
    final BucketCompletionDetailAction? action =
        await showGeneralDialog<BucketCompletionDetailAction>(
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
                final double menuWidth = AppDropdownTokens.menuStyle(
                  AppDropdownMenuSize.lg,
                ).width;
                final double top = anchor.dy + AppSpacing.s8;
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
                      BucketCompletionDetailAction value,
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
                                      BucketCompletionDetailAction.edit,
                                    ),
                                  ),
                                  AppDropdownItem(
                                    label: "삭제하기",
                                    state: selectedIndex == 1
                                        ? AppDropdownItemState.selected
                                        : AppDropdownItemState.defaultState,
                                    onTap: () => selectAndClose(
                                      1,
                                      BucketCompletionDetailAction.delete,
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
    if (action == null || !context.mounted) {
      return;
    }
    Navigator.of(context).pop(action);
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      body: Column(
        children: <Widget>[
          const SizedBox(height: 49),
          SizedBox(
            height: 65,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                      color: AppNeutralColors.grey900,
                      iconSize: AppSpacing.s24,
                      splashRadius: AppSpacing.s20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: AppSpacing.s24,
                        height: AppSpacing.s24,
                      ),
                    ),
                  ),
                  Text(
                    "자세히 보기",
                    textAlign: TextAlign.center,
                    style: AppTypography.headingXSmall.copyWith(
                      color: AppNeutralColors.grey900,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      onTapDown: (TapDownDetails details) {
                        _openMenu(context, details.globalPosition);
                      },
                      child: const SizedBox(
                        width: AppSpacing.s24,
                        height: AppSpacing.s24,
                        child: Icon(
                          Icons.more_vert,
                          size: AppSpacing.s24,
                          color: AppNeutralColors.grey900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20,
                0,
                AppSpacing.s20,
                AppSpacing.s24,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s20),
                decoration: BoxDecoration(
                  color: AppNeutralColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  boxShadow: AppElevation.level1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _AchievementImage(
                      imagePath: imagePath,
                      aspectRatio: 1,
                      radius: 12,
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headingMediumExtraBold.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: AppNeutralColors.grey500,
                        ),
                        const SizedBox(width: AppSpacing.s4),
                        Text(
                          _formatDate(completedDate),
                          style: AppTypography.bodySmallMedium.copyWith(
                            color: AppNeutralColors.grey500,
                          ),
                        ),
                        const Spacer(),
                        _PlainBadge(label: category, color: categoryColor),
                        const SizedBox(width: AppSpacing.s4),
                        const _PlainBadge(
                          label: "완료",
                          color: AppSemanticColors.success100,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Container(height: 1, color: AppNeutralColors.grey300),
                    const SizedBox(height: AppSpacing.s24),
                    Text(
                      note,
                      style: AppTypography.bodyLargeRegular.copyWith(
                        color: AppNeutralColors.grey800,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementImagePicker extends StatelessWidget {
  const _AchievementImagePicker({
    required this.imagePath,
    required this.isSaving,
    required this.onTap,
  });

  final String? imagePath;
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String path = (imagePath ?? "").trim();
    return GestureDetector(
      onTap: onTap,
      child: path.isEmpty
          ? Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppNeutralColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.s24),
                border: Border.all(
                  color: AppNeutralColors.grey300,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: AppNeutralColors.grey50,
                      shape: BoxShape.circle,
                    ),
                    child: isSaving
                        ? const Padding(
                            padding: EdgeInsets.all(AppSpacing.s16),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.add_photo_alternate,
                            size: AppSpacing.s24,
                            color: AppNeutralColors.grey300,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  Text(
                    "버킷리스트를 완료한 이미지를 추가해보세요",
                    style: AppTypography.captionMedium.copyWith(
                      color: AppNeutralColors.grey300,
                    ),
                  ),
                ],
              ),
            )
          : _AchievementImage(imagePath: path, height: 200, radius: 12),
    );
  }
}

class _AchievementImage extends StatelessWidget {
  const _AchievementImage({
    required this.imagePath,
    required this.radius,
    this.height,
    this.aspectRatio,
  });

  final String imagePath;
  final double radius;
  final double? height;
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    final File file = File(imagePath);
    final Widget image = file.existsSync()
        ? Image.file(file, fit: BoxFit.cover)
        : Container(
            color: AppNeutralColors.grey100,
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: AppNeutralColors.grey400,
            ),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: height == null
          ? AspectRatio(aspectRatio: aspectRatio ?? 1, child: image)
          : SizedBox(width: double.infinity, height: height, child: image),
    );
  }
}

class _CompletionInfoCard extends StatelessWidget {
  const _CompletionInfoCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.s16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: AppNeutralColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppElevation.level1,
        ),
        child: child,
      ),
    );
  }
}

class _RequiredTitle extends StatelessWidget {
  const _RequiredTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: AppTypography.bodyMediumSemiBold.copyWith(
            color: AppNeutralColors.grey900,
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        Text(
          "*",
          style: AppTypography.bodyMediumMedium.copyWith(color: brand.c500),
        ),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final BucketCategorySelection category;

  @override
  Widget build(BuildContext context) {
    return _PlainBadge(label: category.name, color: category.color);
  }
}

class _PlainBadge extends StatelessWidget {
  const _PlainBadge({required this.label, required this.color});

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
