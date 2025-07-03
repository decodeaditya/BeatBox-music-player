import 'package:boomplay/Models/songDataModel.dart';
import 'package:boomplay/Models/songProvider.dart';
import 'package:boomplay/components/marque_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// A widget designed to display essential information about the currently playing song
/// in a compact, sleek player bar. This includes the album art, song title,
/// playback status, and a dynamic play/pause button.
class PlayerInfo extends StatefulWidget {
  const PlayerInfo({super.key});

  @override
  _PlayerInfoState createState() => _PlayerInfoState();
}

class _PlayerInfoState extends State<PlayerInfo> {
  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing.
    final screenWidth = MediaQuery.of(context).size.width;
    // Determine the height/width of the album art based on screen width.
    final albumArtSize = screenWidth * 0.13;
    // Determine responsive font sizes based on screen width.
    final statusFontSize = screenWidth * 0.032;
    final titleFontSize = screenWidth * 0.042;
    final iconSize = screenWidth * 0.09;

    return Consumer<SongProvider>(
      builder: (context, musicData, child) {
        // Access the data of the currently playing song from the SongProvider.
        final currentPlayingSongData = musicData.currentPlayingSong;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              // The main player container now has a dark gradient background.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 1, 77, 87), // Very dark near-black at the top-left
                  Color.fromARGB(255, 0, 71, 80), // Slightly lighter dark gray
                  Color.fromARGB(255, 0, 71, 80), // Another slightly lighter dark gray towards bottom-right
                ],
                stops: [0.0, 0.5, 1.0], // Control the spread of the colors
              ),
              borderRadius: BorderRadius.circular(70), // Keep your original large border radius
              boxShadow: [ // Add a subtle shadow for depth
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Section for Album Art and Song Details (Title, Status)
                Expanded(
                  child: Row(
                    children: [
                      // Album Art Display
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100), // Original circular radius
                        child: _buildAlbumArt(currentPlayingSongData, albumArtSize),
                      ),
                      SizedBox(width: screenWidth * 0.04), // Responsive spacing

                      // Song Title and Status Information
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // "Playing Now" or "Tap to Play" status.
                            Text(
                              musicData.isPlaying ? "Playing Now" : "Tap to Play",
                              style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                  fontSize: statusFontSize,
                                  letterSpacing: -0.2,
                                  color: Colors.white70, // Retained color
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.none, // Retained: No underline
                                ),
                              ),
                            ),
                            // Song Title - uses MarqueeIfOverflow for long titles.
                            SizedBox(
                              height: screenWidth * 0.07,
                              child: _buildSongTitle(currentPlayingSongData, titleFontSize),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Play/Pause Button
                _buildPlayPauseButton(musicData, iconSize),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper method to build the album art display.
  /// Shows the actual album art if available, otherwise a default music icon.
  Widget _buildAlbumArt(SongData? songData, double size) {
    if (songData != null && songData.imgUrl != null && songData.imgUrl!.isNotEmpty) {
      return Image.network(
        songData.imgUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            color: Colors.grey[800], // Placeholder color while loading.
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white54),
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: Colors.grey[800], // Background for error.
          child: Icon(
            Icons.broken_image,
            size: size * 0.7,
            color: Colors.grey,
          ),
        ),
      );
    } else {
      return Container(
        width: size,
        height: size,
        color: Colors.grey[800],
        child: Icon(
          Icons.music_note,
          size: size * 0.7,
          color: Colors.grey,
        ),
      );
    }
  }

  /// Helper method to build the song title.
  /// Uses `MarqueeIfOverflow` for smooth scrolling of long titles.
  Widget _buildSongTitle(SongData? songData, double fontSize) {
    if (songData?.title != null && songData!.title.isNotEmpty) {
      return MarqueeIfOverflow(
        text: songData.title!,
        style: GoogleFonts.poppins(
          textStyle: TextStyle(
            fontSize: fontSize,
            letterSpacing: -0.2,
            color: Colors.white, // Retained color
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none, // Retained: Ensure no default underline.
          ),
        ),
        height: fontSize * 2,
        blankSpace: 25.0,
        velocity: 30.0,
        textKey: ValueKey('title_${songData.id ?? songData.title}'),
      );
    } else {
      return Text(
        'No Track Playing',
        textAlign: TextAlign.left,
        style: GoogleFonts.poppins(
          textStyle: TextStyle(
            fontSize: fontSize,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none, // Retained: Ensure no underline.
          ),
        ),
      );
    }
  }

  /// Helper method to build the play/pause button.
  Widget _buildPlayPauseButton(SongProvider musicData, double iconSize) {
    return GestureDetector(
      onTap: () {
        if (musicData.isSongLoaded) {
          musicData.pauseSong();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          musicData.isPlaying ? Icons.pause_outlined : Icons.play_arrow_rounded,
          size: iconSize,
          color: Colors.white, // Retained color
        ),
      ),
    );
  }
}