import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import 'package:boomplay/Models/songDataModel.dart';

// NEW IMPORTS FOR HIVE
import 'package:boomplay/Models/hive_manager.dart'; // No longer strictly needed for SongProvider itself, but good to have if it still uses manager for something else.
import 'package:hive_flutter/hive_flutter.dart'; // Still needed for Box type

// Helper class for player position data (used by streams)
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  PositionData(this.position, this.bufferedPosition, this.duration);
}

// Main Song Provider - Manages music playback
class SongProvider extends ChangeNotifier {
  final player = AudioPlayer(); // Just Audio player instance

  // --- MODIFIED: _songsBox is now initialized directly in the constructor ---
  final Box<SongData> _songsBox; // No longer 'late', initialized via constructor
  // --------------------------------------------------------------------------

  // Music lists
  List _allSongs = []; // Comprehensive list of all songs
  List localPlaylist = []; // Songs saved locally/favorites (will be loaded from Hive)
  List _searchResults = []; // Results from online searches
  List finalSongsPlaylist = []; // The currently active playlist for playback

  // Player state variables
  bool isPlaying = false;
  bool isSongLoaded = false;
  Duration positionSec = Duration.zero;
  Duration durationSec = Duration.zero;
  int currentSongIndex = 0;
  SongData? _currentPlayingSong; // Data for the song currently being played

  // Getters for UI access
  SongData? get currentPlayingSong => _currentPlayingSong;
  List get allSongs => _allSongs;
  List get searchResults => _searchResults;

  // Streams for efficient UI updates (e.g., progress bar)
  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        player.positionStream,
        player.bufferedPositionStream,
        player.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  // --- MODIFIED: Constructor now takes the Hive Box directly ---
  SongProvider(this._songsBox) { // _songsBox is assigned here
    _initPlayerListeners();
    _loadSongsFromHive(); // Load songs immediately after _songsBox is available
  }
  // ------------------------------------------------------------------

  // --- REMOVED: No separate init method needed anymore ---
  // void init(HiveManager hiveManager) {
  //   _songsBox = hiveManager.localSongsBox;
  //   _loadSongsFromHive();
  // }
  // --------------------------------------------------------

  // Load songs from Hive into localPlaylist
  void _loadSongsFromHive() {
    localPlaylist = _songsBox.values.toList();
    notifyListeners(); // Notify UI that the localPlaylist has been loaded
    print("Loaded ${localPlaylist.length} songs from Hive into localPlaylist.");
  }

  // Sets up listeners for the audio player's state.
  void _initPlayerListeners() {
    player.playerStateStream.listen((playerState) {
      isSongLoaded = playerState.processingState != ProcessingState.idle;
      isPlaying = playerState.playing;
      notifyListeners(); // Notify UI about player state changes

      if (playerState.processingState == ProcessingState.completed) {
        finalSongsPlaylist.isNotEmpty ? playNext() : resetPlayerState();
      }
    });

    player.positionStream.listen((position) => positionSec = position);
    player.durationStream.listen(
      (duration) => durationSec = duration ?? Duration.zero,
    );
  }

  // Resets player and song state if playlist is empty or completed.
  void resetPlayerState() {
    player.stop();
    currentSongIndex = 0;
    _currentPlayingSong = null;
    isPlaying = false;
    notifyListeners();
  }

  // Sets the master list of all songs available.
  void setAllSongs(List songs) {
    if (_allSongs != songs) {
      _allSongs = List.from(songs);
      notifyListeners();
    }
  }

  // Updates the list of online search results.
  void setSearchResults(List results) {
    _searchResults = results;
    notifyListeners();
  }

  // Sets the active playlist for playback.
  void setFinalPlaylist(List newPlaylist) {
    if (!listEquals(finalSongsPlaylist, newPlaylist)) {
      finalSongsPlaylist = newPlaylist;

      if (_currentPlayingSong != null) {
        final newIndex = finalSongsPlaylist.indexOf(_currentPlayingSong!);
        currentSongIndex = newIndex != -1 ? newIndex : 0;
        if (newIndex == -1)
          resetPlayerState(); // Stop if current song not in new list
      } else {
        currentSongIndex = 0;
      }
      notifyListeners();
    }
  }

  // MODIFIED: Adds a song to the local playlist and master list (if new).
  // Also adds to Hive if it's a new entry in localPlaylist.
  void updateLocalPlaylist(SongData songToAdd) {
    if (!localPlaylist.any((song) => song.id == songToAdd.id)) {
      localPlaylist.add(songToAdd);
      _songsBox.put(songToAdd.id, songToAdd); // <--- Save to Hive
      print("Added '${songToAdd.title}' to localPlaylist & Hive.");
    } else {
      removeFromLocalPlaylist(songToAdd); // Hive removal happens in this call
      print("Removed '${songToAdd.title}' from localPlaylist via updateLocalPlaylist.");
    }

    if (!_allSongs.any((song) => song.id == songToAdd.id)) {
      _allSongs.add(songToAdd);
    } else {
      removeFromAllSongs(songToAdd);
    }
    notifyListeners();
  }

  // MODIFIED: Removes a song from the local playlist and from Hive.
  void removeFromLocalPlaylist(SongData songToRemove) {
    if (!(_currentPlayingSong?.id == songToRemove.id)) {
      final int initialLength = localPlaylist.length;
      localPlaylist.removeWhere((song) => song.id == songToRemove.id);
      if (localPlaylist.length < initialLength) {
        _songsBox.delete(songToRemove.id); // <--- Delete from Hive
        print("Removed '${songToRemove.title}' from localPlaylist & Hive directly.");
      }
      notifyListeners();
    } else {
      print("Cannot remove currently playing song '${songToRemove.title}' from localPlaylist.");
    }
  }

  void removeFromAllSongs(SongData songToRemove) {
    if (!(_currentPlayingSong?.id == songToRemove.id)) {
      _allSongs.removeWhere((song) => song.id == songToRemove.id);
      notifyListeners();
    }
  }

  // Initializes and plays a song from the active playlist.
  Future<void> playInit(int index) async {
    if (index < 0 || index >= finalSongsPlaylist.length) {
      print("Error: Song index out of bounds: $index");
      return;
    }

    currentSongIndex = index;
    _currentPlayingSong = finalSongsPlaylist[currentSongIndex];
    notifyListeners();

    // Assuming audioUrl is relative and needs to be combined with a base URL
    final url = Uri.https(
      'aac.saavncdn.com',
      _currentPlayingSong!.audioUrl.split('com')[1],
    ).toString();

    try {
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: _currentPlayingSong!.id,
            title: _currentPlayingSong!.title ?? 'Unknown Title',
            artist: _currentPlayingSong!.artists ?? 'Unknown Artist',
            artUri: Uri.parse(_currentPlayingSong!.imgUrl),
          ),
        ),
      );
      durationSec = player.duration ?? Duration.zero;
      positionSec = Duration.zero;

      player.playing ? await player.stop() : null;
      player.play();
    } catch (e) {
      print("Error loading or playing audio: $e");
      isPlaying = false;
      notifyListeners();
    }
  }

  // Toggles play/pause state.
  void pauseSong() {
    player.playing ? player.pause() : player.play();
  }

  void playNext() {
    if (finalSongsPlaylist.isEmpty) {
      return;
    }

    int nextIndex;

    if (currentSongIndex == finalSongsPlaylist.length - 1) {
      nextIndex = 0;
    } else {
      nextIndex = currentSongIndex + 1;
    }

    playInit(nextIndex);
  }

  void playPrevious() {
    if (finalSongsPlaylist.isEmpty) {
      return;
    }

    int previousIndex;

    if (currentSongIndex == 0) {
      previousIndex = finalSongsPlaylist.length - 1;
    } else {
      previousIndex = currentSongIndex - 1;
    }

    playInit(previousIndex);
  }

  // Seeks to a specific position in the current song.
  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  // Toggles repeat mode (Off -> One -> Off).
  void toggleRepeatMode() {
    LoopMode newMode = player.loopMode == LoopMode.off
        ? LoopMode.one
        : LoopMode.off;
    player.setLoopMode(newMode);
    notifyListeners();
  }

  Stream<LoopMode> get loopModeStream => player.loopModeStream;

  // Disposes the player when provider is no longer needed.
  @override
  void dispose() {
    player.stop();
    player.dispose();
    // Do NOT close the Hive box here. It's managed by HiveManager and
    // should remain open for the app's lifetime.
    super.dispose();
  }
}

// Helper function to compare lists for equality (content-wise)
bool listEquals(List list1, List list2) {
  if (identical(list1, list2)) return true;
  if (list1.length != list2.length) return false;
  for (int i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) return false;
  }
  return true;
}