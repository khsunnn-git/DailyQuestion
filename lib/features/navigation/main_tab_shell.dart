import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
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

  late final List<Widget> _pages = <Widget>[
    const HomeScreen(showNavigationBar: false),
    const BucketListScreen(showNavigationBar: false),
    const MyRecordsScreen(showNavigationBar: false),
    const MoreSettingsScreen(showNavigationBar: false),
  ];

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
        ],
      ),
    );
  }
}
