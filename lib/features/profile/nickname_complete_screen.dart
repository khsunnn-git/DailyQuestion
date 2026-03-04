import "package:flutter/material.dart";

import "../../design_system/design_system.dart";
import "../home/home_screen.dart";
import "nickname_setup_screen.dart";

class NicknameCompleteScreen extends StatelessWidget {
  const NicknameCompleteScreen({
    super.key,
    required this.nickname,
    this.onStart,
  });

  final String nickname;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppNeutralColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            AppHeader(
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
            const SizedBox(height: AppSpacing.s64),
            SizedBox(
              width: double.infinity,
              child: Column(
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
                          style: const TextStyle(color: Color(0xFF017AF7)),
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
            const SizedBox(height: AppSpacing.s32),
            SizedBox(
              width: 130,
              height: 130,
              child: Image.asset(
                "assets/images/signup/signup_complete_illustration.png",
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppSpacing.s32),
            SizedBox(
              width: 350,
              child: Column(
                children: <Widget>[
                  const Text(
                    "데일리퀘스천과 함께",
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLargeMedium,
                  ),
                  const Text(
                    "내일을 위한 하루를 쌓아보아요!",
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLargeMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s32),
            SizedBox(
              width: 152,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (onStart != null) {
                    onStart!();
                    return;
                  }
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                  );
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
            const Spacer(),
            const SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.s8),
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
      ),
    );
  }
}
