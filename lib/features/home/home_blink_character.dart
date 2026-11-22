import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "home_character_assets.dart";
import "home_fish_growth.dart";

/// 공룡·고양이·우파루파·뱁새 캐릭터의 움직임.
///
/// - 공통: 2~6레벨은 가끔 눈을 깜빡인다. (1레벨은 깜빡임 프레임이 없다)
/// - 공룡: 1레벨(알)은 가끔 좌우로 뒤뚱거린다.
/// - 고양이: 꼬리(level_N_tail)를 몸 뒤에 깔고, 엉덩이 쪽을 축으로 살랑살랑 흔든다.
/// - 뱁새: 위아래로 둥둥 뜬다. 4·5레벨은 몸/양쪽 날개가 나뉜 이미지로 날갯짓을 한다.
///   5레벨(날고 있는 모습)은 계속 날갯짓하며 떠다니고, 4레벨(날 준비)은 가끔 퍼덕인다.
/// - 우파루파: 물속에 떠 있는 것처럼 둥둥 떠다닌다.
///
/// 모든 프레임이 같은 1024×1024 캔버스라 겹쳐 그리면 위치가 맞는다.
/// 깜빡임 프레임(level_N_blink)은 기본 프레임에 눈 부분만 감은 눈으로 바꿔 끼운
/// 이미지라서, 깜빡일 때 몸은 전혀 움직이지 않는다.
class HomeBlinkCharacter extends StatefulWidget {
  const HomeBlinkCharacter({
    super.key,
    required this.characterType,
    required this.growthLevel,
    required this.size,
    this.fallbackFontSize = 72,
  });

  final HomeCharacterType characterType;
  final HomeFishGrowthLevel growthLevel;
  final double size;
  final double fallbackFontSize;

  static bool _hasLayeredFrames(
    HomeCharacterType type,
    HomeFishGrowthLevel level,
  ) {
    return level != HomeFishGrowthLevel.level1 &&
        (type == HomeCharacterType.cat || type == HomeCharacterType.parrotbill);
  }

  /// 몸과 양쪽 날개가 따로 나뉜 이미지가 있는지. (뱁새 4·5레벨, PSD 레이어 기준)
  static bool hasWingLayers(HomeCharacterType type, HomeFishGrowthLevel level) {
    return type == HomeCharacterType.parrotbill &&
        (level == HomeFishGrowthLevel.level4 ||
            level == HomeFishGrowthLevel.level5);
  }

  /// 날개를 뺀 몸 이미지 (눈 감은 버전 포함).
  static String wingBodyAssetFor(
    HomeCharacterType type,
    HomeFishGrowthLevel level, {
    bool blink = false,
  }) {
    final String suffix = blink ? "_blink" : "";
    return "${type.assetDirectory}/level_${level.number}_body$suffix.webp";
  }

  static String wingAssetFor(
    HomeCharacterType type,
    HomeFishGrowthLevel level, {
    required bool left,
  }) {
    final String side = left ? "left" : "right";
    return "${type.assetDirectory}/level_${level.number}_wing_$side.webp";
  }

  /// 날개 회전축 (어깨). 날개가 몸에 붙는 부분(몸과 겹치는 영역)의 중심값.
  /// 왼쪽 날개는 몸 뒤에, 오른쪽 날개는 몸 앞에 그린다.
  static Alignment wingPivotFor(HomeFishGrowthLevel level, {required bool left}) {
    final (double x, double y) = switch ((level, left)) {
      (HomeFishGrowthLevel.level4, true) => (0.329, 0.623),
      (HomeFishGrowthLevel.level4, false) => (0.603, 0.616),
      (_, true) => (0.346, 0.535),
      (_, false) => (0.603, 0.523),
    };
    return Alignment(x * 2 - 1, y * 2 - 1);
  }

  /// 평소에 보여주는 몸 프레임.
  static String bodyAssetFor(
    HomeCharacterType type,
    HomeFishGrowthLevel level,
  ) {
    if (hasWingLayers(type, level)) {
      return wingBodyAssetFor(type, level);
    }
    if (_hasLayeredFrames(type, level)) {
      return "${type.assetDirectory}/level_${level.number}_base.webp";
    }
    return HomeCharacterAssets.assetFor(type, level);
  }

  /// 몸 뒤에 까는 꼬리. 고양이 2~6레벨만 있다.
  static String? tailAssetFor(
    HomeCharacterType type,
    HomeFishGrowthLevel level,
  ) {
    if (type != HomeCharacterType.cat || level == HomeFishGrowthLevel.level1) {
      return null;
    }
    return "${type.assetDirectory}/level_${level.number}_tail.webp";
  }

  /// 고양이 꼬리 회전축 (캔버스 비율 0~1). 꼬리와 몸이 겹치는 영역(엉덩이)의 중심값.
  static Alignment catTailPivotFor(HomeFishGrowthLevel level) {
    final (double x, double y) = switch (level) {
      HomeFishGrowthLevel.level1 || HomeFishGrowthLevel.level2 => (0.634, 0.835),
      HomeFishGrowthLevel.level3 => (0.687, 0.525),
      HomeFishGrowthLevel.level4 => (0.648, 0.823),
      HomeFishGrowthLevel.level5 => (0.671, 0.601),
      HomeFishGrowthLevel.level6 => (0.720, 0.559),
    };
    return Alignment(x * 2 - 1, y * 2 - 1);
  }

  /// 공룡 알이 뒤뚱거릴 때 축 (알 밑바닥 가운데).
  static const Alignment dinoEggPivot = Alignment(-0.022, 0.746);

  @override
  State<HomeBlinkCharacter> createState() => _HomeBlinkCharacterState();
}

/// 캐릭터·레벨별 반복 움직임.
enum _LoopMotion { none, eggWobble, tailWag, hover, flyingHover, waterFloat }

_LoopMotion _loopMotionFor(HomeCharacterType type, HomeFishGrowthLevel level) {
  final bool isLevel1 = level == HomeFishGrowthLevel.level1;
  return switch (type) {
    HomeCharacterType.dino => isLevel1 ? _LoopMotion.eggWobble : _LoopMotion.none,
    HomeCharacterType.cat => isLevel1 ? _LoopMotion.none : _LoopMotion.tailWag,
    HomeCharacterType.parrotbill =>
      isLevel1
          ? _LoopMotion.none
          : level == HomeFishGrowthLevel.level5
          ? _LoopMotion.flyingHover
          : _LoopMotion.hover,
    HomeCharacterType.axolotl => _LoopMotion.waterFloat,
    _ => _LoopMotion.none,
  };
}

Duration _loopPeriodFor(_LoopMotion motion) {
  return switch (motion) {
    _LoopMotion.none => const Duration(seconds: 1),
    _LoopMotion.eggWobble => const Duration(milliseconds: 2800),
    // 꼬리는 천천히 살랑살랑 (한 번 왕복 약 2.2초)
    _LoopMotion.tailWag => const Duration(milliseconds: 2200),
    _LoopMotion.hover => const Duration(milliseconds: 2400),
    _LoopMotion.flyingHover => const Duration(milliseconds: 1500),
    _LoopMotion.waterFloat => const Duration(milliseconds: 3200),
  };
}

enum _BlinkFrame { body, blink }

class _HomeBlinkCharacterState extends State<HomeBlinkCharacter>
    with TickerProviderStateMixin {
  static const Duration _blinkHold = Duration(milliseconds: 130);
  static const Duration _doubleBlinkGap = Duration(milliseconds: 160);

  final math.Random _random = math.Random();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: _loopPeriodFor(_loopMotion),
  );

  /// 날갯짓. 5레벨은 0.34초마다 한 번씩 계속, 4레벨은 3초마다 세 번 퍼덕이고 쉰다.
  late final AnimationController _flap = AnimationController(vsync: this);
  static const Duration _flyingFlapPeriod = Duration(milliseconds: 340);
  static const Duration _readyFlapCycle = Duration(milliseconds: 3200);

  bool get _hasWings =>
      HomeBlinkCharacter.hasWingLayers(widget.characterType, widget.growthLevel);
  Timer? _motionTimer;
  _BlinkFrame _frame = _BlinkFrame.body;
  bool _motionEnabled = true;
  bool _didStartMotion = false;
  String? _precachedKey;

  _LoopMotion get _loopMotion =>
      _loopMotionFor(widget.characterType, widget.growthLevel);

  String? get _blinkAsset => _hasWings
      ? HomeBlinkCharacter.wingBodyAssetFor(
          widget.characterType,
          widget.growthLevel,
          blink: true,
        )
      : HomeCharacterAssets.blinkAssetFor(
          widget.characterType,
          widget.growthLevel,
        );


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool motionEnabled =
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (motionEnabled != _motionEnabled || !_didStartMotion) {
      _didStartMotion = true;
      _motionEnabled = motionEnabled;
      _syncMotion();
    }
    _precacheFrames();
  }

  @override
  void didUpdateWidget(covariant HomeBlinkCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.growthLevel != widget.growthLevel ||
        oldWidget.characterType != widget.characterType ||
        oldWidget.size != widget.size) {
      _frame = _BlinkFrame.body;
      _precacheFrames();
      _syncMotion();
    }
  }

  int _decodeSize(BuildContext context) {
    final double pixels = widget.size * MediaQuery.devicePixelRatioOf(context);
    return pixels.ceil().clamp(1, 1024);
  }

  void _precacheFrames() {
    final int decodeSize = _decodeSize(context);
    final String key =
        "${widget.characterType.name}-${widget.growthLevel.name}@$decodeSize";
    if (_precachedKey == key) {
      return;
    }
    _precachedKey = key;
    for (final String? asset in <String?>[
      HomeBlinkCharacter.bodyAssetFor(
        widget.characterType,
        widget.growthLevel,
      ),
      HomeBlinkCharacter.tailAssetFor(
        widget.characterType,
        widget.growthLevel,
      ),
      _blinkAsset,
      if (_hasWings) ...<String>[
        HomeBlinkCharacter.wingAssetFor(
          widget.characterType,
          widget.growthLevel,
          left: true,
        ),
        HomeBlinkCharacter.wingAssetFor(
          widget.characterType,
          widget.growthLevel,
          left: false,
        ),
      ],
    ]) {
      if (asset == null) {
        continue;
      }
      unawaited(
        precacheImage(
          ResizeImage(AssetImage(asset), width: decodeSize, height: decodeSize),
          context,
          onError: (_, _) {},
        ),
      );
    }
  }

  void _syncLoop() {
    final _LoopMotion motion = _loopMotion;
    _loop.duration = _loopPeriodFor(motion);
    if (_motionEnabled && motion != _LoopMotion.none) {
      _loop.repeat();
    } else {
      _loop
        ..stop()
        ..value = 0;
    }
    if (_motionEnabled && _hasWings) {
      _flap.duration = widget.growthLevel == HomeFishGrowthLevel.level5
          ? _flyingFlapPeriod
          : _readyFlapCycle;
      _flap.repeat();
    } else {
      _flap
        ..stop()
        ..value = 0;
    }
  }

  /// 날개를 들어 올린 각도(라디안). 0이면 원래 그림 그대로.
  double _wingLift(double t) {
    if (widget.growthLevel == HomeFishGrowthLevel.level5) {
      // 계속 날갯짓: 살짝 내렸다가(-0.12) 크게 올린다(+0.42).
      return 0.15 + 0.27 * math.sin(t * 2 * math.pi);
    }
    // 날 준비: 사이클 앞 25% 동안 세 번 퍼덕이고 나머지는 쉰다.
    const double activePortion = 0.25;
    if (t >= activePortion) {
      return 0;
    }
    final double p = t / activePortion;
    return 0.38 * (1 - math.cos(p * 3 * 2 * math.pi)) / 2;
  }

  void _syncMotion() {
    _syncLoop();
    _motionTimer?.cancel();
    _motionTimer = null;
    if (!_motionEnabled || _blinkAsset == null) {
      if (_frame != _BlinkFrame.body) {
        setState(() => _frame = _BlinkFrame.body);
      }
      return;
    }
    _scheduleNext();
  }

  void _scheduleNext() {
    _motionTimer?.cancel();
    // 2.4~4.8초마다 한 번 움직인다.
    final int waitMs = 2400 + _random.nextInt(2400);
    _motionTimer = Timer(Duration(milliseconds: waitMs), () async {
      await _hold(_BlinkFrame.blink, _blinkHold);
      if (mounted && _motionEnabled && _random.nextInt(4) == 0) {
        await Future<void>.delayed(_doubleBlinkGap);
        await _hold(_BlinkFrame.blink, _blinkHold);
      }
      if (mounted && _motionEnabled) {
        _scheduleNext();
      }
    });
  }

  Future<void> _hold(_BlinkFrame frame, Duration duration) async {
    if (!mounted) {
      return;
    }
    setState(() => _frame = frame);
    await Future<void>.delayed(duration);
    if (!mounted) {
      return;
    }
    setState(() => _frame = _BlinkFrame.body);
  }

  @override
  void dispose() {
    _motionTimer?.cancel();
    _loop.dispose();
    _flap.dispose();
    super.dispose();
  }

  /// 반복 움직임 한 프레임. 이미지 전체(꼬리 제외)에 적용할 이동·회전과 꼬리 회전각.
  ({Offset offset, double angle, Alignment pivot, double tailAngle}) _loopFrame(
    double t,
  ) {
    final double size = widget.size;
    final double wave = math.sin(t * 2 * math.pi);
    switch (_loopMotion) {
      case _LoopMotion.none:
        return (
          offset: Offset.zero,
          angle: 0,
          pivot: Alignment.center,
          tailAngle: 0,
        );
      case _LoopMotion.eggWobble:
        // 앞 40% 구간에 두 번 뒤뚱거리고(점점 잦아듦), 나머지는 가만히 있는다.
        const double activePortion = 0.4;
        final double progress = t / activePortion;
        final double angle = progress >= 1
            ? 0
            : math.sin(progress * 4 * math.pi) * 0.14 * (1 - progress);
        return (
          offset: Offset.zero,
          angle: angle,
          pivot: HomeBlinkCharacter.dinoEggPivot,
          tailAngle: 0,
        );
      case _LoopMotion.tailWag:
        return (
          offset: Offset.zero,
          angle: 0,
          pivot: Alignment.center,
          tailAngle: wave * 0.16,
        );
      case _LoopMotion.hover:
        return (
          offset: Offset(0, -size * 0.022 * (wave + 1) / 2),
          angle: 0,
          pivot: Alignment.center,
          tailAngle: 0,
        );
      case _LoopMotion.flyingHover:
        return (
          offset: Offset(0, size * 0.035 * wave),
          angle: math.sin(t * 2 * math.pi + math.pi / 2) * 0.025,
          pivot: Alignment.center,
          tailAngle: 0,
        );
      case _LoopMotion.waterFloat:
        return (
          offset: Offset(0, size * 0.03 * wave),
          angle: math.cos(t * 2 * math.pi) * 0.03,
          pivot: Alignment.center,
          tailAngle: 0,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final HomeCharacterType type = widget.characterType;
    final HomeFishGrowthLevel level = widget.growthLevel;
    final int decodeSize = _decodeSize(context);
    final String? tailAsset = HomeBlinkCharacter.tailAssetFor(type, level);
    final String bodyAsset = switch (_frame) {
      _BlinkFrame.blink =>
        _blinkAsset ?? HomeBlinkCharacter.bodyAssetFor(type, level),
      _BlinkFrame.body => HomeBlinkCharacter.bodyAssetFor(type, level),
    };
    final Widget body = Image.asset(
      bodyAsset,
      cacheWidth: decodeSize,
      cacheHeight: decodeSize,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, error, stackTrace) {
        return Center(
          child: AppEmojiText(
            type.fallbackEmoji,
            style: TextStyle(fontSize: widget.fallbackFontSize),
          ),
        );
      },
    );
    final Widget? tail = tailAsset == null
        ? null
        : Image.asset(
            tailAsset,
            cacheWidth: decodeSize,
            cacheHeight: decodeSize,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
          );
    final Alignment tailPivot = HomeBlinkCharacter.catTailPivotFor(level);
    Widget wingImage(bool left) => Image.asset(
      HomeBlinkCharacter.wingAssetFor(type, level, left: left),
      cacheWidth: decodeSize,
      cacheHeight: decodeSize,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
    );
    final Widget? leftWing = _hasWings ? wingImage(true) : null;
    final Widget? rightWing = _hasWings ? wingImage(false) : null;
    return SizedBox(
      key: ValueKey<String>("${type.name}-animated-${level.name}"),
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_loop, _flap]),
        builder: (BuildContext context, Widget? _) {
          final ({Offset offset, double angle, Alignment pivot, double tailAngle})
          frame = _loopFrame(_loop.value);
          final double wingLift = _hasWings ? _wingLift(_flap.value) : 0;
          return Transform.translate(
            offset: frame.offset,
            child: Transform.rotate(
              alignment: frame.pivot,
              angle: frame.angle,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // 왼쪽 날개는 몸통 뒤에서 움직인다.
                  if (leftWing != null)
                    Transform.rotate(
                      alignment: HomeBlinkCharacter.wingPivotFor(
                        level,
                        left: true,
                      ),
                      angle: wingLift,
                      child: leftWing,
                    ),
                  if (tail != null)
                    Transform.rotate(
                      alignment: tailPivot,
                      angle: frame.tailAngle,
                      child: tail,
                    ),
                  body,
                  // 왼쪽 날개는 시계 방향(+), 오른쪽 날개는 반시계 방향(-)으로 돌면 위로 올라간다.
                  if (rightWing != null)
                    Transform.rotate(
                      alignment: HomeBlinkCharacter.wingPivotFor(
                        level,
                        left: false,
                      ),
                      angle: -wingLift,
                      child: rightWing,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
