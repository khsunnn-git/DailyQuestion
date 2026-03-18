import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "../navigation/main_tab_shell.dart";
import "nickname_setup_screen.dart";

class NicknameCompleteScreen extends StatelessWidget {
  const NicknameCompleteScreen({
    super.key,
    required this.nickname,
    this.onStart,
  });

  static const double _contentWidth = 350;
  static const double _contentHeight = 414;
  static const double _contentGap = AppSpacing.s32;

  final String nickname;
  final void Function(BuildContext context)? onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppNeutralColors.white,
      body: Stack(
        children: <Widget>[
          Positioned(
            top: AppHeaderTokens.topInset,
            left: 0,
            right: 0,
            child: AppHeader(
              title: "닉네임 설정",
              trailing: null,
              onLeadingPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => const NicknameSetupScreen(),
                  ),
                );
              },
            ),
          ),
          Center(
            child: SizedBox(
              width: _contentWidth,
              height: _contentHeight,
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    height: 78,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: AppFontFamily.suit,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                              color: AppNeutralColors.grey900,
                            ),
                            children: <InlineSpan>[
                              TextSpan(
                                text: nickname,
                                style: const TextStyle(
                                  color: Color(0xFF017AF7),
                                ),
                              ),
                              const TextSpan(text: "님"),
                            ],
                          ),
                        ),
                        const Text(
                          "어서오세요!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppFontFamily.suit,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                            color: AppNeutralColors.grey900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _contentGap),
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: Image.asset(
                      "assets/images/signup/signup_complete_illustration.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: _contentGap),
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: const <Widget>[
                        Text(
                          "데일리퀘스천과 함께",
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyLargeMedium,
                        ),
                        Text(
                          "내일을 위한 하루를 쌓아보아요!",
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyLargeMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _contentGap),
                  SizedBox(
                    width: 152,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (onStart != null) {
                          onStart!(context);
                          return;
                        }
                        Navigator.of(
                          context,
                        ).pushReplacement(MainTabShell.route());
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        backgroundColor: const Color(0xFF017AF7),
                        foregroundColor: AppNeutralColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppInputTokens.radius,
                        ),
                        textStyle: AppTypography.buttonMedium,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s32,
                        ),
                      ),
                      child: const Text("기록 시작하기"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.s8,
            child: Center(
              child: SizedBox(
                width: 139,
                height: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppNeutralColors.grey900,
                    borderRadius: BorderRadius.all(Radius.circular(100)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
