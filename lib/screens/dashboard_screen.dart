import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../providers/participant_provider.dart';
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
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _lastUpdated = DateTime.now());

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EventProvider>();
    final pp = context.watch<ParticipantProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final checkedIn = pp.checkedInCount;
    final total = pp.totalCount;
    final pending = pp.pendingCount;
    final maxCap = ep.activeEvent?.maxCapacity ?? 100;
    final remaining = (maxCap - checkedIn).clamp(0, maxCap);
    final pct = maxCap > 0 ? (checkedIn / maxCap) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status Banner ──────────────────────────────────────
          _buildStatusBanner(ep, isDark),
          const SizedBox(height: 16),

          // ── Timestamp + Refresh ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 14,
                      color: isDark
                          ? Colors.white38
                          : const Color(0xFFA0AEC0)),
                  const SizedBox(width: 6),
                  Text(
                    'Updated ${DateFormat('h:mm:ss a').format(_lastUpdated)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white38
                          : const Color(0xFFA0AEC0),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _refresh,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      size: 18, color: AppTheme.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Stat Tiles ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Total',
                  value: total,
                  icon: Icons.group_rounded,
                  color: AppTheme.secondary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Checked In',
                  value: checkedIn,
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.success,
                  isDark: isDark,
                  badge:
                      '${(pct * 100).toInt()}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Pending',
                  value: pending,
                  icon: Icons.pending_rounded,
                  color: const Color(0xFF8338EC),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Remaining',
                  value: remaining,
                  icon: Icons.chair_rounded,
                  color: AppTheme.warning,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Capacity Section ───────────────────────────────────
          _buildCapacitySection(checkedIn, maxCap, isDark),
          const SizedBox(height: 24),

          // ── Bar Chart ─────────────────────────────────────────
          _buildChartSection(pp, isDark),
          const SizedBox(height: 24),

          // ── Activity Feed ─────────────────────────────────────
          _buildActivityFeed(pp, isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Status Banner ──────────────────────────────────────────────────────────
  Widget _buildStatusBanner(EventProvider ep, bool isDark) {
    final status = ep.crowdStatus;
    final pct = ep.capacityPercentage;

    Color color;
    String text;
    IconData icon;
    String emoji;

    switch (status) {
      case 'critical':
        color = AppTheme.error;
        text = 'CRITICAL';
        emoji = '🔴';
        icon = Icons.warning_amber_rounded;
        break;
      case 'moderate':
        color = AppTheme.warning;
        text = 'MODERATE';
        emoji = '⚠️';
        icon = Icons.info_outline_rounded;
        break;
      default:
        color = AppTheme.success;
        text = 'SAFE';
        emoji = '✅';
        icon = Icons.check_circle_outline_rounded;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _pulseAnimation.value, child: child),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.75)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
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
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crowd Status',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$emoji  $text',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
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
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                Text(
                  'capacity used',
                  style: GoogleFonts.inter(
                    fontSize: 11,
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

  // ─── Capacity Section ────────────────────────────────────────────────────────
  Widget _buildCapacitySection(int checkedIn, int maxCap, bool isDark) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stadium_rounded,
                  color: AppTheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Venue Capacity',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CapacityIndicator(current: checkedIn, max: maxCap, height: 18),
          const SizedBox(height: 14),
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

  // ─── Chart Section ───────────────────────────────────────────────────────────
  Widget _buildChartSection(ParticipantProvider pp, bool isDark) {
    final hourlyData = pp.checkInsByHour;
    final maxY = hourlyData.values.isEmpty
        ? 5.0
        : (hourlyData.values.reduce((a, b) => a > b ? a : b) + 1).toDouble();

    final spots = <BarChartGroupData>[];
    for (int h = 8; h <= 20; h++) {
      final count = hourlyData[h] ?? 0;
      spots.add(BarChartGroupData(
        x: h,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            gradient: LinearGradient(
              colors: [AppTheme.secondary, AppTheme.accent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 12,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ],
      ));
    }

    final hasData = spots.any((s) => s.barRods.first.toY > 0);

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: AppTheme.secondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Check-in Activity Timeline',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Check-ins per hour  (8 AM – 8 PM)',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? Colors.white38 : const Color(0xFFA0AEC0),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: !hasData
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart_rounded,
                            size: 40,
                            color: isDark
                                ? Colors.white12
                                : const Color(0xFFE2E8F0)),
                        const SizedBox(height: 8),
                        Text(
                          'No check-in data yet',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFFA0AEC0),
                          ),
                        ),
                      ],
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barGroups: spots,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : const Color(0xFFEEF2F7),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
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
                            reservedSize: 26,
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
                                  fontSize: 9,
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
                          getTooltipItem: (group, _, rod, __) {
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
                                  color: Colors.white),
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

  // ─── Activity Feed ───────────────────────────────────────────────────────────
  Widget _buildActivityFeed(ParticipantProvider pp, bool isDark) {
    final recent = pp.recentCheckIns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded,
                color: AppTheme.secondary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Recent Activity',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.primary,
              ),
            ),
            const Spacer(),
            if (recent.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${recent.length} entries',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          _Card(
            isDark: isDark,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.history_toggle_off_rounded,
                        size: 40,
                        color:
                            isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 8),
                    Text(
                      'No check-ins yet',
                      style: GoogleFonts.inter(
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFFA0AEC0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          _Card(
            isDark: isDark,
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: recent.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 52),
              itemBuilder: (context, i) {
                final record = recent[i];
                final initials = record.participantName
                    .split(' ')
                    .map((p) => p.isNotEmpty ? p[0] : '')
                    .take(2)
                    .join()
                    .toUpperCase();
                final isQR = record.method == AppConstants.methodQR;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.success.withOpacity(0.15),
                    child: Text(
                      initials.isEmpty ? '?' : initials,
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
                      color: isDark
                          ? Colors.white38
                          : const Color(0xFFA0AEC0),
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
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isQR
                              ? AppTheme.secondary.withOpacity(0.12)
                              : AppTheme.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isQR
                                  ? Icons.qr_code_rounded
                                  : Icons.edit_rounded,
                              size: 10,
                              color: isQR
                                  ? AppTheme.secondary
                                  : AppTheme.warning,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              record.method,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isQR
                                    ? AppTheme.secondary
                                    : AppTheme.warning,
                              ),
                            ),
                          ],
                        ),
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

// ─── Reusable card shell ─────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _Card({
    required this.isDark,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Compact stat tile (no GridView, no overflow) ────────────────────────────
class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final String? badge;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '$value',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge!,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : const Color(0xFF718096),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Legend dot ──────────────────────────────────────────────────────────────
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
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isDark ? Colors.white54 : const Color(0xFF718096),
          ),
        ),
      ],
    );
  }
}
