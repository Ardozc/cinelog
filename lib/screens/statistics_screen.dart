import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

/// Istatistik sayfasi: donut (tur dagilimi), bar (aylik) ve line (haftalik) grafikler.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final genreDist = StorageService.genreDistribution;
    final monthly = StorageService.monthlyCompleted;
    final weekly = StorageService.weeklyActivity;
    final thisMonthCount = monthly.values.isNotEmpty ? monthly.values.last : 0;
    final highestRating = StorageService.highestRating;

    final palette = [
      primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.statusCompleted,
      AppColors.statusDropped
    ];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text('İstatistik', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),

          // Ozet satiri
          Row(
            children: [
              Expanded(
                  child: _MiniStat(
                      label: 'Bu Ay',
                      value: '$thisMonthCount',
                      primary: primary)),
              const SizedBox(width: 12),
              Expanded(
                  child: _MiniStat(
                      label: 'Ort. Puan',
                      value: StorageService.averageRating.toStringAsFixed(1),
                      primary: primary)),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'En Yüksek',
                  value: highestRating > 0
                      ? highestRating.toStringAsFixed(1)
                      : '-',
                  primary: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Donut - tur dagilimi
          _ChartCard(
            title: 'Tür Dağılımı',
            subtitle: 'En çok izlenen tür: ${StorageService.topGenre}',
            child: genreDist.isEmpty
                ? _EmptyChart()
                : SizedBox(
                    height: 180,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 42,
                              sections: genreDist.entries
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((e) {
                                final i = e.key;
                                final entry = e.value;
                                return PieChartSectionData(
                                  value: entry.value.toDouble(),
                                  color: palette[i % palette.length],
                                  title: '',
                                  radius: 26,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: genreDist.entries
                                .toList()
                                .asMap()
                                .entries
                                .take(5)
                                .map((e) {
                              final i = e.key;
                              final entry = e.value;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                            color: palette[i % palette.length],
                                            shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(entry.key,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                            overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 18),

          // Bar - aylik
          _ChartCard(
            title: 'Aylık İzleme',
            subtitle: 'Son 6 ayda tamamlanan yapımlar',
            child: monthly.values.every((v) => v == 0)
                ? _EmptyChart()
                : SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, meta) {
                                final labels = monthly.keys.toList();
                                if (v.toInt() >= labels.length) {
                                  return const SizedBox();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(labels[v.toInt()],
                                      style: TextStyle(
                                          fontSize: 11, color: textSecondary)),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups:
                            monthly.values.toList().asMap().entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.toDouble(),
                                color: primary,
                                width: 18,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 18),

          // Line - haftalik alışkanlık
          _ChartCard(
            title: 'İzleme Alışkanlığı',
            subtitle: 'Son 7 gün',
            child: weekly.values.every((v) => v == 0)
                ? _EmptyChart()
                : SizedBox(
                    height: 160,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, meta) {
                                final labels = weekly.keys.toList();
                                if (v.toInt() >= labels.length) {
                                  return const SizedBox();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(labels[v.toInt()],
                                      style: TextStyle(
                                          fontSize: 11, color: textSecondary)),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: weekly.values
                                .toList()
                                .asMap()
                                .entries
                                .map((e) => FlSpot(
                                    e.key.toDouble(), e.value.toDouble()))
                                .toList(),
                            isCurved: true,
                            color: primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                                show: true,
                                color: primary.withValues(alpha: 0.12)),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color primary;
  const _MiniStat(
      {required this.label, required this.value, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: primary)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _ChartCard(
      {required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
          child: Text('Henüz veri yok',
              style: Theme.of(context).textTheme.bodyMedium)),
    );
  }
}
