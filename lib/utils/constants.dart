class AppConstants {
  // App Info
  static const String appName = 'EventFlow';
  static const String appTagline = 'Smart Check-in & Crowd Manager';
  static const String appVersion = '1.0.0';

  // Route Names
  static const String routeHome = '/home';
  static const String routeSetup = '/setup';
  static const String routeCheckin = '/checkin';
  static const String routeDashboard = '/dashboard';
  static const String routeLogs = '/logs';

  // Shared Preferences Keys
  static const String keyEvents = 'events_data';
  static const String keyParticipants = 'participants_data';
  static const String keyCheckInRecords = 'checkin_records_data';
  static const String keyOfflineQueue = 'offline_queue_data';
  static const String keyActiveEventId = 'active_event_id';
  static const String keyIsDemoLoaded = 'is_demo_loaded';

  // Demo Data
  static const String demoEventName = 'Annual Tech Fest 2025';
  static const String demoEventVenue = 'Main Auditorium, Block A';
  static const String demoEventDescription =
      'The flagship annual technology festival featuring project exhibitions, coding competitions, workshops, and keynote sessions by industry leaders.';
  static const int demoEventCapacity = 100;

  // Crowd Status Thresholds
  static const double moderateThreshold = 0.70;
  static const double criticalThreshold = 0.90;

  // Check-in Methods
  static const String methodQR = 'QR';
  static const String methodManual = 'Manual';

  // Messages
  static const String msgEventCreated = 'Event created successfully!';
  static const String msgCheckInSuccess = 'Check-in recorded successfully!';
  static const String msgAlreadyCheckedIn = 'Participant is already checked in.';
  static const String msgCapacityFull = 'Event is at full capacity. Cannot check in.';
  static const String msgParticipantNotFound = 'Participant not found.';
  static const String msgNoActiveEvent = 'No active event selected.';
  static const String msgSyncComplete = 'Offline records synced successfully!';

  // Animation Durations
  static const Duration scanAnimationDuration = Duration(milliseconds: 1500);
  static const Duration successAnimationDuration = Duration(milliseconds: 800);
  static const Duration transitionDuration = Duration(milliseconds: 300);
  static const Duration pulseDuration = Duration(milliseconds: 1200);

  // UI Constants
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const double pagePadding = 20.0;
  static const double cardPadding = 16.0;
  static const double sectionSpacing = 24.0;
}
