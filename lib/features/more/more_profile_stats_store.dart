import "more_profile_stats_store_io.dart"
    if (dart.library.js_interop) "more_profile_stats_store_web.dart"
    as store;

class MoreProfileStats {
  const MoreProfileStats({this.questionStreakDays, this.bucketCount});

  final int? questionStreakDays;
  final int? bucketCount;
}

Future<MoreProfileStats> loadMoreProfileStats() => store.loadMoreProfileStats();
