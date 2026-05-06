import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/participant_provider.dart';
import '../providers/connectivity_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final participantProvider = context.watch<ParticipantProvider>();
    final connectivityProvider = context.watch<ConnectivityProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            _buildHeroSection(isDark, eventProvider),
            const SizedBox(height: 28),

            // Stats Row
            _buildQuickStats(participantProvider, eventProvider, isDark),
            const SizedBox(height: 28),

            // Navigation Cards Grid
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            _buildNavigationGrid(context),
            const SizedBox(height: 28),

            // Active Event Card
            if (eventProvider.hasActiveEvent)
              _buildActiveEventCard(eventProvider, isDark),

            const SizedBox(height: 28),

            // Recent Activity
            if (participantProvider.recentCheckIns.isNotEmpty) ...[
              Text(
                'Recent Check-ins',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
              const SizedBox(height: 14),
              _buildRecentActivity(participantProvider, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDark, EventProvider eventProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, Color(0xFF1A3A5C)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.secondary.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppTheme.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    AppConstants.appTagline,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, thickness: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event_rounded, color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              Text(
                'Active Event: ',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
              Expanded(
                child: Text(
                  eventProvider.hasActiveEvent
                      ? eventProvider.activeEvent!.name
                      : 'No event selected',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: eventProvider.hasActiveEvent
                        ? AppTheme.secondary
                        : Colors.white38,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    ParticipantProvider pp,
    EventProvider ep,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: _QuickStatChip(
            icon: Icons.people_rounded,
            label: 'Checked In',
            value: '${pp.checkedInCount}',
            color: AppTheme.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatChip(
            icon: Icons.pending_rounded,
            label: 'Pending',
            value: '${pp.pendingCount}',
            color: AppTheme.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatChip(
            icon: Icons.group_rounded,
            label: 'Total',
            value: '${pp.totalCount}',
            color: AppTheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationGrid(BuildContext context) {
    final cards = [
      _NavCardData(
        icon: Icons.add_circle_outline_rounded,
        title: 'Create Event',
        subtitle: 'Set up a new event',
        gradient: [const Color(0xFF0D1B2A), const Color(0xFF1A3A5C)],
        iconColor: AppTheme.secondary,
        route: AppConstants.routeSetup,
      ),
      _NavCardData(
        icon: Icons.qr_code_scanner_rounded,
        title: 'Check-in',
        subtitle: 'Scan & verify attendees',
        gradient: [const Color(0xFF006994), AppTheme.secondary],
        iconColor: Colors.white,
        route: AppConstants.routeCheckin,
      ),
      _NavCardData(
        icon: Icons.bar_chart_rounded,
        title: 'Dashboard',
        subtitle: 'Live crowd monitoring',
        gradient: [const Color(0xFF1B4332), const Color(0xFF06D6A0)],
        iconColor: Colors.white,
        route: AppConstants.routeDashboard,
      ),
      _NavCardData(
        icon: Icons.list_alt_rounded,
        title: 'Logs',
        subtitle: 'Search & export records',
        gradient: [const Color(0xFF4A1942), const Color(0xFF8338EC)],
        iconColor: Colors.white,
        route: AppConstants.routeLogs,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: cards
          .map((card) => _NavigationCard(data: card))
          .toList(),
    );
  }

  Widget _buildActiveEventCard(EventProvider ep, bool isDark) {
    final event = ep.activeEvent!;
    final pct = ep.capacityPercentage;
    Color statusColor;
    String statusLabel;
    if (pct >= AppConstants.criticalThreshold) {
      statusColor = AppTheme.error;
      statusLabel = '🔴 CRITICAL';
    } else if (pct >= AppConstants.moderateThreshold) {
      statusColor = AppTheme.warning;
      statusLabel = '⚠ MODERATE';
    } else {
      statusColor = AppTheme.success;
      statusLabel = '✅ SAFE';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE2E8F0),
        ),
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
          Row(
            children: [
              Text(
                'Active Event',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            event.name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '📍 ${event.venue}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white54 : const Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 14),
          // Capacity bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${ep.currentCheckedInCount} / ${event.maxCapacity} checked in (${(pct * 100).toInt()}%)',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white54 : const Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(ParticipantProvider pp, bool isDark) {
    final recent = pp.recentCheckIns.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE2E8F0),
        ),
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
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.success,
                size: 20,
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
                  _formatTime(record.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: record.method == AppConstants.methodQR
                        ? AppTheme.secondary.withOpacity(0.1)
                        : AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    record.method,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: record.method == AppConstants.methodQR
                          ? AppTheme.secondary
                          : AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }
}

class _QuickStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? Colors.white54 : const Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color iconColor;
  final String route;

  const _NavCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.iconColor,
    required this.route,
  });
}

class _NavigationCard extends StatefulWidget {
  final _NavCardData data;

  const _NavigationCard({required this.data});

  @override
  State<_NavigationCard> createState() => _NavigationCardState();
}

class _NavigationCardState extends State<_NavigationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: ScaleTransition(
        scale: _hoverAnimation,
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, widget.data.route),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.data.gradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.data.gradient.last.withOpacity(
                      _isHovered ? 0.4 : 0.2),
                  blurRadius: _isHovered ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.data.icon,
                    color: widget.data.iconColor,
                    size: 24,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.data.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.data.subtitle,
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
        ),
      ),
    );
  }
}
