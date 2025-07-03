import 'package:boomplay/Models/songProvider.dart';
import 'package:boomplay/components/alert_options.dart';
import 'package:boomplay/components/music_tile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LocalSongs extends StatefulWidget {
  const LocalSongs({super.key});

  @override
  _LocalSongsState createState() => _LocalSongsState();
}

class _LocalSongsState extends State<LocalSongs> {
  String query = '';
  TextEditingController _searchController = TextEditingController();

  // This list will hold the songs currently displayed in the ListView.
  // It will either be the full playlist or the filtered search results.
  List _displaySongs = [];

  @override
  Widget build(BuildContext context) {
    return Consumer<SongProvider>(
      builder: (context, musicData, child) {
        var playlist = musicData.localPlaylist;

        // Determine which list of songs to display based on the current query.
        // If the query is empty, show the full playlist.
        // Otherwise, filter the playlist based on the query.
        if (query.isEmpty) {
          _displaySongs = playlist;
        } else {
          _displaySongs = playlist
              .where(
                (song) => (song.title + song.artists).toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .toList();
        }

        // Function to handle search input changes (real-time filtering)
        void onSearchChanged(String text) {
          setState(() {
            query = text;
            // _displaySongs will be re-calculated in the builder due to setState.
          });
        }

        // Function to handle explicit search (e.g., when search button is tapped or Enter is pressed)
        void btnSearch() {
          setState(() {
            query = _searchController.text.toLowerCase();
          });
          onSearchChanged(query); // Trigger filtering with the current text
          FocusScope.of(context).unfocus(); // Dismiss the keyboard
        }

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 60,
            forceMaterialTransparency: true,
            centerTitle: true,
            scrolledUnderElevation: 0.0,
            title: Text(
              "Favorites",
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.7,
                ),
              ),
              textAlign: TextAlign.left,
            ),
          ),
          body: Container(
            child: Column(
              children: [
                Divider(color: Colors.white10, thickness: 0.4, height: 0),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: onSearchChanged, // Live filtering as user types
                    onSubmitted:
                        onSearchChanged, // Filter when user submits (e.g., presses enter)
                    style: GoogleFonts.urbanist(
                      textStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(20),
                      filled: true,
                      fillColor: const Color.fromARGB(28, 255, 255, 255),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      hintText: 'Search among favorites',
                      suffixIcon: GestureDetector(
                        onTap: () => {
                          btnSearch(),
                        }, // Explicit search button tap
                        child: Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(Icons.search, color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        // Display _displaySongs, which is either the full or filtered list.
                        child: _displaySongs.isNotEmpty
                            ? ListView.builder(
                                itemCount:
                                    _displaySongs.length +
                                    1, // +1 for the bottom padding
                                itemBuilder: (context, index) {
                                  if (index < _displaySongs.length) {
                                    final currentSong = _displaySongs[index];
                                    // Find the original index of the song in the main playlist.
                                    // This is crucial for `playInit` and `MoreTrackOptions`
                                    // which might rely on the song's position in the full list.
                                    final int originalIndex = playlist.indexOf(
                                      currentSong,
                                    );

                                    return GestureDetector(
                                      onTap: () {
                                        // Only play if the original index is found,
                                        // preventing issues if somehow a song isn't in the main playlist.
                                        if (originalIndex != -1) {
                                          context.read<SongProvider>().setFinalPlaylist(playlist);
                                          musicData.playInit(originalIndex);
                                        }
                                      },
                                      child: MusicTile(
                                        title: currentSong.title,
                                        artists: currentSong.artists,
                                        imgSrc: currentSong.imgUrl,
                                        onMoreHorizPressed: () => showDialog(
                                          context: context,
                                          builder: (dialogContext) {
                                            return MoreTrackOptions(
                                              song: currentSong,
                                              parentContext: context,
                                              // Pass the original index to MoreTrackOptions.
                                              // Fallback to current index if original not found (though it should be).
                                              index: originalIndex != -1
                                                  ? originalIndex
                                                  : index,
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  } else {
                                    // This is the padding at the bottom of the list.
                                    return musicData.isSongLoaded
                                        ? Container(
                                            height:
                                                MediaQuery.of(
                                                  context,
                                                ).padding.bottom +
                                                100,
                                          )
                                        : const SizedBox.shrink();
                                  }
                                },
                              )
                            : Text(
                                // Display different messages based on whether there's a query
                                // and if no results were found.
                                query.isNotEmpty
                                    ? 'No songs matching "$query" found.'
                                    : 'No songs found in your favorites.',
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.7,
                                  ),
                                ),
                              ),
                      ),
                    ],
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
