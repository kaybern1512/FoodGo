class RestaurantTimeUtils {
  static bool isRestaurantOpen(
    String openTime,
    String closeTime,
  ) {
    final now = DateTime.now();

    final open = openTime.split(':');
    final close = closeTime.split(':');

    final openDate = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(open[0]),
      int.parse(open[1]),
    );

    final closeDate = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(close[0]),
      int.parse(close[1]),
    );

    return !now.isBefore(openDate) && !now.isAfter(closeDate);
  }
}
