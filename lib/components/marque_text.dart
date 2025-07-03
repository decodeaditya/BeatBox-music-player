import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class MarqueeIfOverflow extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double height; // Required to give Marquee a constrained height
  final double blankSpace;
  final double velocity;
  final Duration pauseAfterRound;
  final double startPadding;
  final Key? textKey; // Optional key to force Marquee rebuild on text change

  const MarqueeIfOverflow({
    super.key, // Key for the MarqueeIfOverflow widget itself
    required this.text,
    required this.style,
    required this.height,
    this.blankSpace = 15.0,
    this.velocity = 25.0,
    this.pauseAfterRound = const Duration(seconds: 1),
    this.startPadding = 15.0,
    this.textKey, // This key will be passed to the Marquee widget
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Measure the actual width of the text
          final textPainter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: TextDirection.ltr, // Assuming LTR for most text, adjust if needed
            maxLines: 1, // Crucial for measuring as a single line
          )..layout(minWidth: 0, maxWidth: double.infinity); // Measure its true intrinsic width

          final textWidth = textPainter.width;
          final availableWidth = constraints.maxWidth;

          // If text is wider than available space, use Marquee
          if (textWidth > availableWidth) {
            return Marquee(
              key: textKey, // Pass the custom key for text content changes
              text: text,
              style: style,
              blankSpace: blankSpace,
              velocity: velocity,
              pauseAfterRound: pauseAfterRound,
              startPadding: startPadding,
              fadingEdgeStartFraction: 0.1,
              fadingEdgeEndFraction: 0.1,
              showFadingOnlyWhenScrolling: true,
              // For debugging if it scrolls when it shouldn't:
              // showFadingOnlyWhenScrolling: textWidth > availableWidth,
            );
          } else {
            // Otherwise, render a simple Text widget
            return DefaultTextStyle(
              style: style,
              textAlign: TextAlign.center, // Center small text
              overflow: TextOverflow.visible, // Ensure it's not clipped
              maxLines: 1,
              child: Text(text),
            );
          }
        },
      ),
    );
  }
}

