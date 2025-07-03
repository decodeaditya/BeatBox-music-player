import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MusicTile extends StatelessWidget {
  final title;
  final artists;
  final imgSrc;
  final VoidCallback? onMoreHorizPressed;

  const MusicTile({
    super.key,
    required this.title,
    required this.artists,
    required this.imgSrc,
    required this.onMoreHorizPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imgSrc,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[800],
                        child: const Icon(Icons.music_note, color: Colors.grey, size: 30),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1, // Title: Limit to 1 line
                          overflow: TextOverflow.ellipsis, // Title: Show ellipsis on overflow
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                              color: Colors.white,
                            ),
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          artists,
                          maxLines: 1, // Artists: Limit to 1 line
                          overflow: TextOverflow.ellipsis, // Artists: Show ellipsis on overflow
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              fontSize: 15,
                              color: Colors.white54,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1,
                            ),
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_horiz_outlined),
            onPressed: onMoreHorizPressed,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }
}