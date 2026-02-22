import "package:flutter/material.dart";

import "../tokens/app_badge_tag_tokens.dart";
import "../tokens/app_card_tokens.dart";
import "../tokens/app_colors.dart";
import "../tokens/app_spacing.dart";

class AppDailyStreakCheckCard extends StatelessWidget {
  const AppDailyStreakCheckCard({
    super.key,
    this.title = "앗,😮\n어제 질문이 비어 있어요!",
    this.description = "어제의 질문도 작성하면 연속 기록을\n이어갈 수 있어요!",
    required this.weekdays,
    required this.states,
  }) : assert(weekdays.length == 7 && states.length == 7);

  final String title;
  final String description;
  final List<String> weekdays;
  final List<AppStreakStarState> states;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppCardTokens.dailyWidth,
      height: AppCardTokens.dailyHeight,
      padding: AppCardTokens.dailyPadding,
      decoration: BoxDecoration(
        color: AppCardTokens.background,
        borderRadius: AppCardTokens.dailyRadius,
        boxShadow: AppCardTokens.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppCardTokens.dailyTitleStyle.copyWith(
              color: AppNeutralColors.grey900,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            description,
            style: AppCardTokens.dailyBodyStyle.copyWith(
              color: AppNeutralColors.grey600,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(7, (int index) {
              return Column(
                children: <Widget>[
                  Text(
                    weekdays[index],
                    style: AppCardTokens.dailyWeekdayStyle.copyWith(
                      color: AppNeutralColors.grey900,
                    ),
                  ),
                  const SizedBox(height: AppCardTokens.weekItemGap),
                  _StreakStar(state: states[index]),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class AppRecordPreviewCard extends StatelessWidget {
  const AppRecordPreviewCard({
    super.key,
    this.dateLabel = "24일 수요일",
    required this.question,
    required this.body,
    this.tag = "#버킷리스트",
  });

  final String dateLabel;
  final String question;
  final String body;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppCardTokens.recordPreviewWidth,
      height: AppCardTokens.recordPreviewHeight,
      padding: AppCardTokens.recordPreviewPadding,
      decoration: BoxDecoration(
        color: AppCardTokens.background,
        borderRadius: AppCardTokens.recordPreviewRadius,
        boxShadow: AppCardTokens.shadow,
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.history,
                size: 24,
                color: AppNeutralColors.grey400,
              ),
              Expanded(
                child: Text(
                  dateLabel,
                  textAlign: TextAlign.center,
                  style: AppCardTokens.recordDateStyle.copyWith(
                    color: AppBrandThemes.blue.c500,
                  ),
                ),
              ),
              const Icon(
                Icons.more_horiz,
                size: 24,
                color: AppNeutralColors.grey400,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            question,
            textAlign: TextAlign.center,
            style: AppCardTokens.recordTitleStyle.copyWith(
              color: AppNeutralColors.grey900,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Expanded(
            child: Text(
              body,
              textAlign: TextAlign.center,
              overflow: TextOverflow.fade,
              style: AppCardTokens.recordBodyStyle.copyWith(
                color: AppNeutralColors.grey800,
              ),
            ),
          ),
          const Divider(color: AppNeutralColors.grey100),
          const SizedBox(height: AppSpacing.s8),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppBrandThemes.blue.c500,
              borderRadius: AppBucketTagTokens.radius,
            ),
            alignment: Alignment.center,
            child: Text(
              tag,
              style: AppBucketTagTokens.textStyle.copyWith(
                color: AppNeutralColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppInsightCard extends StatelessWidget {
  const AppInsightCard({
    super.key,
    this.title = "인사이트",
    required this.body,
    this.icon = Icons.lightbulb,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppCardTokens.insightWidth,
      padding: AppCardTokens.insightPadding,
      decoration: BoxDecoration(
        color: AppCardTokens.background,
        borderRadius: AppCardTokens.insightRadius,
        boxShadow: AppCardTokens.shadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: AppCardTokens.insightIconSize,
            height: AppCardTokens.insightIconSize,
            decoration: const BoxDecoration(
              color: Color(0xFFDCEBFA),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppBrandThemes.blue.c500),
          ),
          const SizedBox(width: AppCardTokens.insightGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppCardTokens.insightTitleStyle.copyWith(
                    color: AppNeutralColors.grey900,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  body,
                  style: AppCardTokens.insightBodyStyle.copyWith(
                    color: AppNeutralColors.grey900,
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

enum AppTodayRecordState { defaultState, none }

class AppTodayRecordCard extends StatelessWidget {
  const AppTodayRecordCard({
    super.key,
    this.state = AppTodayRecordState.defaultState,
    this.body = "",
    this.nameLabel = "익명의 호랑이님",
    this.emptyLabel = "오늘 첫 번째로 기록해보실래요?",
  });

  final AppTodayRecordState state;
  final String body;
  final String nameLabel;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final bool isNone = state == AppTodayRecordState.none;
    return Container(
      width: AppCardTokens.todayWidth,
      height: AppCardTokens.todayHeight,
      padding: AppCardTokens.todayPadding,
      decoration: BoxDecoration(
        color: AppCardTokens.background,
        borderRadius: AppCardTokens.todayRadius,
        boxShadow: AppCardTokens.shadow,
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: isNone
                  ? const Icon(
                      Icons.edit_note,
                      size: 64,
                      color: AppBrandThemes.blue.c300,
                    )
                  : Text(
                      body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppCardTokens.todayBodyStyle.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
            ),
          ),
          Align(
            alignment: isNone ? Alignment.center : Alignment.centerRight,
            child: Text(
              isNone ? emptyLabel : nameLabel,
              style: AppCardTokens.todayNameStyle.copyWith(
                color: isNone
                    ? AppCardTokens.todayEmptyCtaColor
                    : AppCardTokens.todayNameColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppTodayOtherRecordCard extends StatelessWidget {
  const AppTodayOtherRecordCard({
    super.key,
    required this.body,
    this.footer = "익명의 호랑이님 답변",
  });

  final String body;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppCardTokens.todayOtherWidth,
      height: AppCardTokens.todayOtherHeight,
      padding: AppCardTokens.todayOtherPadding,
      decoration: BoxDecoration(
        color: AppCardTokens.background,
        borderRadius: AppCardTokens.todayOtherRadius,
        boxShadow: AppCardTokens.shadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            body,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppCardTokens.todayOtherBodyStyle.copyWith(
              color: AppNeutralColors.grey900,
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            footer,
            textAlign: TextAlign.center,
            style: AppCardTokens.todayOtherNameStyle.copyWith(
              color: AppBrandThemes.blue.c500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakStar extends StatelessWidget {
  const _StreakStar({required this.state});

  final AppStreakStarState state;

  @override
  Widget build(BuildContext context) {
    final bool isMissed = state == AppStreakStarState.missed;
    final bool isSuccess = state == AppStreakStarState.success;
    return Container(
      width: AppCardTokens.weekStarSize,
      height: AppCardTokens.weekStarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppCardTokens.streakStarBackground(state),
        border: AppCardTokens.streakStarBorder(state),
      ),
      child: Center(
        child: isSuccess
            ? const Icon(Icons.star, size: 20, color: AppNeutralColors.white)
            : isMissed
            ? const Text(
                "?",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppSemanticColors.success500,
                ),
              )
            : null,
      ),
    );
  }
}
