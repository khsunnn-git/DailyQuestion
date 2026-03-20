import "package:flutter/material.dart";

class AppEmojiText extends StatelessWidget {
  const AppEmojiText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;

  static const Color _emojiAmber = Color(0xFFFFC83D);
  static const Color _emojiPink = Color(0xFFFF6FAE);
  static const Color _emojiRed = Color(0xFFFF5A5F);
  static const Color _emojiOrange = Color(0xFFFF8A3D);
  static const Color _emojiBlue = Color(0xFF48A9F8);
  static const Color _emojiGrey = Color(0xFF9AA0A6);
  static const Color _emojiGreen = Color(0xFF4CAF50);
  static const Color _emojiSky = Color(0xFF7CC8FF);
  static const Color _emojiIndigo = Color(0xFF7986CB);

  _EmojiGlyph? _emojiGlyph(String cluster) {
    switch (cluster) {
      case "🔔":
        return const _EmojiGlyph(Icons.notifications_rounded, _emojiAmber);
      case "✨":
        return const _EmojiGlyph(
          Icons.auto_awesome_rounded,
          _emojiAmber,
          sizeScale: 1.0,
        );
      case "🎉":
        return const _EmojiGlyph(
          Icons.celebration_rounded,
          _emojiPink,
          sizeScale: 1.15,
        );
      case "🔥":
        return const _EmojiGlyph(Icons.local_fire_department_rounded, _emojiOrange);
      case "❤️":
        return const _EmojiGlyph(Icons.favorite_rounded, _emojiRed);
      case "⭐":
        return const _EmojiGlyph(Icons.star_rounded, _emojiAmber);
      case "〰️":
        return const _EmojiGlyph(Icons.remove_rounded, _emojiGrey, sizeScale: 1.0);
      case "🌧️":
        return const _EmojiGlyph(Icons.cloud_rounded, _emojiSky);
      case "⚡":
        return const _EmojiGlyph(Icons.bolt_rounded, _emojiAmber);
      case "☀️":
        return const _EmojiGlyph(Icons.wb_sunny_rounded, _emojiAmber);
      case "🌙":
        return const _EmojiGlyph(Icons.dark_mode_rounded, _emojiIndigo);
      case "🪫":
        return const _EmojiGlyph(Icons.battery_alert_rounded, _emojiGrey);
      case "🌿":
        return const _EmojiGlyph(Icons.eco_rounded, _emojiGreen);
      case "🍃":
        return const _EmojiGlyph(Icons.air_rounded, _emojiGreen);
      case "🌫️":
        return const _EmojiGlyph(Icons.cloud_rounded, _emojiGrey);
      case "🌪️":
        return const _EmojiGlyph(Icons.air_rounded, _emojiGrey);
      case "🪙":
        return const _EmojiGlyph(Icons.paid_rounded, _emojiAmber);
      case "🐟":
        return const _EmojiGlyph(
          Icons.set_meal_rounded,
          _emojiBlue,
          sizeScale: 1.2,
        );
      default:
        return null;
    }
  }

  List<InlineSpan> _buildSpans(TextStyle effectiveStyle) {
    final List<InlineSpan> spans = <InlineSpan>[];
    final StringBuffer buffer = StringBuffer();

    void flushBuffer() {
      if (buffer.isEmpty) {
        return;
      }
      spans.add(TextSpan(text: buffer.toString()));
      buffer.clear();
    }

    for (final String cluster in text.characters) {
      final _EmojiGlyph? glyph = _emojiGlyph(cluster);
      if (glyph != null) {
        flushBuffer();
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              glyph.icon,
              size: (effectiveStyle.fontSize ?? 14) * glyph.sizeScale,
              color: glyph.color,
            ),
          ),
        );
        continue;
      }
      buffer.write(cluster);
    }

    flushBuffer();
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle effectiveStyle = DefaultTextStyle.of(context).style.merge(
      style,
    );

    return Text.rich(
      TextSpan(style: effectiveStyle, children: _buildSpans(effectiveStyle)),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
    );
  }
}

class _EmojiGlyph {
  const _EmojiGlyph(this.icon, this.color, {this.sizeScale = 1.1});

  final IconData icon;
  final Color color;
  final double sizeScale;
}
