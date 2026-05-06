import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/participant_model.dart';
import '../models/checkin_record_model.dart';
import '../providers/participant_provider.dart';
import '../providers/event_provider.dart';
import '../providers/connectivity_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class QrSimulatorWidget extends StatefulWidget {
  final Function(CheckInResult result, ParticipantModel? participant) onCheckIn;

  const QrSimulatorWidget({super.key, required this.onCheckIn});

  @override
  State<QrSimulatorWidget> createState() => _QrSimulatorWidgetState();
}

class _QrSimulatorWidgetState extends State<QrSimulatorWidget>
    with TickerProviderStateMixin {
  bool _isScanning = false;
  ParticipantModel? _lastScannedParticipant;
  String _lastScannedId = '';
  CheckInResult? _lastResult;

  late AnimationController _scanAnimController;
  late AnimationController _borderController;
  late AnimationController _resultController;
  late Animation<double> _scanAnimation;
  late Animation<double> _borderAnimation;
  late Animation<double> _resultAnimation;
  late Animation<Color?> _borderColorAnimation;

  @override
  void initState() {
    super.initState();

    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );

    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _borderAnimation = Tween<double>(begin: 0, end: 1).animate(_borderController);
    _borderColorAnimation = ColorTween(
      begin: AppTheme.secondary,
      end: AppTheme.accent,
    ).animate(_borderController);

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _borderController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _simulateScan() async {
    if (_isScanning) return;

    final participantProvider = context.read<ParticipantProvider>();
    final eventProvider = context.read<EventProvider>();
    final connectivityProvider = context.read<ConnectivityProvider>();

    final uncheckedParticipant = participantProvider.getRandomUncheckedParticipant();

    setState(() {
      _isScanning = true;
      _lastResult = null;
    });

    _scanAnimController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    if (uncheckedParticipant == null) {
      setState(() {
        _isScanning = false;
        _lastScannedId = 'No unchecked participants';
        _lastResult = CheckInResult.participantNotFound;
      });
      widget.onCheckIn(CheckInResult.participantNotFound, null);
      _resultController.forward(from: 0);
      return;
    }

    final activeEvent = eventProvider.activeEvent;
    if (activeEvent == null) {
      setState(() {
        _isScanning = false;
        _lastResult = CheckInResult.noActiveEvent;
      });
      widget.onCheckIn(CheckInResult.noActiveEvent, null);
      _resultController.forward(from: 0);
      return;
    }

    final result = participantProvider.checkIn(
      uncheckedParticipant.participantId,
      AppConstants.methodQR,
      activeEvent.id,
      activeEvent.maxCapacity,
      connectivityProvider.isOnline,
    );

    final updatedParticipant = participantProvider.getParticipantById(
        uncheckedParticipant.participantId);

    eventProvider.updateCheckedInCount(participantProvider.checkedInCount);

    setState(() {
      _isScanning = false;
      _lastScannedParticipant = updatedParticipant;
      _lastScannedId = uncheckedParticipant.participantId;
      _lastResult = result;
    });

    _resultController.forward(from: 0);
    widget.onCheckIn(result, updatedParticipant);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // QR Display Area
        AnimatedBuilder(
          animation: _borderAnimation,
          builder: (context, child) {
            return Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _borderColorAnimation.value ?? AppTheme.secondary,
                  width: 3,
                ),
                color: isDark ? AppTheme.darkCard : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withOpacity(0.2 + 0.1 * _borderAnimation.value),
                    blurRadius: 20 + 10 * _borderAnimation.value,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_lastScannedParticipant != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: QrImageView(
                    data: _lastScannedParticipant!.participantId,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary,
                  ),
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      size: 80,
                      color: isDark
                          ? Colors.white24
                          : const Color(0xFFCBD5E0),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'QR Code will\nappear here',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFFA0AEC0),
                      ),
                    ),
                  ],
                ),

              // Scanning Overlay
              if (_isScanning)
                AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              value: _scanAnimation.value,
                              strokeWidth: 4,
                              color: AppTheme.secondary,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Scanning...',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Processing QR Code',
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // Result Overlay (success flash)
              if (_lastResult == CheckInResult.success && !_isScanning)
                AnimatedBuilder(
                  animation: _resultAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: (1 - _resultAnimation.value).clamp(0, 0.5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Scanned ID display
        if (_lastScannedId.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_rounded,
                    size: 16, color: AppTheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Scanned: ',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : const Color(0xFF718096),
                  ),
                ),
                Text(
                  _lastScannedId,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Scan Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isScanning ? null : _simulateScan,
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.camera_alt_rounded),
            label: Text(_isScanning ? 'Scanning...' : '📷 Simulate QR Scan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Randomly picks an unchecked participant and simulates scanning',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? Colors.white38 : const Color(0xFFA0AEC0),
          ),
        ),
      ],
    );
  }
}
