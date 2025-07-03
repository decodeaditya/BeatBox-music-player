// main.dart - UPDATED
import 'package:boomplay/Models/hive_manager.dart';
import 'package:boomplay/Models/songDataModel.dart';
import 'package:boomplay/Models/songProvider.dart';
import 'package:boomplay/pages/full_page_player.dart';
import 'package:boomplay/pages/home_page.dart';
import 'package:boomplay/pages/intro_page.dart';
import 'package:boomplay/pages/player_info.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // Assuming you use this elsewhere, added for theme.

// Declare the GlobalKey at the top-level (outside any class)
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final HiveManager hiveManager = HiveManager();
  await hiveManager.initHive(); // This initializes Hive and opens all boxes + registers adapters

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.beatbox.channel.audio',
    androidNotificationChannelName: 'Beatbox Audio playback',
    androidNotificationOngoing: true,
  );

  runApp(
    MultiProvider(
      providers: [
        // Provide the pre-initialized hiveManager instance.
        ChangeNotifierProvider.value(value: hiveManager), // HiveManager is available first

        // --- MODIFIED: Create SongProvider by passing the songsBox directly ---
        ChangeNotifierProvider(
          create: (context) {
            // Get the HiveManager instance that's already provided
            final HiveManager manager = Provider.of<HiveManager>(context, listen: false);
            // Pass the specific songsBox from the manager to the SongProvider constructor
            return SongProvider(manager.localSongsBox);
          },
        ),
        // ----------------------------------------------------------------------
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isFullPagePlayerOpen = false;

  void _openBottomSheet() async {
    if (globalNavigatorKey.currentState == null ||
        !globalNavigatorKey.currentState!.context.mounted) {
      debugPrint("Navigator key context not available yet for bottom sheet.");
      return;
    }

    setState(() {
      _isFullPagePlayerOpen = true;
    });

    await showModalBottomSheet(
      context: globalNavigatorKey.currentState!.context,
      isScrollControlled: true,
      builder: (ctx) {
        return const FullPagePlayer();
      },
    );

    setState(() {
      _isFullPagePlayerOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);
    final hiveManager = Provider.of<HiveManager>(context);

    final bool isOnIntroPage = !hiveManager.isPreviouslyOpened;

    final double systemBottomSafeArea = MediaQuery.of(context).padding.bottom;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double totalBottomInset = systemBottomSafeArea + keyboardHeight;

    const double miniPlayerFixedVisualHeight = 72.0;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xff1DB954),
        colorScheme: ColorScheme.fromSeed(
          surface: const Color(0xff09080f),
          seedColor: const Color(0xff09080f),
          brightness: Brightness.dark,

        ),
        textTheme: GoogleFonts.poppinsTextTheme( // Assuming you use GoogleFonts
          Theme.of(context).textTheme.apply(bodyColor: Colors.white),
        ),
      ),
      navigatorKey: globalNavigatorKey,
      builder: (context, navigatorChild) {
        return Stack(
          children: [
            navigatorChild!,

            StreamBuilder<PlayerState>(
              stream: songProvider.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                final bool isSongLoaded =
                    processingState != null &&
                    processingState != ProcessingState.idle;

                final bool showMiniPlayer =
                    isSongLoaded && !_isFullPagePlayerOpen && !isOnIntroPage;

                if (showMiniPlayer) {
                  return Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromARGB(61, 0, 0, 0),
                            blurRadius: 10.0,
                            spreadRadius: 2.0,
                            offset: Offset(0, -3),
                          ),
                        ],
                        color: Colors.transparent,
                      ),
                      height: miniPlayerFixedVisualHeight,
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),

            StreamBuilder<PlayerState>(
              stream: songProvider.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;

                final bool isSongLoaded =
                    processingState != null &&
                    processingState != ProcessingState.idle;

                final bool showMiniPlayer =
                    isSongLoaded && !_isFullPagePlayerOpen && !isOnIntroPage;

                if (showMiniPlayer) {
                  return Positioned(
                    left: 0,
                    right: 0,
                    bottom: totalBottomInset,
                    child: GestureDetector(
                      onTap: () {
                        _openBottomSheet();
                      },
                      child: const PlayerInfo(),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        );
      },
      home: hiveManager.isPreviouslyOpened ? const HomePage() : const IntroPage(),
    );
  }
}