import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/participant_model.dart';
import '../utils/app_theme.dart';

class ParticipantTile extends StatelessWidget {
  final ParticipantModel participant;
  final String? method;
  final VoidCallback? onTap;
  final bool showStatus;
  final bool compact;

  const ParticipantTile({
    super.key,
    required this.participant,
    this.method,
    this.onTap,
    this.showStatus = true,
    this.compact = false,
  });

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF00B4D8),
      const Color(0xFF06D6A0),
      const Color(0xFFFFB703),
      const Color(0xFFEF476F),
      const Color(0xFF48CAE4),
      const Color(0xFF3A86FF),
      const Color(0xFF8338EC),
    ];
    int hash = 0;
    for (final char in name.codeUnits) {
      hash = (hash * 31 + char) % colors.length;
    }
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avatarColor = _avatarColor(participant.name);
    final isCheckedIn = participant.isCheckedIn;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: compact ? 10 : 14,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCheckedIn
                  ? AppTheme.success.withOpacity(0.3)
                  : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFE2E8F0)),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: compact ? 40 : 48,
                height: compact ? 40 : 48,
                decoration: BoxDecoration(
                  color: avatarColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: avatarColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    participant.initials,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            participant.name,
                            style: GoogleFonts.inter(
                              fontSize: compact ? 14 : 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showStatus)
                          _StatusBadge(isCheckedIn: isCheckedIn),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            participant.participantId,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.secondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          participant.department,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                    if (!compact && isCheckedIn && participant.checkInTime != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: AppTheme.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('h:mm a').format(participant.checkInTime!),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (method != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                method == 'QR'
                                    ? Icons.qr_code_scanner
                                    : Icons.edit_rounded,
                                size: 12,
                                color: isDark
                                    ? Colors.white38
                                    : const Color(0xFFA0AEC0),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                method!,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white38
                                      : const Color(0xFFA0AEC0),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white38 : const Color(0xFFA0AEC0),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isCheckedIn;

  const _StatusBadge({required this.isCheckedIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCheckedIn
            ? AppTheme.success.withOpacity(0.15)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isCheckedIn ? AppTheme.success : const Color(0xFFA0AEC0),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isCheckedIn ? 'Checked In' : 'Pending',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isCheckedIn ? AppTheme.success : const Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }
}
