import 'dart:async';
import 'dart:convert';
import 'package:boomplay/Models/songDataModel.dart';
import 'package:boomplay/Models/songProvider.dart' hide SongData;
import 'package:boomplay/components/alert_options.dart';
import 'package:boomplay/components/marque_text.dart';
import 'package:boomplay/components/music_tile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class SearchOnlinePage extends StatefulWidget {
  const SearchOnlinePage({super.key});

  @override
  _SearchOnlinePageState createState() => _SearchOnlinePageState();
}

class _SearchOnlinePageState extends State<SearchOnlinePage> {
  final TextEditingController _searchController = TextEditingController();
  List searchResults = [];

  Timer? _debounce;
  bool _isLoading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() {
      _isLoading = true;
    });
    _debounce = Timer(const Duration(milliseconds: 100), () async {
      try {
        var results = await _fetchData(query);
        setState(() {
          for (var song in results) {
            var artists = [];

            for (var item in song['artists']['primary']) {
              artists.add(item['name']);
            }

            var data = SongData(
              title: song['name'],
              imgUrl: song['image'][2]['url'],
              artists: artists.join(', '),
              audioUrl: song['downloadUrl'][2]['url'],
              id: song['id'],
            );
            searchResults.add(data);
          }

          _searchController.text = '';
          context.read<SongProvider>().setSearchResults(searchResults);
          context.read<SongProvider>().setFinalPlaylist(searchResults);
        });
      } catch (e) {
        // Handle error
        print(e);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future _fetchData(query) async {
    setState(() {
      searchResults = [];
    });
    var response = await http.get(
      Uri.https('saavn.dev', '/api/search/songs', {'query': query}),
    );
    var jsonData = jsonDecode(response.body);

    return jsonData['data']['results'];
  }

  void btnsearch() {
    final query = _searchController.text.toLowerCase();
    _onSearchChanged(query);
    FocusScope.of(context).unfocus();
  }

  void playSongOption(int index) {
    context.read<SongProvider>().playInit(index);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SongProvider>(
      builder: (context, musicData, child) {
        var playlist = musicData.searchResults;

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 60,
            forceMaterialTransparency: true,
            centerTitle: true,
            scrolledUnderElevation: 0.0,
            title: Text(
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.7,
                ),
              ),
              "Find Online",
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
                      hintText: 'Search Tracks by Name or Artists',
                      suffixIcon: GestureDetector(
                        onTap: () => {btnsearch()},
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
                    onSubmitted: _onSearchChanged,
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: Column(
                    children: [
                      if (_isLoading)
                        CircularProgressIndicator(color: Colors.white54)
                      else
                        Expanded(
                          child: playlist.isNotEmpty
                              ? ListView.builder(
                                  itemCount: playlist.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index < playlist.length) {
                                      return GestureDetector(
                                        onTap: () => {
                                          context.read<SongProvider>().setFinalPlaylist(playlist),
                                          musicData.playInit(index),
                                        },
                                        child: MusicTile(
                                          title: playlist[index].title,
                                          artists: playlist[index].artists,
                                          imgSrc: playlist[index].imgUrl,
                                          onMoreHorizPressed: () => showDialog(
                                            context: context,
                                            builder: (dialogContext) {
                                              return MoreTrackOptions(
                                                song: playlist[index],
                                                parentContext: context,
                                                index: index,
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    } else {
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
                                  'No songs found..',
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
