import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/participant_model.dart';
import '../models/checkin_record_model.dart';
import '../utils/constants.dart';

class ParticipantProvider extends ChangeNotifier {
  final List<ParticipantModel> _participants = [];
  final List<CheckInRecord> _checkInRecords = [];
  final List<CheckInRecord> _offlineQueue = [];
  bool _isLoading = false;

  List<ParticipantModel> get participants => List.unmodifiable(_participants);
  List<CheckInRecord> get checkInRecords => List.unmodifiable(_checkInRecords);
  List<CheckInRecord> get offlineQueue => List.unmodifiable(_offlineQueue);
  bool get isLoading => _isLoading;

  int get checkedInCount => _participants.where((p) => p.isCheckedIn).length;
  int get pendingCount => _participants.where((p) => !p.isCheckedIn).length;
  int get totalCount => _participants.length;
  int get offlineQueueCount => _offlineQueue.length;

  List<ParticipantModel> get checkedInParticipants =>
      _participants.where((p) => p.isCheckedIn).toList();

  List<CheckInRecord> get recentCheckIns {
    final sorted = List<CheckInRecord>.from(_checkInRecords)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(10).toList();
  }

  List<ParticipantModel> searchParticipants(String query) {
    if (query.trim().isEmpty) return List.unmodifiable(_participants);
    final lower = query.toLowerCase();
    return _participants.where((p) {
      return p.name.toLowerCase().contains(lower) ||
          p.participantId.toLowerCase().contains(lower) ||
          p.email.toLowerCase().contains(lower) ||
          p.department.toLowerCase().contains(lower);
    }).toList();
  }

  Map<int, int> get checkInsByHour {
    final Map<int, int> result = {};
    for (final record in _checkInRecords) {
      final hour = record.timestamp.hour;
      result[hour] = (result[hour] ?? 0) + 1;
    }
    return result;
  }

  Future<void> loadFromPrefs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      final participantsJson = prefs.getString(AppConstants.keyParticipants);
      if (participantsJson != null) {
        final List<dynamic> decoded = jsonDecode(participantsJson);
        _participants.clear();
        for (final item in decoded) {
          _participants.add(
              ParticipantModel.fromJson(item as Map<String, dynamic>));
        }
      }

      final recordsJson = prefs.getString(AppConstants.keyCheckInRecords);
      if (recordsJson != null) {
        final List<dynamic> decoded = jsonDecode(recordsJson);
        _checkInRecords.clear();
        for (final item in decoded) {
          _checkInRecords.add(
              CheckInRecord.fromJson(item as Map<String, dynamic>));
        }
      }

      final queueJson = prefs.getString(AppConstants.keyOfflineQueue);
      if (queueJson != null) {
        final List<dynamic> decoded = jsonDecode(queueJson);
        _offlineQueue.clear();
        for (final item in decoded) {
          _offlineQueue.add(
              CheckInRecord.fromJson(item as Map<String, dynamic>));
        }
      }
    } catch (e) {
      debugPrint('ParticipantProvider.loadFromPrefs error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          AppConstants.keyParticipants,
          jsonEncode(_participants.map((p) => p.toJson()).toList()));
      await prefs.setString(
          AppConstants.keyCheckInRecords,
          jsonEncode(_checkInRecords.map((r) => r.toJson()).toList()));
      await prefs.setString(
          AppConstants.keyOfflineQueue,
          jsonEncode(_offlineQueue.map((r) => r.toJson()).toList()));
    } catch (e) {
      debugPrint('ParticipantProvider._saveToPrefs error: $e');
    }
  }

  void addParticipant(ParticipantModel participant) {
    _participants.add(participant);
    _saveToPrefs();
    notifyListeners();
  }

  void addDemoParticipants(List<ParticipantModel> participants) {
    for (final p in participants) {
      if (!_participants.any((existing) => existing.id == p.id)) {
        _participants.add(p);
      }
    }
    notifyListeners();
  }

  void addDemoCheckInRecords(List<CheckInRecord> records) {
    for (final r in records) {
      if (!_checkInRecords.any((existing) => existing.id == r.id)) {
        _checkInRecords.add(r);
      }
    }
    notifyListeners();
  }

  CheckInResult checkIn(
    String participantId,
    String method,
    String eventId,
    int maxCapacity,
    bool isOnline,
  ) {
    // Find participant
    ParticipantModel? participant;
    try {
      participant = _participants.firstWhere(
        (p) => p.participantId.toUpperCase() == participantId.toUpperCase(),
      );
    } catch (_) {
      return CheckInResult.participantNotFound;
    }

    // Check if already checked in
    if (participant.isCheckedIn) {
      return CheckInResult.alreadyCheckedIn;
    }

    // Check capacity
    if (checkedInCount >= maxCapacity) {
      return CheckInResult.capacityFull;
    }

    // Perform check-in
    final now = DateTime.now();
    final index = _participants.indexOf(participant);
    _participants[index] = participant.copyWith(
      isCheckedIn: true,
      checkInTime: now,
      eventId: eventId,
    );

    final record = CheckInRecord(
      id: const Uuid().v4(),
      participantId: participant.participantId,
      participantName: participant.name,
      eventId: eventId,
      timestamp: now,
      method: method,
      isSynced: isOnline,
    );

    _checkInRecords.add(record);

    if (!isOnline) {
      _offlineQueue.add(record);
    }

    _saveToPrefs();
    notifyListeners();
    return CheckInResult.success;
  }

  ParticipantModel? getParticipantById(String participantId) {
    try {
      return _participants.firstWhere(
        (p) => p.participantId.toUpperCase() == participantId.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  ParticipantModel? getRandomUncheckedParticipant() {
    final unchecked = _participants.where((p) => !p.isCheckedIn).toList();
    if (unchecked.isEmpty) return null;
    final rand = Random();
    return unchecked[rand.nextInt(unchecked.length)];
  }

  Future<void> syncOfflineQueue() async {
    // Simulate sync delay
    await Future.delayed(const Duration(seconds: 2));

    for (final record in _offlineQueue) {
      final index = _checkInRecords.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _checkInRecords[index] = record.copyWith(isSynced: true);
      }
    }
    _offlineQueue.clear();
    await _saveToPrefs();
    notifyListeners();
  }

  void reset() {
    _participants.clear();
    _checkInRecords.clear();
    _offlineQueue.clear();
    notifyListeners();
  }
}
