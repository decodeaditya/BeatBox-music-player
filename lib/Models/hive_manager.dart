// Models/hive_manager.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:boomplay/Models/songDataModel.dart'; // <--- NEW: Import SongDataModel

class HiveManager extends ChangeNotifier {
  // We'll initialize boxes in the init method, so make them late final
  late final Box _myBox;
  late final Box<SongData> _localSongsBox; // <--- NEW: Declare the songs box

  bool _isPreviouslyOpened = false;
  bool get isPreviouslyOpened => _isPreviouslyOpened;

  // New getter to expose the localSongsBox
  Box<SongData> get localSongsBox => _localSongsBox; // <--- NEW: Getter for songs box

  // --- NEW: Asynchronous initialization method ---
  Future<void> initHive() async {
    // These must be called BEFORE opening any boxes
    await Hive.initFlutter();
    Hive.registerAdapter(SongDataAdapter()); // Register your SongData adapter here!

    // Open your boxes
    _myBox = await Hive.openBox("myBox");
    _localSongsBox = await Hive.openBox<SongData>('localSongs'); // <--- NEW: Open songs box

    // Load initial status
    loadOnboardingStatus();
  }
  // ------------------------------------------------

  // Private constructor to enforce singleton pattern (optional, but common for managers)
  // HiveManager._();
  // static final HiveManager _instance = HiveManager._();
  // factory HiveManager() => _instance;


  // The rest of your existing methods remain mostly the same, but use _myBox
  void firstOpenApp() {
    _myBox.put("previouslyOpened", false);
    _isPreviouslyOpened = false;
  }

  void loadOnboardingStatus() {
    _isPreviouslyOpened = _myBox.get("previouslyOpened", defaultValue: false);
  }

  Future<void> markOnboardingComplete() async {
    await _myBox.put("previouslyOpened", true);
    _isPreviouslyOpened = true;
    notifyListeners();
    debugPrint("Onboarding marked as complete!");
  }
}