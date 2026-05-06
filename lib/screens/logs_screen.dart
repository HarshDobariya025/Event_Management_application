import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/participant_model.dart';
import '../models/checkin_record_model.dart';
import '../providers/participant_provider.dart';
import '../providers/event_provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/participant_tile.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'All';
  bool _isSyncing = false;

  final List<String> _filters = [
    'All',
    'Checked In',
    'Not Checked In',
    'QR Entry',
    'Manual Entry',
  ];

  List<ParticipantModel> _applyFilters(
    List<ParticipantModel> participants,
    List<CheckInRecord> records,
    String query,
    String filter,
  ) {
    var result = query.isEmpty
        ? participants
        : participants.where((p) {
            final lower = query.toLowerCase();
            return p.name.toLowerCase().contains(lower) ||
                p.participantId.toLowerCase().contains(lower) ||
                p.department.toLowerCase().contains(lower) ||
                p.email.toLowerCase().contains(lower);
          }).toList();

    switch (filter) {
      case 'Checked In':
        result = result.where((p) => p.isCheckedIn).toList();
        break;
      case 'Not Checked In':
        result = result.where((p) => !p.isCheckedIn).toList();
        break;
      case 'QR Entry':
        final qrIds = records
            .where((r) => r.method == AppConstants.methodQR)
            .map((r) => r.participantId)
            .toSet();
        result = result.where((p) => qrIds.contains(p.participantId)).toList();
        break;
      case 'Manual Entry':
        final manualIds = records
            .where((r) => r.method == AppConstants.methodManual)
            .map((r) => r.participantId)
            .toSet();
        result = result
            .where((p) => manualIds.contains(p.participantId))
            .toList();
        break;
    }
    return result;
  }

  String? _getMethodForParticipant(
      String participantId, List<CheckInRecord> records) {
    try {
      return records
          .lastWhere((r) => r.participantId == participantId)
          .method;
    } catch (_) {
      return null;
    }
  }

  Future<void> _simulateSync(
    ParticipantProvider pp,
    ConnectivityProvider cp,
  ) async {
    setState(() => _isSyncing = true);
    await pp.syncOfflineQueue();
    cp.setOnline(true);
    setState(() => _isSyncing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_done_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(AppConstants.msgSyncComplete, style: GoogleFonts.inter()),
            ],
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  void _showExportDialog(
      EventProvider ep, ParticipantProvider pp) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final event = ep.activeEvent;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppTheme.secondary),
              const SizedBox(width: 10),
              Text(
                'Event Report',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ReportRow(
                    label: 'Event',
                    value: event?.name ?? 'N/A'),
                _ReportRow(label: 'Venue', value: event?.venue ?? 'N/A'),
                _ReportRow(
                    label: 'Date',
                    value: event != null
                        ? DateFormat('MMM dd, yyyy').format(event.dateTime)
                        : 'N/A'),
                const Divider(),
                _ReportRow(
                    label: 'Total Registered',
                    value: '${pp.totalCount}'),
                _ReportRow(
                    label: 'Checked In',
                    value: '${pp.checkedInCount}'),
                _ReportRow(
                    label: 'Pending',
                    value: '${pp.pendingCount}'),
                _ReportRow(
                    label: 'Capacity',
                    value: '${event?.maxCapacity ?? 0}'),
                _ReportRow(
                    label: 'Occupancy',
                    value: event != null
                        ? '${(pp.checkedInCount / event.maxCapacity * 100).toInt()}%'
                        : 'N/A'),
                const Divider(),
                _ReportRow(
                    label: 'QR Check-ins',
                    value: '${pp.checkInRecords.where((r) => r.method == AppConstants.methodQR).length}'),
                _ReportRow(
                    label: 'Manual Check-ins',
                    value: '${pp.checkInRecords.where((r) => r.method == AppConstants.methodManual).length}'),
                _ReportRow(
                    label: 'Pending Sync',
                    value: '${pp.offlineQueueCount}'),
                const Divider(),
                _ReportRow(
                    label: 'Generated at',
                    value: DateFormat('MMM dd, yyyy h:mm a')
                        .format(DateTime.now())),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: GoogleFonts.inter()),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Report exported successfully! (simulated)',
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: AppTheme.success,
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text('Export', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _showParticipantDetail(
    BuildContext context,
    ParticipantModel p,
    String? method,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.secondary.withOpacity(0.15),
                    radius: 32,
                    child: Text(
                      p.initials,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.primary,
                          ),
                        ),
                        Text(
                          p.email,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: p.isCheckedIn
                          ? AppTheme.success.withOpacity(0.15)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p.isCheckedIn ? '✅ Checked In' : '⏳ Pending',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.isCheckedIn
                            ? AppTheme.success
                            : const Color(0xFF718096),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailItem(
                  icon: Icons.badge_rounded,
                  label: 'Participant ID',
                  value: p.participantId,
                  isDark: isDark),
              _DetailItem(
                  icon: Icons.school_rounded,
                  label: 'Department',
                  value: p.department,
                  isDark: isDark),
              _DetailItem(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  value: p.email,
                  isDark: isDark),
              if (p.isCheckedIn && p.checkInTime != null)
                _DetailItem(
                  icon: Icons.access_time_rounded,
                  label: 'Check-in Time',
                  value: DateFormat('EEEE, MMM dd – h:mm a')
                      .format(p.checkInTime!),
                  isDark: isDark,
                ),
              if (method != null)
                _DetailItem(
                  icon: method == AppConstants.methodQR
                      ? Icons.qr_code_rounded
                      : Icons.edit_rounded,
                  label: 'Entry Method',
                  value: method == AppConstants.methodQR
                      ? 'QR Code Scan'
                      : 'Manual Entry',
                  isDark: isDark,
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ParticipantProvider>();
    final ep = context.watch<EventProvider>();
    final cp = context.watch<ConnectivityProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _applyFilters(
      pp.participants.toList(),
      pp.checkInRecords.toList(),
      _searchController.text,
      _activeFilter,
    );

    return Column(
      children: [
        // Offline Banner
        if (cp.isOffline || pp.offlineQueueCount > 0)
          _buildOfflineBanner(pp, cp, isDark),

        // Search & Filters
        Container(
          color: isDark ? AppTheme.darkSurface : AppTheme.primary,
          padding:
              const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by name, ID, or department...',
                  hintStyle:
                      GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: Colors.white54),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.secondary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                onChanged: (v) => setState(() {}),
              ),
              const SizedBox(height: 10),

              // Filter Chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final filter = _filters[i];
                    final isActive = _activeFilter == filter;
                    return GestureDetector(
                      onTap: () => setState(() => _activeFilter = filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.secondary
                              : Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? AppTheme.secondary
                                : Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          filter,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 56,
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFCBD5E0),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No participants found',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFFA0AEC0),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    final method = _getMethodForParticipant(
                        p.participantId, pp.checkInRecords.toList());
                    return ParticipantTile(
                      participant: p,
                      method: method,
                      onTap: () => _showParticipantDetail(
                          context, p, method, isDark),
                    );
                  },
                ),
        ),

        // Footer
        _buildFooter(pp, ep, cp, isDark),
      ],
    );
  }

  Widget _buildOfflineBanner(
    ParticipantProvider pp,
    ConnectivityProvider cp,
    bool isDark,
  ) {
    return Container(
      color: AppTheme.error.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const _BlinkingDot(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cp.isOffline
                  ? 'Offline Mode — ${pp.offlineQueueCount} entries pending sync'
                  : '${pp.offlineQueueCount} entries pending sync',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          if (pp.offlineQueueCount > 0)
            TextButton.icon(
              onPressed: _isSyncing
                  ? null
                  : () => _simulateSync(pp, cp),
              icon: _isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                _isSyncing ? 'Syncing...' : '🔄 Sync Now',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    ParticipantProvider pp,
    EventProvider ep,
    ConnectivityProvider cp,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _FooterStat(
                    label: 'Total', value: pp.totalCount, color: AppTheme.secondary),
                const SizedBox(width: 16),
                _FooterStat(
                    label: 'In', value: pp.checkedInCount, color: AppTheme.success),
                const SizedBox(width: 16),
                _FooterStat(
                    label: 'Pending', value: pp.pendingCount, color: AppTheme.warning),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showExportDialog(ep, pp),
            icon: const Icon(Icons.bar_chart_rounded, size: 18),
            label: Text('Export Report', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _FooterStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? Colors.white38 : const Color(0xFFA0AEC0),
          ),
        ),
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReportRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white54 : const Color(0xFF718096),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18,
              color: isDark ? Colors.white38 : const Color(0xFFA0AEC0)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : const Color(0xFFA0AEC0),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
