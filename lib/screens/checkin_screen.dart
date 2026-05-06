import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/checkin_record_model.dart';
import '../models/participant_model.dart';
import '../providers/event_provider.dart';
import '../providers/participant_provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/qr_simulator_widget.dart';
import '../widgets/capacity_indicator.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _manualIdController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  ParticipantModel? _selectedParticipant;
  List<_CheckInFeedback> _feedbacks = [];
  bool _isManualProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualIdController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addFeedback(CheckInResult result, ParticipantModel? participant) {
    setState(() {
      _feedbacks.insert(
        0,
        _CheckInFeedback(
          result: result,
          participant: participant,
          timestamp: DateTime.now(),
        ),
      );
      if (_feedbacks.length > 5) {
        _feedbacks = _feedbacks.take(5).toList();
      }
    });
  }

  void _handleManualCheckIn() async {
    if (_isManualProcessing) return;
    final eventProvider = context.read<EventProvider>();
    final participantProvider = context.read<ParticipantProvider>();
    final connectivityProvider = context.read<ConnectivityProvider>();

    final activeEvent = eventProvider.activeEvent;
    if (activeEvent == null) {
      _showSnackBar(AppConstants.msgNoActiveEvent, isError: true);
      return;
    }

    final participantId = _selectedParticipant?.participantId ??
        _manualIdController.text.trim();

    if (participantId.isEmpty) {
      _showSnackBar('Please select or enter a participant ID', isError: true);
      return;
    }

    setState(() => _isManualProcessing = true);
    await Future.delayed(const Duration(milliseconds: 300));

    final result = participantProvider.checkIn(
      participantId,
      AppConstants.methodManual,
      activeEvent.id,
      activeEvent.maxCapacity,
      connectivityProvider.isOnline,
    );

    eventProvider.updateCheckedInCount(participantProvider.checkedInCount);

    final updatedParticipant =
        participantProvider.getParticipantById(participantId);

    setState(() {
      _isManualProcessing = false;
      _selectedParticipant = updatedParticipant;
    });

    _addFeedback(result, updatedParticipant);
    _showResultSnackBar(result, updatedParticipant);
  }

  void _showResultSnackBar(CheckInResult result, ParticipantModel? participant) {
    String message;
    Color color;
    IconData icon;

    switch (result) {
      case CheckInResult.success:
        final time = participant?.checkInTime != null
            ? DateFormat('h:mm a').format(participant!.checkInTime!)
            : '';
        message =
            '✅ Welcome, ${participant?.name}! Check-in recorded at $time';
        color = AppTheme.success;
        icon = Icons.check_circle_rounded;
        break;
      case CheckInResult.alreadyCheckedIn:
        final time = participant?.checkInTime != null
            ? DateFormat('h:mm a').format(participant!.checkInTime!)
            : '';
        message =
            '❌ ${participant?.name} is already checked in since $time';
        color = AppTheme.warning;
        icon = Icons.warning_rounded;
        break;
      case CheckInResult.capacityFull:
        message = AppConstants.msgCapacityFull;
        color = AppTheme.error;
        icon = Icons.block_rounded;
        break;
      case CheckInResult.participantNotFound:
        message = AppConstants.msgParticipantNotFound;
        color = AppTheme.error;
        icon = Icons.person_off_rounded;
        break;
      case CheckInResult.noActiveEvent:
        message = AppConstants.msgNoActiveEvent;
        color = AppTheme.error;
        icon = Icons.event_busy_rounded;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: GoogleFonts.inter(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final participantProvider = context.watch<ParticipantProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeEvent = eventProvider.activeEvent;

    return Column(
      children: [
        // Event Header Bar
        _buildEventHeader(activeEvent, eventProvider, participantProvider, isDark),

        // Tab Bar
        Container(
          color: isDark ? AppTheme.darkSurface : AppTheme.primary,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'QR Scan'),
              Tab(icon: Icon(Icons.edit_rounded), text: 'Manual Entry'),
            ],
            indicatorColor: AppTheme.secondary,
            labelColor: AppTheme.secondary,
            unselectedLabelColor: Colors.white60,
            dividerColor: Colors.transparent,
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildQRTab(eventProvider, participantProvider, isDark),
              _buildManualTab(participantProvider, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventHeader(
    eventModel,
    EventProvider ep,
    ParticipantProvider pp,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ep.hasActiveEvent
                ? ep.activeEvent!.name
                : 'No Event Selected',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          CapacityIndicator(
            current: pp.checkedInCount,
            max: ep.hasActiveEvent ? ep.activeEvent!.maxCapacity : 100,
          ),
        ],
      ),
    );
  }

  Widget _buildQRTab(
    EventProvider ep,
    ParticipantProvider pp,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        children: [
          // QR Simulator
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrSimulatorWidget(
              onCheckIn: (result, participant) {
                _addFeedback(result, participant);
                _showResultSnackBar(result, participant);
              },
            ),
          ),
          const SizedBox(height: 20),

          // Manual ID Override
          Container(
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
                  'Manual ID Entry',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualIdController,
                        decoration: InputDecoration(
                          labelText: 'Participant ID',
                          hintText: 'e.g. STU-001',
                          prefixIcon:
                              const Icon(Icons.badge_rounded),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final id = _manualIdController.text.trim();
                        if (id.isEmpty) {
                          _showSnackBar('Enter a participant ID', isError: true);
                          return;
                        }
                        final activeEvent = ep.activeEvent;
                        if (activeEvent == null) {
                          _showSnackBar(AppConstants.msgNoActiveEvent,
                              isError: true);
                          return;
                        }
                        final connectivityProvider =
                            context.read<ConnectivityProvider>();
                        final result = pp.checkIn(
                          id,
                          AppConstants.methodManual,
                          activeEvent.id,
                          activeEvent.maxCapacity,
                          connectivityProvider.isOnline,
                        );
                        ep.updateCheckedInCount(pp.checkedInCount);
                        final participant = pp.getParticipantById(id);
                        _addFeedback(result, participant);
                        _showResultSnackBar(result, participant);
                        _manualIdController.clear();
                      },
                      child: const Text('Validate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Recent Check-ins
          _buildRecentCheckIns(isDark),
        ],
      ),
    );
  }

  Widget _buildManualTab(ParticipantProvider pp, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search participants',
              hintText: 'Name, ID, or department...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Participant List
          ...() {
            final results = pp.searchParticipants(_searchController.text);
            if (results.isEmpty) {
              return [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48,
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFCBD5E0)),
                        const SizedBox(height: 12),
                        Text(
                          'No participants found',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFFA0AEC0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            }
            return results.map((p) => _buildParticipantSelectionTile(p, isDark));
          }(),
          const SizedBox(height: 20),

          // Selected Participant Detail Card
          if (_selectedParticipant != null)
            _buildSelectedParticipantCard(_selectedParticipant!, isDark),

          const SizedBox(height: 20),

          // Recent Check-ins
          _buildRecentCheckIns(isDark),
        ],
      ),
    );
  }

  Widget _buildParticipantSelectionTile(ParticipantModel p, bool isDark) {
    final isSelected = _selectedParticipant?.id == p.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedParticipant = p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.secondary.withOpacity(0.1)
              : (isDark ? AppTheme.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.secondary
                : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: p.isCheckedIn
                  ? AppTheme.success.withOpacity(0.2)
                  : AppTheme.secondary.withOpacity(0.15),
              radius: 22,
              child: Text(
                p.initials,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color:
                      p.isCheckedIn ? AppTheme.success : AppTheme.secondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.primary,
                    ),
                  ),
                  Text(
                    '${p.participantId} • ${p.department}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white54
                          : const Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
            if (p.isCheckedIn)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✓ In',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.success,
                  ),
                ),
              )
            else if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.secondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedParticipantCard(
      ParticipantModel p, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: p.isCheckedIn
              ? AppTheme.success.withOpacity(0.4)
              : AppTheme.secondary.withOpacity(0.3),
          width: 1.5,
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
              CircleAvatar(
                backgroundColor: AppTheme.secondary.withOpacity(0.15),
                radius: 28,
                child: Text(
                  p.initials,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.primary,
                      ),
                    ),
                    Text(
                      p.email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
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
          const SizedBox(height: 16),
          Row(
            children: [
              _DetailChip(
                icon: Icons.badge_rounded,
                label: p.participantId,
              ),
              const SizedBox(width: 8),
              _DetailChip(
                icon: Icons.school_rounded,
                label: p.department,
              ),
            ],
          ),
          if (p.isCheckedIn && p.checkInTime != null) ...[
            const SizedBox(height: 8),
            _DetailChip(
              icon: Icons.access_time_rounded,
              label:
                  'Checked in at ${DateFormat('hh:mm a').format(p.checkInTime!)}',
              color: AppTheme.success,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: p.isCheckedIn || _isManualProcessing
                  ? null
                  : _handleManualCheckIn,
              icon: _isManualProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                p.isCheckedIn
                    ? 'Already Checked In'
                    : (_isManualProcessing
                        ? 'Processing...'
                        : '✅ Check In'),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    p.isCheckedIn ? const Color(0xFFE2E8F0) : AppTheme.success,
                foregroundColor:
                    p.isCheckedIn ? const Color(0xFF718096) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCheckIns(bool isDark) {
    if (_feedbacks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Results',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        ..._feedbacks.map((fb) => _FeedbackCard(feedback: fb, isDark: isDark)),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _DetailChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.secondary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppTheme.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? AppTheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInFeedback {
  final CheckInResult result;
  final ParticipantModel? participant;
  final DateTime timestamp;

  _CheckInFeedback({
    required this.result,
    required this.participant,
    required this.timestamp,
  });
}

class _FeedbackCard extends StatelessWidget {
  final _CheckInFeedback feedback;
  final bool isDark;

  const _FeedbackCard({required this.feedback, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String message;

    switch (feedback.result) {
      case CheckInResult.success:
        color = AppTheme.success;
        icon = Icons.check_circle_rounded;
        message = feedback.participant != null
            ? '✅ Welcome, ${feedback.participant!.name}! Check-in recorded at ${DateFormat('h:mm a').format(feedback.participant!.checkInTime ?? DateTime.now())}'
            : '✅ Check-in successful';
        break;
      case CheckInResult.alreadyCheckedIn:
        color = AppTheme.warning;
        icon = Icons.warning_rounded;
        final t = feedback.participant?.checkInTime;
        message = feedback.participant != null
            ? '❌ ${feedback.participant!.name} is already checked in${t != null ? ' since ${DateFormat('h:mm a').format(t)}' : ''}'
            : '❌ Already checked in';
        break;
      case CheckInResult.capacityFull:
        color = AppTheme.error;
        icon = Icons.block_rounded;
        message = '❌ Event is at full capacity. Cannot check in.';
        break;
      case CheckInResult.participantNotFound:
        color = AppTheme.error;
        icon = Icons.person_off_rounded;
        message = '❌ Participant ID not found.';
        break;
      case CheckInResult.noActiveEvent:
        color = AppTheme.error;
        icon = Icons.event_busy_rounded;
        message = '❌ No active event selected.';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white : AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            DateFormat('h:mm:ss a').format(feedback.timestamp),
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? Colors.white38 : const Color(0xFFA0AEC0),
            ),
          ),
        ],
      ),
    );
  }
}
