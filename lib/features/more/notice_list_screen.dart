import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";

import "../../design_system/design_system.dart";

class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  String? _expandedNoticeId;

  void _toggleExpanded(String noticeId) {
    setState(() {
      if (_expandedNoticeId == noticeId) {
        _expandedNoticeId = null;
        return;
      }
      _expandedNoticeId = noticeId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Scaffold(
      backgroundColor: brand.bg,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: StreamBuilder<List<_NoticeItem>>(
              stream: _NoticeRepository.instance.watchNotices(),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<_NoticeItem>> snapshot,
                  ) {
                    if (!snapshot.hasData) {
                      return const Center(child: AppLoadingIndicator());
                    }
                    final List<_NoticeItem> items = snapshot.data!;
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          "등록된 공지사항이 없어요.",
                          style: AppTypography.bodyMediumMedium.copyWith(
                            color: AppNeutralColors.grey500,
                          ),
                        ),
                      );
                    }
                    final String expandedId =
                        _expandedNoticeId ?? items.first.id;
                    return ListView.builder(
                      padding: const EdgeInsets.only(
                        top: 114,
                        bottom: AppSpacing.s24,
                      ),
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int index) {
                        final _NoticeItem item = items[index];
                        return _NoticeRow(
                          item: item,
                          expanded: expandedId == item.id,
                          onTap: () => _toggleExpanded(item.id),
                        );
                      },
                    );
                  },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: AppHeaderTokens.topInset,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s20),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: AppSpacing.s24,
                    height: AppSpacing.s24,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: AppSpacing.s24,
                        height: AppSpacing.s24,
                      ),
                      icon: const Icon(
                        Icons.arrow_back,
                        size: AppSpacing.s24,
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "공지사항",
                      textAlign: TextAlign.center,
                      style: AppTypography.headingXSmall.copyWith(
                        color: AppNeutralColors.grey900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s24, height: AppSpacing.s24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({
    required this.item,
    required this.expanded,
    required this.onTap,
  });

  final _NoticeItem item;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BrandScale brand = context.appBrandScale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            color: AppNeutralColors.white,
            constraints: const BoxConstraints(minHeight: 90),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppNeutralColors.grey100),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s2),
                        decoration: BoxDecoration(
                          color: brand.c50,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: brand.c400),
                        ),
                        child: Icon(
                          Icons.notifications_none,
                          size: 14,
                          color: brand.c500,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      Expanded(
                        child: Text(
                          "데일리퀘스천",
                          style: AppTypography.captionSmall.copyWith(
                            color: AppNeutralColors.grey500,
                          ),
                        ),
                      ),
                      Text(
                        item.date,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppNeutralColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    item.title,
                    style: AppTypography.bodyMediumSemiBold.copyWith(
                      color: AppNeutralColors.grey900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            color: brand.c50,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s40,
              vertical: AppSpacing.s20,
            ),
            child: Text(
              item.description ?? "",
              style: AppTypography.bodySmallMedium.copyWith(
                color: AppNeutralColors.grey900,
                height: 1.5,
              ),
            ),
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
    );
  }
}

class _NoticeItem {
  const _NoticeItem({
    required this.id,
    required this.title,
    required this.date,
    this.description,
    required this.sortMillis,
  });

  final String id;
  final String title;
  final String date;
  final String? description;
  final int sortMillis;
}

class _NoticeRepository {
  _NoticeRepository._();

  static final _NoticeRepository instance = _NoticeRepository._();

  Stream<List<_NoticeItem>> watchNotices() {
    return FirebaseFirestore.instance
        .collection("notices")
        .limit(100)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<_NoticeItem> items = snapshot.docs
              .map(_toItem)
              .whereType<_NoticeItem>()
              .toList(growable: false);
          items.sort((a, b) => b.sortMillis.compareTo(a.sortMillis));
          return items;
        });
  }

  _NoticeItem? _toItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data();
    final String title = "${data["title"] ?? ""}".trim();
    final bool isPublished = data["isPublished"] == true;
    if (!isPublished) {
      return null;
    }
    if (title.isEmpty) {
      return null;
    }
    final String description =
        "${data["body"] ?? data["description"] ?? data["content"] ?? ""}"
            .trim();
    final Timestamp? publishedAt = data["publishedAt"] as Timestamp?;
    final Timestamp? createdAt = data["createdAt"] as Timestamp?;
    final Timestamp? updatedAt = data["updatedAt"] as Timestamp?;
    final DateTime date =
        (publishedAt ?? updatedAt ?? createdAt ?? Timestamp.now()).toDate();
    final String dateText =
        "${date.year.toString().padLeft(4, "0")}."
        "${date.month.toString().padLeft(2, "0")}."
        "${date.day.toString().padLeft(2, "0")}";

    return _NoticeItem(
      id: doc.id,
      title: title,
      date: dateText,
      description: description.isEmpty ? null : description,
      sortMillis: date.millisecondsSinceEpoch,
    );
  }
}
