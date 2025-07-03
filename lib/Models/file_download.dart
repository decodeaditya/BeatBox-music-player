import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_media_store/flutter_media_store.dart'; // Import flutter_media_store
import 'package:device_info_plus/device_info_plus.dart';

class Mp3DownloaderPage extends StatefulWidget {
  final String mp3Url;
  final String fileName; // e.g., "my_song.mp3"

  const Mp3DownloaderPage({
    Key? key,
    required this.mp3Url,
    required this.fileName,
  }) : super(key: key);

  @override
  State<Mp3DownloaderPage> createState() => Mp3DownloaderPageState();
}

class Mp3DownloaderPageState extends State<Mp3DownloaderPage> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = "Ready to download";
  String? _downloadedFilePath;

  final FlutterMediaStore _mediaStore = FlutterMediaStore();

  Future<void> _downloadMp3() async {
    if (_isDownloading) {
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatus = "Preparing download..."; // Changed initial status
      _downloadedFilePath = null;
    });

    // --- Permission Handling Adjustment START ---
    if (Platform.isAndroid) {
      // Check Android version
      final AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
      final int sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) { // Android 13 (API 33) and above
        // For Android 13+, READ_EXTERNAL_STORAGE is deprecated/removed.
        // We now request specific media permissions.
        PermissionStatus audioStatus = await Permission.audio.status;

        if (audioStatus.isDenied) {
          audioStatus = await Permission.audio.request();
        }

        if (audioStatus.isPermanentlyDenied) {
          setState(() {
            _isDownloading = false;
            _downloadStatus = "Media permission permanently denied.";
          });
          openAppSettings();
          return;
        }
        if (!audioStatus.isGranted) {
          setState(() {
            _isDownloading = false;
            _downloadStatus = "Media permission denied.";
          });
          return;
        }
        // If Permission.audio is granted, or if it's already granted
        // and flutter_media_store will handle the write via MediaStore.
      } else if (sdkInt >= 30) { // Android 11 (API 30) - 12 (API 32)
        // On Android 11/12, READ_EXTERNAL_STORAGE might still be implicitly
        // used for some legacy paths, but MediaStore is the preferred way.
        // If your app only needs to write to its own designated MediaStore directories
        // (like Music, Pictures, Downloads), you often don't need a direct storage permission request here.
        // However, if you also read files created by *other* apps, Permission.storage might still be checked
        // by some older plugin versions, or you'd need MANAGE_EXTERNAL_STORAGE for broader access.
        // For just writing to MediaStore with flutter_media_store, it typically handles it.
        // Let's keep a check for Permission.storage for API 30-32 as a fallback/safety,
        // but understand it's less direct than MediaStore writes.
        PermissionStatus status = await Permission.storage.status;
        if (status.isDenied) {
          status = await Permission.storage.request();
        }
        if (status.isPermanentlyDenied) {
          setState(() {
            _isDownloading = false;
            _downloadStatus = "Storage permission permanently denied.";
          });
       
          openAppSettings();
          return;
        }
        if (!status.isGranted) {
          setState(() {
            _isDownloading = false;
            _downloadStatus = "Storage permission denied.";
          });
        
          return;
        }
      } else { // Android 10 (API 29) and below
        PermissionStatus status = await Permission.storage.status;
        if (status.isDenied) {
          status = await Permission.storage.request();
        }
        if (status.isPermanentlyDenied) {
          setState(() {
            _isDownloading = false;
            _downloadStatus = "Storage permission permanently denied.";
          });
        
          openAppSettings();
          return;
        }
        if (!status.isGranted) {
          setState(() {
            _isDownloading = false;
            _downloadStatus = "Storage permission denied.";
          });
      
          return;
        }
      }
    }
    // --- Permission Handling Adjustment END ---

    setState(() {
      _downloadStatus = "Preparing download...";
    });

    Directory tempDir = await getTemporaryDirectory();
    final String tempFilePath = '${tempDir.path}/${widget.fileName}';

    setState(() {
      _downloadStatus = "Downloading...";
    });

    try {
      Dio dio = Dio();
      await dio.download(
        widget.mp3Url,
        tempFilePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
              _downloadStatus =
                  "Downloading: ${(_downloadProgress * 100).toStringAsFixed(0)}%";
            });
          }
        },
      );

      List<int> fileBytes = await File(tempFilePath).readAsBytes();

      String finalSavePath = '';
      if (Platform.isAndroid) {
        await _mediaStore.saveFile(
          fileData: fileBytes,
          mimeType: "audio/mpeg",
          rootFolderName: "Downloads",
          folderName: "Beatbox",
          fileName: widget.fileName,
          onSuccess: (String uri, String filePath) {
            finalSavePath = filePath;
            setState(() {
              _isDownloading = false;
              _downloadStatus = "Download complete! Saved to Music/Beatbox folder.";
              _downloadedFilePath = finalSavePath;
            });
        
            print('✅ File saved successfully: $filePath');
            print('URI: $uri');
          },
          onError: (String errorMessage) {
            finalSavePath = tempFilePath;
            setState(() {
              _isDownloading = false;
              _downloadStatus = "Download complete (internal only): $errorMessage";
              _downloadedFilePath = finalSavePath;
            });
        
            print("❌ Failed to save to MediaStore: $errorMessage");
          },
        );

        if (await File(tempFilePath).exists()) {
          await File(tempFilePath).delete();
        }
      } else if (Platform.isIOS) {
        Directory appDocumentsDir = await getApplicationDocumentsDirectory();
        final String iosSubFolder = '${appDocumentsDir.path}/Beatbox';
        final Directory iosMusicDirectory = Directory(iosSubFolder);
        if (!await iosMusicDirectory.exists()) {
          await iosMusicDirectory.create(recursive: true);
        }
        finalSavePath = '$iosSubFolder/${widget.fileName}';
        await File(
          tempFilePath,
        ).copy(finalSavePath);
        await File(tempFilePath).delete();
      

        setState(() {
          _isDownloading = false;
          _downloadStatus = "Download complete!";
          _downloadedFilePath = finalSavePath;
        });
        print("MP3 processed and saved to: $finalSavePath");
      } else {
        finalSavePath = tempFilePath;
        setState(() {
          _isDownloading = false;
          _downloadStatus = "Download complete (app internal storage)!";
          _downloadedFilePath = finalSavePath;
        });
       
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadStatus = "Download failed: ${e.toString()}";
      });
    
      print("Download error: $e");
      if (await File(tempFilePath).exists()) {
        await File(tempFilePath).delete();
      }
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        forceMaterialTransparency: true,
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        title: Text(
          "Download Music",
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.7,
              color: Colors.white,
            ),
          ),
          textAlign: TextAlign.left,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const Divider(color: Colors.white10, thickness: 0.4, height: 0),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.fileName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _downloadStatus,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (_isDownloading)
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: _downloadProgress,
                            backgroundColor: Colors.grey[700],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.lightGreenAccent,
                            ),
                            minHeight: 10,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (_downloadedFilePath != null)
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 50,
                      ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _downloadMp3,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.download, color: Colors.white),
                      label: Text(
                        _isDownloading ? 'Downloading...' : 'Download MP3',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDownloading
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_downloadedFilePath != null)
                      Column(
                        children: [
                          Text(
                            "File saved to:",
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                fontSize: 14,
                                color: Colors.white60,
                              ),
                            ),
                          ),
                          Text(
                            _downloadedFilePath!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                fontSize: 12,
                                color: Colors.white30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}