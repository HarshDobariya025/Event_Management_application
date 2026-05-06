import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models/event_model.dart';
import 'models/participant_model.dart';
import 'models/checkin_record_model.dart';
import 'providers/event_provider.dart';
import 'providers/participant_provider.dart';
import 'providers/connectivity_provider.dart';
import 'screens/home_screen.dart';
import 'screens/event_setup_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/logs_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EventFlowApp());
}

class EventFlowApp extends StatelessWidget {
  const EventFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => ParticipantProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _isDarkMode = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isDemoLoaded = prefs.getBool(AppConstants.keyIsDemoLoaded) ?? false;

    final eventProvider = context.read<EventProvider>();
    final participantProvider = context.read<ParticipantProvider>();

    if (isDemoLoaded) {
      // Load persisted data
      await eventProvider.loadFromPrefs();
      await participantProvider.loadFromPrefs();

      // Sync the count
      eventProvider.updateCheckedInCount(participantProvider.checkedInCount);
    } else {
      // Load demo data
      await _loadDemoData(eventProvider, participantProvider, prefs);
    }

    setState(() => _isInitialized = true);
  }

  Future<void> _loadDemoData(
    EventProvider eventProvider,
    ParticipantProvider participantProvider,
    SharedPreferences prefs,
  ) async {
    const uuid = Uuid();

    // Create demo event
    final eventId = uuid.v4();
    final now = DateTime.now();
    final demoEvent = EventModel(
      id: eventId,
      name: AppConstants.demoEventName,
      dateTime: now.add(const Duration(days: 1)),
      maxCapacity: AppConstants.demoEventCapacity,
      venue: AppConstants.demoEventVenue,
      description: AppConstants.demoEventDescription,
      createdAt: now,
    );
    eventProvider.addDemoEvent(demoEvent);

    // Create demo participants
    final participantData = [
      ['STU-001', 'Aarav Shah', 'aarav.shah@university.edu', 'CS Dept'],
      ['STU-002', 'Priya Patel', 'priya.patel@university.edu', 'IT Dept'],
      ['STU-003', 'Rohan Mehta', 'rohan.mehta@university.edu', 'EC Dept'],
      ['STU-004', 'Sneha Joshi', 'sneha.joshi@university.edu', 'ME Dept'],
      ['STU-005', 'Karan Desai', 'karan.desai@university.edu', 'CS Dept'],
      ['STU-006', 'Ananya Singh', 'ananya.singh@university.edu', 'IT Dept'],
      ['STU-007', 'Vivek Kumar', 'vivek.kumar@university.edu', 'CE Dept'],
      ['STU-008', 'Pooja Sharma', 'pooja.sharma@university.edu', 'CS Dept'],
      ['STU-009', 'Arjun Nair', 'arjun.nair@university.edu', 'EC Dept'],
      ['STU-010', 'Meera Iyer', 'meera.iyer@university.edu', 'IT Dept'],
      ['STU-011', 'Dev Patel', 'dev.patel@university.edu', 'ME Dept'],
      ['STU-012', 'Riya Gupta', 'riya.gupta@university.edu', 'CS Dept'],
      ['STU-013', 'Harsh Verma', 'harsh.verma@university.edu', 'CE Dept'],
      ['STU-014', 'Nisha Agarwal', 'nisha.agarwal@university.edu', 'IT Dept'],
      ['STU-015', 'Siddharth Rao', 'siddharth.rao@university.edu', 'EC Dept'],
      ['STU-016', 'Kavya Reddy', 'kavya.reddy@university.edu', 'ME Dept'],
      ['STU-017', 'Aditya Malhotra', 'aditya.malhotra@university.edu', 'CS Dept'],
      ['STU-018', 'Ishaan Bose', 'ishaan.bose@university.edu', 'CE Dept'],
      ['STU-019', 'Tanvi Choudhary', 'tanvi.choudhary@university.edu', 'IT Dept'],
      ['STU-020', 'Raj Khanna', 'raj.khanna@university.edu', 'EC Dept'],
    ];

    // First 8 are checked in
    final checkedInBase = now.subtract(const Duration(hours: 2));
    final methods = [
      AppConstants.methodQR,
      AppConstants.methodManual,
      AppConstants.methodQR,
      AppConstants.methodManual,
      AppConstants.methodQR,
      AppConstants.methodManual,
      AppConstants.methodQR,
      AppConstants.methodManual,
    ];

    final participants = <ParticipantModel>[];
    final records = <CheckInRecord>[];

    for (int i = 0; i < participantData.length; i++) {
      final data = participantData[i];
      final isCheckedIn = i < 8;
      final checkInTime = isCheckedIn
          ? checkedInBase.add(Duration(minutes: i * 12))
          : null;

      final participant = ParticipantModel(
        id: uuid.v4(),
        participantId: data[0],
        name: data[1],
        email: data[2],
        department: data[3],
        isCheckedIn: isCheckedIn,
        checkInTime: checkInTime,
        eventId: isCheckedIn ? eventId : null,
      );
      participants.add(participant);

      if (isCheckedIn) {
        final record = CheckInRecord(
          id: uuid.v4(),
          participantId: data[0],
          participantName: data[1],
          eventId: eventId,
          timestamp: checkInTime!,
          method: methods[i],
          isSynced: true,
        );
        records.add(record);
      }
    }

    participantProvider.addDemoParticipants(participants);
    participantProvider.addDemoCheckInRecords(records);
    eventProvider.updateCheckedInCount(participantProvider.checkedInCount);

    // Mark demo as loaded
    await prefs.setBool(AppConstants.keyIsDemoLoaded, true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routes: {
        AppConstants.routeSetup: (context) => const EventSetupScreen(),
      },
      home: _isInitialized
          ? MainScaffold(
              isDarkMode: _isDarkMode,
              onThemeToggle: () => setState(() => _isDarkMode = !_isDarkMode),
            )
          : const _SplashScreen(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const MainScaffold({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onTabChange: _switchTab),
      const CheckinScreen(),
      const DashboardScreen(),
      const LogsScreen(),
    ];
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  final List<_TabItem> _tabs = [
    _TabItem(icon: Icons.home_rounded, label: 'Home'),
    _TabItem(icon: Icons.qr_code_scanner_rounded, label: 'Check-in'),
    _TabItem(icon: Icons.bar_chart_rounded, label: 'Dashboard'),
    _TabItem(icon: Icons.list_alt_rounded, label: 'Logs'),
  ];

  final List<String> _titles = [
    'EventFlow',
    'Check-in',
    'Dashboard',
    'Logs & Search',
  ];

  @override
  Widget build(BuildContext context) {
    final connectivityProvider = context.watch<ConnectivityProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: AppTheme.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(_titles[_currentIndex]),
          ],
        ),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primary,
        actions: [
          // Online/Offline Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: connectivityProvider.isOnline
                        ? AppTheme.success
                        : AppTheme.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: connectivityProvider.isOnline
                            ? AppTheme.success.withOpacity(0.5)
                            : AppTheme.error.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  connectivityProvider.isOnline ? 'Online' : 'Offline',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Switch(
                  value: connectivityProvider.isOnline,
                  onChanged: (v) => connectivityProvider.setOnline(v),
                  activeColor: AppTheme.success,
                  inactiveThumbColor: AppTheme.error,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),

          // Theme Toggle
          IconButton(
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: Colors.white,
            ),
            tooltip: widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
            onPressed: widget.onThemeToggle,
          ),

          // Setup Event button
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded,
                  color: Colors.white),
              tooltip: 'Create Event',
              onPressed: () =>
                  Navigator.pushNamed(context, AppConstants.routeSetup),
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _switchTab,
          items: _tabs
              .map((tab) => BottomNavigationBarItem(
                    icon: Icon(tab.icon),
                    label: tab.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;

  const _TabItem({
    required this.icon,
    required this.label,
  });
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available_rounded,
                size: 64,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'EventFlow',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Smart Check-in & Crowd Manager',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppTheme.secondary,
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            const Text(
              'Initializing...',
              style: TextStyle(fontSize: 13, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}
