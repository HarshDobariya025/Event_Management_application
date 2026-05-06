import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../providers/participant_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/capacity_indicator.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppConstants.pulseDuration,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() => _lastUpdated = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final participantProvider = context.watch<ParticipantProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeEvent = eventProvider.activeEvent;

    final checkedIn = participantProvider.checkedInCount;
    final total = participantProvider.totalCount;
    final pending = participantProvider.pendingCount;
    final maxCap = activeEvent?.maxCapacity ?? 100;
    final remaining = maxCap - checkedIn;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Banner
          _buildStatusBanner(eventProvider, isDark),
          const SizedBox(height: 24),

          // Refresh Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last updated: ${DateFormat('h:mm:ss a').format(_lastUpdated)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : const Color(0xFFA0AEC0),
                ),
              ),
              IconButton.filled(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.secondary.withOpacity(0.15),
                  foregroundColor: AppTheme.secondary,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stat Cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            children: [
              StatCard(
                label: 'Total Registered',
                value: total,
                icon: Icons.group_rounded,
                color: AppTheme.secondary,
              ),
              StatCard(
                label: 'Checked In',
                value: checkedIn,
                icon: Icons.check_circle_rounded,
                color: AppTheme.success,
                subtitle: activeEvent != null
                    ? '${(checkedIn / maxCap * 100).toInt()}%'
                    : null,
              ),
              StatCard(
                label: 'Remaining Capacity',
                value: remaining.clamp(0, maxCap),
                icon: Icons.chair_rounded,
                color: AppTheme.warning,
              ),
              StatCard(
                label: 'Pending Check-in',
                value: pending,
                icon: Icons.pending_rounded,
                color: const Color(0xFF8338EC),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Capacity Bar
          _buildCapacitySection(checkedIn, maxCap, isDark),
          const SizedBox(height: 24),

          // Chart
          _buildChartSection(participantProvider, isDark),
          const SizedBox(height: 24),

          // Recent Activity Feed
          _buildActivityFeed(participantProvider, isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(EventProvider ep, bool isDark) {
    final status = ep.crowdStatus;
    final pct = ep.capacityPercentage;

    Color bannerColor;
    String bannerText;
    IconData bannerIcon;

    switch (status) {
      case 'critical':
        bannerColor = AppTheme.error;
        bannerText = '🔴 FULL / CRITICAL';
        bannerIcon = Icons.warning_rounded;
        break;
      case 'moderate':
        bannerColor = AppTheme.warning;
        bannerText = '⚠ MODERATE';
        bannerIcon = Icons.info_rounded;
        break;
      default:
        bannerColor = AppTheme.success;
        bannerText = '✅ SAFE';
        bannerIcon = Icons.check_circle_rounded;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bannerColor.withOpacity(0.85),
              bannerColor,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: bannerColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(bannerIcon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crowd Status',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    bannerText,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(pct * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                Text(
                  'capacity used',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacitySection(int checkedIn, int maxCap, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Venue Capacity',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          CapacityIndicator(
            current: checkedIn,
            max: maxCap,
            height: 20,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LegendDot(color: AppTheme.success, label: '< 70% Safe'),
              _LegendDot(color: AppTheme.warning, label: '70–90% Moderate'),
              _LegendDot(color: AppTheme.error, label: '> 90% Critical'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(ParticipantProvider pp, bool isDark) {
    final hourlyData = pp.checkInsByHour;

    // Build chart data for hours 8am to 8pm
    final spots = <BarChartGroupData>[];
    for (int h = 8; h <= 20; h++) {
      final count = hourlyData[h] ?? 0;
      spots.add(
        BarChartGroupData(
          x: h,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              gradient: LinearGradient(
                colors: [AppTheme.secondary, AppTheme.accent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Check-in Activity Timeline',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check-ins per hour (8 AM – 8 PM)',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white38 : const Color(0xFFA0AEC0),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: spots.isEmpty || spots.every((s) => s.barRods.first.toY == 0)
                ? Center(
                    child: Text(
                      'No check-in data yet',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFFA0AEC0),
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (hourlyData.values.isEmpty
                              ? 5
                              : hourlyData.values.reduce((a, b) => a > b ? a : b) +
                                  1)
                          .toDouble(),
                      barGroups: spots,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : const Color(0xFFE2E8F0),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              if (value % 1 != 0) return const SizedBox();
                              return Text(
                                '${value.toInt()}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.white38
                                      : const Color(0xFFA0AEC0),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final h = value.toInt();
                              if (h % 2 != 0) return const SizedBox();
                              final label = h < 12
                                  ? '${h}AM'
                                  : h == 12
                                      ? '12PM'
                                      : '${h - 12}PM';
                              return Text(
                                label,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.white38
                                      : const Color(0xFFA0AEC0),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final h = group.x.toInt();
                            final label = h < 12
                                ? '${h}AM'
                                : h == 12
                                    ? '12PM'
                                    : '${h - 12}PM';
                            return BarTooltipItem(
                              '$label\n${rod.toY.toInt()} check-ins',
                              GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed(ParticipantProvider pp, bool isDark) {
    final recent = pp.recentCheckIns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity Feed',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.primary,
          ),
        ),
        const SizedBox(height: 14),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No check-ins recorded yet',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white38 : const Color(0xFFA0AEC0),
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: recent.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 52),
              itemBuilder: (context, i) {
                final record = recent[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.success.withOpacity(0.15),
                    child: Text(
                      record.participantName.isNotEmpty
                          ? record.participantName
                              .split(' ')
                              .map((p) => p[0])
                              .take(2)
                              .join()
                              .toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                  title: Text(
                    record.participantName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.primary,
                    ),
                  ),
                  subtitle: Text(
                    record.participantId,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : const Color(0xFFA0AEC0),
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(record.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppTheme.primary,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            record.method == AppConstants.methodQR
                                ? Icons.qr_code_rounded
                                : Icons.edit_rounded,
                            size: 12,
                            color: AppTheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            record.method,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? Colors.white54 : const Color(0xFF718096),
          ),
        ),
      ],
    );
  }
}
