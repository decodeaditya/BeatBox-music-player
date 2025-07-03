import 'package:boomplay/Models/file_download.dart';
import 'package:boomplay/Models/songProvider.dart';
import 'package:boomplay/components/marque_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';

// Removed: import 'package:palette_generator/palette_generator.dart';

class FullPagePlayer extends StatelessWidget {
  const FullPagePlayer({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$minutes:$seconds';
  }

  // Define your static gradient colors here
  final List<Color> staticGradientColors = const [
    Color.fromARGB(255, 63, 63, 63), // A dark grey/black for the top
    Color.fromARGB(221, 22, 22, 22), // Pure black for the bottom
  ];

  // Removed: _generateGradientColors function
  // Removed: _darkenColor function (if it was still present)

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);

    return Consumer<SongProvider>(
      builder: (context, musicData, child) {
        var playlist = musicData.finalSongsPlaylist;
        final currentPlayingSongData = musicData.currentPlayingSong;
        // Removed: final String? albumArtUrl = currentPlayingSongData?.imgUrl; (no longer needed for gradient)

        return DraggableScrollableSheet(
          initialChildSize: 1.0,
          minChildSize: 0.8,
          maxChildSize: 1.0,
          expand: true,
          builder: (_, scrollController) {
            return Center(
              // Replaced FutureBuilder and AnimatedContainer with a simple Container
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: staticGradientColors, // Using the static colors
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 1.0],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16.0),
                  ),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 30.0,
                    left: 10.0,
                    right: 10.0,
                    bottom: MediaQuery.of(context).padding.bottom + 20.0,
                  ),
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(400),
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white70,
                              size: 30,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        Text(
                          musicData.isPlaying ? "Now Playing" : "Let's Play",
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          textAlign: TextAlign.left,
                        ),
                        IconButton(
                          icon: Container(
                            padding: EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(400),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 26,
                            ),
                          ),
                          onPressed: () {
                            musicData.resetPlayerState();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width / 1.2,
                        height: MediaQuery.of(context).size.width / 1.2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child:
                              currentPlayingSongData != null &&
                                  currentPlayingSongData.imgUrl != null
                              ? Image.network(
                                  currentPlayingSongData.imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.music_note,
                                        size: 100,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.music_note,
                                    size: 100,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    currentPlayingSongData?.title != null
                        ? MarqueeIfOverflow(
                            text: currentPlayingSongData!.title!,
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                fontSize: 26,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            height: 35,
                            blankSpace: 25.0,
                            velocity: 30.0,
                            textKey: ValueKey(
                              'title_${currentPlayingSongData.id ?? currentPlayingSongData.title}',
                            ),
                          )
                        : Text(
                            'No Track Playing',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                fontSize: 26,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                    const SizedBox(height: 8),
                    currentPlayingSongData?.artists != null
                        ? MarqueeIfOverflow(
                            text: currentPlayingSongData!.artists!,
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                fontSize: 19,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            height: 35,
                            blankSpace: 25.0,
                            velocity: 30.0,
                            textKey: ValueKey(
                              'artists_${currentPlayingSongData.id ?? currentPlayingSongData.artists}',
                            ),
                          )
                        : Text(
                            'Unknown Artist',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                fontSize: 26,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                    const SizedBox(height: 40),

                    StreamBuilder<PositionData>(
                      stream: musicData.positionDataStream,
                      builder: (context, snapshot) {
                        final positionData = snapshot.data;
                        final position =
                            positionData?.position ?? Duration.zero;
                        final bufferedPosition =
                            positionData?.bufferedPosition ?? Duration.zero;
                        final duration =
                            positionData?.duration ?? Duration.zero;

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 3.0,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6.0,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 7.0,
                                ),
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Color.fromARGB(
                                  216,
                                  70,
                                  70,
                                  70,
                                ),
                                thumbColor: Colors.white,
                                overlayColor: const Color.fromARGB(
                                  101,
                                  255,
                                  255,
                                  255,
                                ),
                              ),
                              child: Slider(
                                min: 0.0,
                                max: duration.inMilliseconds.toDouble(),
                                value: position.inMilliseconds.toDouble().clamp(
                                  0.0,
                                  duration.inMilliseconds.toDouble(),
                                ),
                                onChanged: (value) {
                                  musicData.seek(
                                    Duration(milliseconds: value.toInt()),
                                  );
                                },
                                secondaryTrackValue: bufferedPosition
                                    .inMilliseconds
                                    .toDouble()
                                    .clamp(
                                      0.0,
                                      duration.inMilliseconds.toDouble(),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    Container(
                      height: MediaQuery.of(context).size.height * 0.01,
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        StreamBuilder<LoopMode>(
                          stream: songProvider.loopModeStream,
                          builder: (context, snapshot) {
                            final loopMode = snapshot.data ?? LoopMode.off;
                            IconData iconData;
                            Color iconColor;

                            switch (loopMode) {
                              case LoopMode.off:
                                iconData = Icons.repeat_rounded;
                                iconColor = Colors.white70;
                                break;
                              case LoopMode.one:
                                iconData = Icons.repeat_one_rounded;
                                iconColor = Colors.white;
                                break;
                              case LoopMode.all:
                                iconData = Icons.repeat_rounded;
                                iconColor = Colors.white;
                                break;
                            }
                            return IconButton(
                              icon: Icon(iconData, color: iconColor, size: 30),
                              onPressed: songProvider.toggleRepeatMode,
                            );
                          },
                        ),
                        IconButton(
                          icon: Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              color: Colors.black54,
                            ),
                            child: const Icon(
                              Icons.skip_previous_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          onPressed: () {
                            musicData.playPrevious();
                          },
                        ),
                        Container(
                          padding: EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            color: Colors.white,
                          ),
                          child: StreamBuilder<PlayerState>(
                            stream: musicData.playerStateStream,
                            builder: (context, snapshot) {
                              final playerState = snapshot.data;
                              final processingState =
                                  playerState?.processingState;
                              final playing = playerState?.playing;

                              IconData icon;
                              if (processingState == ProcessingState.loading ||
                                  processingState ==
                                      ProcessingState.buffering) {
                                icon = Icons.hourglass_empty;
                              } else if (playing == true) {
                                icon = Icons.pause;
                              } else if (processingState ==
                                  ProcessingState.completed) {
                                icon = Icons.replay_rounded;
                              } else {
                                icon = Icons.play_arrow_rounded;
                              }

                              return IconButton(
                                icon: Icon(
                                  icon,
                                  size: 40,
                                  color: Color(0xff121212),
                                ),
                                onPressed: () {
                                  if (currentPlayingSongData == null &&
                                      playlist.isNotEmpty) {
                                    musicData.playInit(0);
                                  } else if (processingState ==
                                      ProcessingState.completed) {
                                    musicData.seek(Duration.zero);
                                    musicData.player.play();
                                  } else {
                                    musicData.pauseSong();
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              color: Colors.black54,
                            ),
                            child: const Icon(
                              Icons.skip_next_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          onPressed: () {
                            musicData.playNext();
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.download_rounded,
                            color: Colors.white70,
                            size: 30,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => Mp3DownloaderPage(
                                  mp3Url:  currentPlayingSongData != null ? currentPlayingSongData.audioUrl : "nosong.mp3",
                                fileName:   currentPlayingSongData != null ? '${currentPlayingSongData.title + currentPlayingSongData.id}_beatbox.mp3' : "nosong.mp3",
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
