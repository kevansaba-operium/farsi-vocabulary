import 'package:flutter/material.dart';
import '../utils/phonetics.dart';

/// Renders a transliteration or Farsi string with phonetic highlighting.
/// Farsi script is always right-to-left; Latin transliteration is always LTR.
class PhoneticText extends StatelessWidget {
  final String text;
  final bool isFarsi;
  final TextStyle? style;
  final TextAlign textAlign;

  const PhoneticText(
    this.text, {
    super.key,
    this.isFarsi = false,
    this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final base = (style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFamily: isFarsi ? 'sans-serif' : null,
    );
    final spans = isFarsi ? tokenizeFarsi(text) : tokenizeTranslit(text);
    final textSpan = buildPhoneticTextSpan(spans, base);

    if (isFarsi) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          width: double.infinity,
          child: RichText(
            text: textSpan,
            textAlign: textAlign,
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: RichText(
        text: textSpan,
        textAlign: textAlign,
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

/// Compact legend row showing all highlighted phonetic features.
class PhoneticLegend extends StatelessWidget {
  const PhoneticLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: phoneticLegend.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${item.symbol} – ${item.description}',
              style: TextStyle(fontSize: 11, color: item.color),
            ),
          ],
        );
      }).toList(),
    );
  }
}
