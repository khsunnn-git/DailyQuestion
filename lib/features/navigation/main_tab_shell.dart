import "dart:async";

import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "../auth/auth_service.dart";
import "../auth/login_screen.dart";
import "../bucket/bucket_list_screen.dart";
import "../home/home_screen.dart";
import "../home/my_records_screen.dart";
import "../more/more_settings_screen.dart";

class MainTabShell extends StatefulWidget {
  const MainTabShell({super.key, this.initialIndex = 0})
    : assert(initialIndex >= 0 && initialIndex < 4);

  final int initialIndex;

  static Route<void> route({int initialIndex = 0}) {
    return MaterialPageRoute<void>(
      builder: (_) => MainTabShell(initialIndex: initialIndex),
    );
  }

  static Future<void> replace(
    BuildContext context, {
    required int index,
    bool clearStack = false,
  }) {
    final Route<void> route = MainTabShell.route(initialIndex: index);
    if (clearStack) {
      return Navigator.of(
        context,
      ).pushAndRemoveUntil(route, (Route<dynamic> next) => false);
    }
    return Navigator.of(context).pushReplacement(route);
  }

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell> {
  late int _currentIndex = widget.initialIndex;
  StreamSubscription<Object?>? _authSubscription;
  bool _isResolvingAuthState = true;
  bool _showAccountConnectPrompt = false;

  late final List<Widget> _pages = <Widget>[
    const HomeScreen(showNavigationBar: false),
    const BucketListScreen(showNavigationBar: false),
    const MyRecordsScreen(showNavigationBar: false),
    const MoreSettingsScreen(showNavigationBar: false),
  ];

  @override
  void initState() {
    super.initState();
    _authSubscription = AuthService.instance.authStateChanges.listen((_) {
      _refreshAccountConnectPrompt();
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
    _refreshAccountConnectPrompt();
  }

  void _refreshAccountConnectPrompt() {
    if (_isResolvingAuthState) {
      if (!mounted) {
        _showAccountConnectPrompt = false;
        return;
      }
      if (_showAccountConnectPrompt) {
        setState(() {
          _showAccountConnectPrompt = false;
        });
      }
      return;
    }
    final bool shouldShow = !AuthService.instance.hasConnectedProvider;
    if (!mounted) {
      _showAccountConnectPrompt = shouldShow;
      return;
    }
    if (_showAccountConnectPrompt == shouldShow) {
      return;
    }
    setState(() {
      _showAccountConnectPrompt = shouldShow;
    });
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
    _refreshAccountConnectPrompt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppNavigationBar(
              currentIndex: _currentIndex,
              onTap: (int index) {
                if (index == _currentIndex) {
                  return;
                }
                setState(() {
                  _currentIndex = index;
                });
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
          if (_showAccountConnectPrompt)
            Positioned(
              right: AppSpacing.s20,
              bottom: AppNavigationBar.totalHeight(context) + 2,
              child: _AnimatedAccountConnectPrompt(onTap: _openAccountConnect),
            ),
        ],
      ),
    );
  }
}

class _AnimatedAccountConnectPrompt extends StatefulWidget {
  const _AnimatedAccountConnectPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_AnimatedAccountConnectPrompt> createState() =>
      _AnimatedAccountConnectPromptState();
}

class _AnimatedAccountConnectPromptState
    extends State<_AnimatedAccountConnectPrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);
  late final Animation<double> _offsetY = Tween<double>(
    begin: 0,
    end: -4,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetY,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: const AppSpeechBubble(
          text: "계정 연동하기",
          direction: AppBubbleDirection.down,
        ),
      ),
      builder: (BuildContext context, Widget? child) {
        return Transform.translate(
          offset: Offset(0, _offsetY.value),
          child: child,
        );
      },
    );
  }
}
