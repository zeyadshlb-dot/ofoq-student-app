import 'package:flutter/material.dart';

class StudentHeatmap extends StatelessWidget {
  final List<dynamic> progressData;
  final bool isDark;
  final Color primaryColor;

  const StudentHeatmap({
    super.key,
    required this.progressData,
    this.isDark = false,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (progressData.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.08),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              'لا توجد سجلات تقدم لليوم',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // activityMap: "day-hour" -> count
    final activityMap = <String, int>{};
    for (var p in progressData) {
      final timestampStr = p['updated_at'] ?? p['UpdatedAt'];
      if (timestampStr == null) continue;
      final date = DateTime.parse(timestampStr);
      final day = date.weekday % 7; // Sunday=0, Monday=1, ...
      final hour = date.hour;
      final key = "$day-$hour";
      activityMap[key] = (activityMap[key] ?? 0) + 1;
    }

    int maxVal = 1;
    activityMap.forEach((_, v) {
      if (v > maxVal) maxVal = v;
    });

    final days = [
      "السبت",
      "الأحد",
      "الاثنين",
      "الثلاثاء",
      "الأربعاء",
      "الخميس",
      "الجمعة",
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222340) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.06),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'نمط نشاطك التعليمي',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1B2E),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Text(
                      'تحليل الأوقات التي تذاكر فيها عادةً',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [0.1, 0.3, 0.6, 0.9]
                    .map(
                      (op) => Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(op),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day Labels
                Column(
                  children: [
                    const SizedBox(height: 30),
                    ...days
                        .map(
                          (d) => Container(
                            height: 25,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 8,
                                color: isDark ? Colors.white54 : Colors.grey,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
                // Grid
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hours Labels
                    Row(
                      children: List.generate(
                        24,
                        (i) => Container(
                          width: 25,
                          alignment: Alignment.center,
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              "${i}:00",
                              style: TextStyle(
                                fontSize: 7,
                                color: isDark ? Colors.white38 : Colors.grey,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(
                      7,
                      (dIdx) => Row(
                        children: List.generate(24, (hIdx) {
                          final val = activityMap["$dIdx-$hIdx"] ?? 0;
                          final opacity = val == 0
                              ? (isDark ? 0.08 : 0.06)
                              : (val / maxVal) * 0.8 + 0.15;
                          return Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: val > 0
                                  ? primaryColor.withOpacity(opacity)
                                  : (isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.grey.withOpacity(0.06)),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          );
                        }),
                      ),
                    ).toList(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
