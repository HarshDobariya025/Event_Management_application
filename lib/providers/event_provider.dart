import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../utils/constants.dart';

class EventProvider extends ChangeNotifier {
  final List<EventModel> _events = [];
  EventModel? _activeEvent;
  bool _isLoading = false;

  List<EventModel> get events => List.unmodifiable(_events);
  EventModel? get activeEvent => _activeEvent;
  bool get isLoading => _isLoading;
  bool get hasActiveEvent => _activeEvent != null;

  int get checkedInCount => 0; // Updated by ParticipantProvider
  int _currentCheckedInCount = 0;

  int get currentCheckedInCount => _currentCheckedInCount;

  void updateCheckedInCount(int count) {
    _currentCheckedInCount = count;
    notifyListeners();
  }

  int get remainingCapacity {
    if (_activeEvent == null) return 0;
    return _activeEvent!.maxCapacity - _currentCheckedInCount;
  }

  double get capacityPercentage {
    if (_activeEvent == null || _activeEvent!.maxCapacity == 0) return 0.0;
    return (_currentCheckedInCount / _activeEvent!.maxCapacity).clamp(0.0, 1.0);
  }

  String get crowdStatus {
    final pct = capacityPercentage;
    if (pct >= AppConstants.criticalThreshold) return 'critical';
    if (pct >= AppConstants.moderateThreshold) return 'moderate';
    return 'safe';
  }

  Future<void> loadFromPrefs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load events
      final eventsJson = prefs.getString(AppConstants.keyEvents);
      if (eventsJson != null) {
        final List<dynamic> decoded = jsonDecode(eventsJson);
        _events.clear();
        for (final item in decoded) {
          _events.add(EventModel.fromJson(item as Map<String, dynamic>));
        }
      }

      // Load active event ID
      final activeId = prefs.getString(AppConstants.keyActiveEventId);
      if (activeId != null) {
        try {
          _activeEvent = _events.firstWhere((e) => e.id == activeId);
        } catch (_) {
          _activeEvent = _events.isNotEmpty ? _events.first : null;
        }
      } else if (_events.isNotEmpty) {
        _activeEvent = _events.first;
      }
    } catch (e) {
      debugPrint('EventProvider.loadFromPrefs error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_events.map((e) => e.toJson()).toList());
      await prefs.setString(AppConstants.keyEvents, encoded);
      if (_activeEvent != null) {
        await prefs.setString(AppConstants.keyActiveEventId, _activeEvent!.id);
      }
    } catch (e) {
      debugPrint('EventProvider._saveToPrefs error: $e');
    }
  }

  void createEvent(EventModel event) {
    _events.add(event);
    _activeEvent = event;
    _saveToPrefs();
    notifyListeners();
  }

  void setActiveEvent(String eventId) {
    try {
      _activeEvent = _events.firstWhere((e) => e.id == eventId);
      _saveToPrefs();
      notifyListeners();
    } catch (_) {
      debugPrint('Event with id $eventId not found');
    }
  }

  void addDemoEvent(EventModel event) {
    if (!_events.any((e) => e.id == event.id)) {
      _events.add(event);
      _activeEvent = event;
      notifyListeners();
    }
  }

  String generateEventId() => const Uuid().v4();
}
