// lib/widgets/youtube_music_options_dialog.dart
import 'package:boomplay/Models/file_download.dart';
import 'package:boomplay/pages/local_Songs.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boomplay/Models/songProvider.dart';
import 'package:provider/provider.dart';

// --- Song Model (assuming it's either defined here or in a separate models file) ---
// For simplicity in this example, I'm including it here.
// In a larger app, you might have lib/models/song.dart
class Song {
  final String id;
  final String title;
  final String artists;
  final String imgUrl;
  final String audioUrl;

  Song({
    required this.id,
    required this.title,
    required this.artists,
    required this.imgUrl,
    required this.audioUrl,
  });
}
// --- End Song Model ---

/// A custom AlertDialog styled like YouTube Music's "More Track Options" modal.
class MoreTrackOptions extends StatefulWidget {
  final index;
  final song;
  final BuildContext
  parentContext; // Context of the calling widget (for ScaffoldMessenger)

  const MoreTrackOptions({
    super.key,
    required this.song,
    required this.parentContext,
    required this.index,
  });

  @override
  State<MoreTrackOptions> createState() => _MoreTrackOptionsState();
}

class _MoreTrackOptionsState extends State<MoreTrackOptions>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300), // Adjust duration as needed
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // A nice bouncy effect for appearance
      reverseCurve: Curves.easeInQuad, // A smoother disappearance
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    // Start the animation when the dialog appears
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SongProvider>(
      builder: (context, musicData, child) {
        bool isLocallyAdded = musicData.localPlaylist.any(
          (localsong) => localsong.id == widget.song.id,
        );

        bool currentlyPlaying =  musicData.currentPlayingSong?.id == widget.song.id;

        return ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 15.0,
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Song Thumbnail and Info at the top of the dialog
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            widget.song.imgUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[700],
                                  child: Icon(
                                    Icons.music_note,
                                    color: Colors.grey[500],
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                widget.song.artists,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(color: Colors.white12, thickness: 1),
                    ),

                    // --- YouTube Music style options as ListTiles ---
                    Container(
                      width: double.maxFinite,
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                context
                                    .read<SongProvider>()
                                    .updateLocalPlaylist(widget.song);
                                context.read<SongProvider>().setFinalPlaylist(musicData.localPlaylist);    
                                Navigator.of(context).pop();
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        currentlyPlaying && isLocallyAdded ? "Can't Update Playlist" : 'Playlist Updated',
                                        style: GoogleFonts.poppins(
                                          textStyle: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      content: SingleChildScrollView(
                                        child: ListBody(
                                          children: [
                                            Text(
                                               currentlyPlaying && isLocallyAdded ? 'Selected track was not removed Because it is being Played!' :'The Song that you have Selected was ${isLocallyAdded ? "Removed from" : "Added to"} Favorites!',
                                              style: GoogleFonts.poppins(
                                                textStyle: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text(
                                            'Done',
                                            style: GoogleFonts.poppins(
                                              textStyle: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 3),
                                    child: Container(
                                      width: double.maxFinite,
                                      height: 70,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isLocallyAdded
                                            ? Icons.playlist_remove_rounded
                                            : Icons.playlist_add_rounded,
                                        color: Colors.white70,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    !isLocallyAdded
                                        ? 'Add Favorite'
                                        : 'Undo Favorite',
                                    style: GoogleFonts.poppins(
                                      textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => Mp3DownloaderPage(
                                      mp3Url: widget.song.audioUrl,
                                      fileName:
                                          '${widget.song.title + widget.song.id}_beatbox.mp3',
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 3),
                                    child: Container(
                                      width: double.maxFinite,
                                      height: 70,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.download_for_offline_outlined,
                                        color: Colors.white70,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Download',
                                    style: GoogleFonts.poppins(
                                      textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.maxFinite,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color.fromARGB(17, 255, 255, 255),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
