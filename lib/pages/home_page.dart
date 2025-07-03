import 'package:boomplay/Models/songDataModel.dart';
import 'package:boomplay/Models/songProvider.dart';
import 'package:boomplay/pages/local_Songs.dart';
import 'package:boomplay/pages/search_online_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boomplay/components/music_tile.dart';
import 'package:boomplay/components/alert_options.dart'; // Assuming this imports MoreTrackOptions
import 'package:provider/provider.dart';
import 'dart:async'; // For Timer
import 'dart:math'; // For Random

/// The main entry point for the home screen of the music application.
/// It displays a greeting, a dynamic "playing" image, and a list of local songs.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Stores the current greeting (Morning, Afternoon, Evening)
  String _currentGreeting = '';
  // Timer to update the greeting based on the time of day
  Timer? _greetingUpdateTimer;

  // For selecting a random GIF when music is playing
  final Random _random = Random();
  // List of paths to GIF assets displayed when a song is playing.
  // Make sure these paths are correct and assets are declared in pubspec.yaml.
  final List<String> _playingGifs = [
    'assets/playingImg1.gif',
    'assets/playingImg2.gif',
    'assets/playingImg3.gif',
    'assets/playingImg4.gif',
  ];
  // A cache to store which random GIF is chosen for a specific song ID.
  // This prevents the GIF from changing every time the widget rebuilds while the same song plays.
  final Map<String, String> _songImageCache = {};

  @override
  void initState() {
    super.initState();
    // Initialize the greeting when the widget starts
    _updateGreeting();
    // Start the timer to automatically update the greeting
    _startGreetingTimer();
  }

  /// This method is called when the dependencies of this State object change.
  /// It's a standard Flutter lifecycle method; no specific logic is added here currently.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  /// Determines the appropriate greeting based on the current hour.
  /// Updates the `_currentGreeting` state variable if the greeting has changed.
  void _updateGreeting() {
    var currentHour = DateTime.now().hour;

    String calculatedGreeting;
    if (currentHour >= 0 && currentHour < 12) {
      calculatedGreeting = "Morning";
    } else if (currentHour >= 12 && currentHour < 16) {
      calculatedGreeting = 'Afternoon';
    } else {
      calculatedGreeting = 'Evening';
    }

    // Only update state if the greeting has actually changed to avoid unnecessary rebuilds.
    if (_currentGreeting != calculatedGreeting) {
      setState(() {
        _currentGreeting = calculatedGreeting;
      });
    }
  }

  /// Sets up a timer to trigger `_updateGreeting` at the next boundary
  /// (e.g., from Morning to Afternoon).
  /// It cancels any existing timer before starting a new one.
  void _startGreetingTimer() {
    _greetingUpdateTimer?.cancel(); // Cancel any previous timer

    DateTime now = DateTime.now();
    DateTime nextBoundary;

    // Calculate the time until the next greeting change
    if (now.hour < 12) {
      nextBoundary = DateTime(now.year, now.month, now.day, 12, 0, 0); // Next is noon
    } else if (now.hour < 16) {
      nextBoundary = DateTime(now.year, now.month, now.day, 16, 0, 0); // Next is 4 PM
    } else {
      // If it's evening, set the boundary to midnight of the next day
      nextBoundary = DateTime(now.year, now.month, now.day, 23, 59, 59)
          .add(const Duration(seconds: 1));
    }

    Duration timeToNextBoundary = nextBoundary.difference(now);

    // If for some reason the calculated time is negative (e.g., already past the boundary)
    // or very small, set a short timer to update immediately and reschedule.
    if (timeToNextBoundary.isNegative || timeToNextBoundary.inMilliseconds < 100) {
      timeToNextBoundary = const Duration(seconds: 1);
    }

    _greetingUpdateTimer = Timer(timeToNextBoundary, () {
      _updateGreeting(); // Update the greeting
      _startGreetingTimer(); // Schedule the next update
    });
  }

  @override
  void dispose() {
    _greetingUpdateTimer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  /// Calculates the total number of items to display in the ListView.
  /// This includes up to 5 song tiles, an optional "Go to Favorites" button,
  /// and a dynamic bottom padding for the mini-player.
  int _calculateDisplayItemCount(List playlist) {
    if (playlist.isEmpty) {
      return 0; // If no songs, nothing to display.
    }

    int count = 0;
    // Determine how many actual song tiles to show (max 5)
    final int visibleSongsCount = playlist.length > 5 ? 5 : playlist.length;
    count += visibleSongsCount;

    // If there are more than 5 songs, add an item for the "Go to Favorites" button
    if (playlist.length > 5) {
      count += 1;
    }

    // Always add 1 for the dynamic bottom padding (for the mini-player)
    count += 1;

    return count;
  }

  /// Builds the action button for searching online or going to favorites.
  /// Extracted into a separate function for better readability.
  Widget _buildActionButton({
    required VoidCallback onTap,
    required String text,
    required IconData icon,
    required double screenWidth,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(59),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              text,
              style: GoogleFonts.urbanist(
                textStyle: TextStyle(
                  color: const Color.fromARGB(206, 229, 229, 229),
                  fontWeight: FontWeight.w600,
                  fontSize: screenWidth * 0.035, // Responsive font size
                ),
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(width: 4),
            Icon(icon, size: screenWidth * 0.05), // Responsive icon size
          ],
        ),
      ),
    );
  }

  /// Builds the greeting section at the top of the home screen.
  Widget _buildGreetingSection({
    required double screenWidth,
    required SongProvider musicData,
  }) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.045), // Responsive padding
      child: Column(
        children: [
          SizedBox(
            width: double.maxFinite,
            child: Text(
              "Welcome to BeatBox!",
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  color: const Color.fromARGB(153, 229, 229, 229),
                  fontSize: screenWidth * 0.04, // Responsive font size
                ),
              ),
              textAlign: TextAlign.left,
            ),
          ),
          SizedBox(
            width: double.maxFinite,
            child: Text(
              musicData.isPlaying
                  ? "Playing Magic :)"
                  : "Good $_currentGreeting,", // Use the cached greeting
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: screenWidth * 0.075, // Responsive font size
                  fontWeight: FontWeight.bold,
                ),
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the dynamic image section (playing GIF or stop GIF).
  Widget _buildDynamicImageSection({
    required String displayImage,
    required double screenWidth,
    required double screenHeight,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.045),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: Image.asset(
            key: ValueKey<String>(displayImage), // Key changes when image path changes
            displayImage, // This will be the random playing GIF or stop GIF
            width: screenWidth,
            height: screenHeight * 0.25, // Responsive height for the image
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: screenWidth,
              height: screenHeight * 0.25, // Maintain height on error
              color: Colors.grey[800],
              child: Icon(
                Icons.broken_image,
                color: Colors.white54,
                size: screenWidth * 0.12, // Responsive error icon size
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the "My Music" header and "Favorites" button.
  Widget _buildMyMusicHeader({
    required double screenWidth,
  }) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.05), // Responsive padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "My Music",
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                fontSize: screenWidth * 0.06, // Responsive font size
                fontWeight: FontWeight.w600,
                letterSpacing: -0.7,
              ),
            ),
            textAlign: TextAlign.left,
          ),
          _buildActionButton(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LocalSongs(),
                ),
              );
            },
            text: "Favorites",
            icon: Icons.chevron_right_rounded,
            screenWidth: screenWidth,
          ),
        ],
      ),
    );
  }

  /// Builds the "Go to Favorites for more" button that appears if there are >5 songs.
  Widget _buildGoToFavoritesButton({
    required int playlistLength,
    required double screenWidth,
    required double screenHeight,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const LocalSongs(),
          ),
        );
      },
      child: Container(
        width: double.maxFinite,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.02,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.015),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.music_note_rounded,
                color: Colors.white54,
                size: screenWidth * 0.08, // Responsive icon size
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              "Go to Favorites for more",
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: screenWidth * 0.04, // Responsive font size
                  letterSpacing: -0.2,
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "Showing 5 of $playlistLength Tracks Here",
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: screenWidth * 0.035, // Responsive font size
                  letterSpacing: -0.2,
                  color: Colors.white30,
                  fontWeight: FontWeight.w500,
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive UI elements
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Consumer<SongProvider>(
      builder: (context, musicData, child) {
        var playlist = musicData.localPlaylist;
        final int displayItemCount = _calculateDisplayItemCount(playlist);

        // Determine which GIF to display (playing or stop)
        final String displayImage;
        if (musicData.isPlaying &&
            musicData.currentSongIndex >= 0 &&
            musicData.currentSongIndex < playlist.length) {
          final String songId = playlist[musicData.currentSongIndex].id;
          // If no GIF is cached for this song, pick a random one
          if (!_songImageCache.containsKey(songId)) {
            _songImageCache[songId] =
                _playingGifs[_random.nextInt(_playingGifs.length)];
          }
          displayImage = _songImageCache[songId]!; // Use the cached GIF
        } else {
          displayImage = "assets/stopImg.gif"; // Show stop GIF when not playing
        }

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: kToolbarHeight, // Standard Flutter AppBar height
            forceMaterialTransparency: true, // Makes AppBar background transparent
            automaticallyImplyLeading: false, // Prevents default back button
            scrolledUnderElevation: 0.0, // Prevents shadow when scrolled
            title: Image.asset(
              "assets/logo_txt.png",
              height: screenHeight * 0.05, // Responsive logo height
              fit: BoxFit.contain,
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: screenWidth * 0.045), // Responsive padding
                child: _buildActionButton(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SearchOnlinePage(),
                      ),
                    );
                  },
                  text: "Search online",
                  icon: Icons.my_library_music_rounded,
                  screenWidth: screenWidth,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildGreetingSection(
                screenWidth: screenWidth,
                musicData: musicData,
              ),
              _buildDynamicImageSection(
                displayImage: displayImage,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
              SizedBox(height: screenHeight * 0.03), // Responsive spacing below image
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xff1E1E1E), // Dark background for the music list
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildMyMusicHeader(screenWidth: screenWidth),
                      const Divider(
                        color: Colors.white10,
                        thickness: 0.4,
                        height: 0,
                      ),
                      const SizedBox(height: 10), // Small spacing after divider
                      Expanded(
                        // Conditionally render the song list or a "no favorites" message
                        child: playlist.isNotEmpty
                            ? ListView.builder(
                                itemCount: displayItemCount, // Total items calculated
                                itemBuilder: (context, index) {
                                  // Condition 1: Display individual song tiles (up to 5)
                                  if (index < playlist.length && index < 5) {
                                    final currentSong = playlist[index];
                                    return GestureDetector(
                                      onTap: () {
                                        // Set the main playback playlist to the local playlist
                                        context.read<SongProvider>().setFinalPlaylist(playlist);
                                        // Start playing the tapped song
                                        musicData.playInit(index);
                                      },
                                      child: MusicTile(
                                        title: currentSong.title,
                                        artists: currentSong.artists,
                                        imgSrc: currentSong.imgUrl,
                                        onMoreHorizPressed: () => showDialog(
                                          context: context,
                                          builder: (dialogContext) {
                                            return MoreTrackOptions(
                                              song: currentSong, // Pass the specific song data
                                              parentContext: context, // Pass context for provider actions
                                              index: index, // Pass index if MoreTrackOptions needs it
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                  // Condition 2: Display "Go to Favorites for more" button if there are >5 songs
                                  else if (playlist.length > 5 && index == 5) {
                                    return _buildGoToFavoritesButton(
                                      playlistLength: playlist.length,
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                    );
                                  }
                                  // Condition 3: Add dynamic bottom padding for the mini-player
                                  else if (index == displayItemCount - 1) {
                                    return musicData.isSongLoaded
                                        ? Container(
                                            height: MediaQuery.of(context).padding.bottom + 100,
                                          )
                                        : const SizedBox.shrink(); // No padding if no song is loaded
                                  }
                                  // Fallback for any unexpected index (should not be reached with correct itemCount)
                                  else {
                                    return const SizedBox.shrink();
                                  }
                                },
                              )
                            : Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  'You have no Favorite tracks!',
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                      color: const Color.fromARGB(179, 255, 255, 255),
                                      fontSize: screenWidth * 0.045, // Responsive font size
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.7,
                                    ),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}