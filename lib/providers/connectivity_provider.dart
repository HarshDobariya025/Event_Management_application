import 'package:flutter/foundation.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _isSyncing = false;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  bool get isOffline => !_isOnline;

  void toggleConnectivity() {
    _isOnline = !_isOnline;
    notifyListeners();
  }

  void setOnline(bool value) {
    if (_isOnline != value) {
      _isOnline = value;
      notifyListeners();
    }
  }

  Future<void> simulateSync(VoidCallback onComplete) async {
    _isSyncing = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _isSyncing = false;
    _isOnline = true;
    notifyListeners();

    onComplete();
  }
}
