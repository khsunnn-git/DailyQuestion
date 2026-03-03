import "package:flutter/material.dart";

import "../../design_system/design_system.dart";

class MonthlyReportPreviewScreen extends StatelessWidget {
  const MonthlyReportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      appBar: AppBar(
        title: Text(
          "월간 리포트 미리보기",
          style: AppTypography.headingXSmall.copyWith(
            color: AppNeutralColors.grey900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: const <Widget>[
          _Section(
            title: "월 한 줄 요약",
            body: "의욕은 높았지만, 체력·집중 루틴이 흔들리며 감정 피로가 중반에 올라간 달",
          ),
          SizedBox(height: AppSpacing.s16),
          _Section(
            title: "데이터 스냅샷",
            lines: <String>[
              "응답률: 100% (31/31)",
              "평균 만족도: 6.7/10",
              "평균 에너지: 6.1/10",
              "평균 스트레스: 5.8/10",
              "태그 분포(Primary): 루틴 12, 감정 10, 성장 9, 관계 0",
              "키워드 TOP5: 피곤함, 카페인, 음악, 미룸, 산책",
            ],
          ),
          SizedBox(height: AppSpacing.s16),
          _Section(
            title: "축별 인사이트",
            lines: <String>[
              "감정: 초반(1~7일) 기대감이 높았고, 중반(14~22일) 피로·예민 키워드가 증가.",
              "루틴: 수면시간 불규칙, 아침 시작 루틴이 약함. 대신 출퇴근 음악은 안정장치로 작동.",
              "성장: 변화 의지는 강하지만 실행 단위가 커서 미루기 발생.",
              "관계: 1~31번 질문 구조상 관계 데이터가 적어 사회적 에너지 분석은 보류.",
            ],
          ),
          SizedBox(height: AppSpacing.s16),
          _Section(
            title: "대표 패턴",
            lines: <String>[
              "스트레스가 높은 날은 만족도 하락과 함께 미룸/야식/늦잠이 같이 등장.",
              "기분 좋았던 순간 답변의 공통점은 짧은 휴식 + 혼자 있는 시간.",
              "집중 방해 요인으로 알림, 숏폼, 멀티태스킹이 반복.",
            ],
          ),
          SizedBox(height: AppSpacing.s16),
          _Section(
            title: "해석",
            lines: <String>[
              "현재 문제는 동기 부족보다 에너지 관리 실패에 가까움.",
              "잘 되는 날의 조건이 명확함: 아침 고정 행동 1개 + 점심 이후 짧은 리셋.",
              "다음 달에는 목표를 줄이고 리듬을 먼저 고정하는 전략이 효율적.",
            ],
          ),
          SizedBox(height: AppSpacing.s16),
          _Section(
            title: "다음 달 실험 제안 (작게 2개)",
            lines: <String>[
              "평일 5일 중 3일, 기상 후 30분 내 물 + 스트레칭 5분 실행",
              "업무 시작 전 90분 알림 오프, 퇴근 후 숏폼 30분 제한",
            ],
          ),
          SizedBox(height: AppSpacing.s16),
          _Section(
            title: "다음 달 추적 지표",
            lines: <String>[
              "수면 시작 시각(주중 평균)",
              "미루기 체감 점수(1~10)",
              "스트레스 7점 이상인 날의 빈도",
              "기분 좋았던 순간 기록 횟수",
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.body, this.lines});

  final String title;
  final String? body;
  final List<String>? lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        borderRadius: AppRadius.br16,
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTypography.heading2XSmall.copyWith(
              color: AppNeutralColors.grey900,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          if (body != null)
            Text(
              body!,
              style: AppTypography.bodyMediumRegular.copyWith(
                color: AppNeutralColors.grey800,
              ),
            ),
          if (lines != null)
            ...lines!.map(
              (String item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: Text(
                  "• $item",
                  style: AppTypography.bodyMediumRegular.copyWith(
                    color: AppNeutralColors.grey800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
