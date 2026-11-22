import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "home_fish_growth.dart";

/// 백구 캐릭터: 꼬리를 살랑살랑 흔들고, 가끔 눈을 깜빡인다.
///
/// 레이어 순서는 꼬리(뒤) → 몸(앞)이다. 원본 합성 이미지에서 꼬리 일부가
/// 몸에 가려져 있으므로, 몸에 가려지는 부분의 중심을 회전축으로 잡았다.
/// 세 프레임 모두 같은 1024×1024 캔버스라 그대로 겹치면 위치가 맞는다.
class HomeDogCharacter extends StatefulWidget {
  const HomeDogCharacter({
    super.key,
    required this.growthLevel,
    required this.size,
    this.fallbackFontSize = 72,
  });

  final HomeFishGrowthLevel growthLevel;
  final double size;
  final double fallbackFontSize;

  static String baseAssetFor(HomeFishGrowthLevel level) =>
      "$_dir/level_${level.number}_base.webp";
  static String blinkAssetFor(HomeFishGrowthLevel level) =>
      "$_dir/level_${level.number}_blink.webp";
  static String tailAssetFor(HomeFishGrowthLevel level) =>
      "$_dir/level_${level.number}_tail.webp";

  static const String _dir = "assets/images/home/characters/dog";

  /// 꼬리 회전축 (캔버스 비율 0~1). 꼬리와 몸이 겹치는 영역의 중심값.
  static Alignment tailPivotFor(HomeFishGrowthLevel level) {
    final (double x, double y) = switch (level) {
      HomeFishGrowthLevel.level1 => (0.641, 0.811),
      HomeFishGrowthLevel.level2 => (0.639, 0.801),
      HomeFishGrowthLevel.level3 => (0.638, 0.640),
      HomeFishGrowthLevel.level4 => (0.634, 0.706),
      HomeFishGrowthLevel.level5 => (0.624, 0.709),
      HomeFishGrowthLevel.level6 => (0.628, 0.761),
    };
    return Alignment(x * 2 - 1, y * 2 - 1);
  }

  /// 꼬리 최대 회전각(라디안). 작은 꼬리는 조금 더 크게 흔든다.
  static double tailMaxAngleFor(HomeFishGrowthLevel level) {
    return switch (level) {
      HomeFishGrowthLevel.level1 || HomeFishGrowthLevel.level2 => 0.24,
      HomeFishGrowthLevel.level3 || HomeFishGrowthLevel.level4 => 0.20,
      HomeFishGrowthLevel.level5 || HomeFishGrowthLevel.level6 => 0.17,
    };
  }

  @override
  State<HomeDogCharacter> createState() => _HomeDogCharacterState();
}

class _HomeDogCharacterState extends State<HomeDogCharacter>
    with SingleTickerProviderStateMixin {
  static const Duration _wagHalfPeriod = Duration(milliseconds: 420);
  static const Duration _blinkHold = Duration(milliseconds: 130);
  static const Duration _doubleBlinkGap = Duration(milliseconds: 160);

  late final AnimationController _wagController;
  late final Animation<double> _wag;
  final math.Random _random = math.Random();
  Timer? _blinkTimer;
  bool _isBlinking = false;
  bool _motionEnabled = true;
  String? _precachedKey;

  @override
  void initState() {
    super.initState();
    _wagController = AnimationController(vsync: this, duration: _wagHalfPeriod);
    _wag = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _wagController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool motionEnabled =
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (motionEnabled != _motionEnabled || !_wagController.isAnimating) {
      _motionEnabled = motionEnabled;
      _syncMotion();
    }
    _precacheFrames();
  }

  @override
  void didUpdateWidget(covariant HomeDogCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.growthLevel != widget.growthLevel ||
        oldWidget.size != widget.size) {
      _precacheFrames();
    }
  }

  /// 1024px 원본을 화면에 보이는 크기로 줄여 읽는다 (장당 메모리 약 4MB → 수백 KB).
  int _decodeSize(BuildContext context) {
    final double pixels = widget.size * MediaQuery.devicePixelRatioOf(context);
    return pixels.ceil().clamp(1, 1024);
  }

  void _precacheFrames() {
    final int decodeSize = _decodeSize(context);
    final String key = "${widget.growthLevel.name}@$decodeSize";
    if (_precachedKey == key) {
      return;
    }
    _precachedKey = key;
    // 첫 깜빡임 때 이미지가 늦게 떠서 번쩍이는 것을 막는다.
    // Image.asset(cacheWidth/cacheHeight)과 같은 키가 되도록 ResizeImage로 미리 읽는다.
    for (final String asset in <String>[
      HomeDogCharacter.baseAssetFor(widget.growthLevel),
      HomeDogCharacter.blinkAssetFor(widget.growthLevel),
      HomeDogCharacter.tailAssetFor(widget.growthLevel),
    ]) {
      unawaited(
        precacheImage(
          ResizeImage(AssetImage(asset), width: decodeSize, height: decodeSize),
          context,
          onError: (_, _) {},
        ),
      );
    }
  }

  void _syncMotion() {
    if (_motionEnabled) {
      _wagController.repeat(reverse: true);
      _scheduleBlink();
    } else {
      _wagController
        ..stop()
        ..value = 0.5;
      _blinkTimer?.cancel();
      _isBlinking = false;
    }
  }

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    // 2.4~4.8초마다 한 번, 4번 중 1번은 두 번 연속 깜빡인다.
    final int waitMs = 2400 + _random.nextInt(2400);
    _blinkTimer = Timer(Duration(milliseconds: waitMs), () async {
      await _blinkOnce();
      if (mounted && _motionEnabled && _random.nextInt(4) == 0) {
        await Future<void>.delayed(_doubleBlinkGap);
        await _blinkOnce();
      }
      if (mounted && _motionEnabled) {
        _scheduleBlink();
      }
    });
  }

  Future<void> _blinkOnce() async {
    if (!mounted) {
      return;
    }
    setState(() => _isBlinking = true);
    await Future<void>.delayed(_blinkHold);
    if (!mounted) {
      return;
    }
    setState(() => _isBlinking = false);
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _wagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HomeFishGrowthLevel level = widget.growthLevel;
    final Alignment pivot = HomeDogCharacter.tailPivotFor(level);
    final double maxAngle = HomeDogCharacter.tailMaxAngleFor(level);
    final int decodeSize = _decodeSize(context);
    return SizedBox(
      key: ValueKey<String>("dog-animated-${level.name}"),
      width: widget.size,
      height: widget.size,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          AnimatedBuilder(
            animation: _wag,
            builder: (BuildContext context, Widget? child) {
              return Transform.rotate(
                alignment: pivot,
                angle: _wag.value * maxAngle,
                child: child,
              );
            },
            child: Image.asset(
              HomeDogCharacter.tailAssetFor(level),
              cacheWidth: decodeSize,
              cacheHeight: decodeSize,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          Image.asset(
            _isBlinking
                ? HomeDogCharacter.blinkAssetFor(level)
                : HomeDogCharacter.baseAssetFor(level),
            cacheWidth: decodeSize,
            cacheHeight: decodeSize,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, error, stackTrace) {
              return Center(
                child: AppEmojiText(
                  "🐶",
                  style: TextStyle(fontSize: widget.fallbackFontSize),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
