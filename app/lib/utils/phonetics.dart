import 'package:flutter/material.dart';

/// Phonetic highlighting rules for Farsi transliteration and Persian script.
///
/// Highlights:
///   - kh (خ) – teal/cyan: the guttural kh sound
///   - gh (غ/ق) – purple: the voiced uvular fricative
///   - r (ر) – orange: the Farsi rolled r
///   - â / aa (آ / ـا) – blue: long/open "a"  vs plain "a" (short)
///   - sh (ش) – green
///
/// Works on both transliteration strings (Latin) and Farsi strings (Arabic script).

enum PhoneticFeature { kh, gh, r, openA, sh }

class PhoneticSpan {
  final String text;
  final PhoneticFeature? feature;

  const PhoneticSpan(this.text, [this.feature]);
}

class PhoneticColors {
  static const kh = Color(0xFF00796B); // teal
  static const gh = Color(0xFF7B1FA2); // purple
  static const r = Color(0xFFE65100); // deep orange
  static const openA = Color(0xFF1565C0); // blue (long/open A)
  static const sh = Color(0xFF2E7D32); // green

  static Color? forFeature(PhoneticFeature f) => switch (f) {
        PhoneticFeature.kh => kh,
        PhoneticFeature.gh => gh,
        PhoneticFeature.r => r,
        PhoneticFeature.openA => openA,
        PhoneticFeature.sh => sh,
      };
}

class PhoneticLegendItem {
  final String symbol;
  final String description;
  final Color color;

  const PhoneticLegendItem(this.symbol, this.description, this.color);
}

const List<PhoneticLegendItem> phoneticLegend = [
  PhoneticLegendItem('kh / خ', 'Guttural kh (like ch in Bach)', PhoneticColors.kh),
  PhoneticLegendItem('gh / غ / ق', 'Voiced uvular gh (deep throat)', PhoneticColors.gh),
  PhoneticLegendItem('r / ر', 'Rolled r', PhoneticColors.r),
  PhoneticLegendItem('â / aa / آ', 'Long open "a" (like "father")', PhoneticColors.openA),
  PhoneticLegendItem('sh / ش', 'sh sound', PhoneticColors.sh),
];

// ---------------------------------------------------------------------------
// Transliteration tokenizer
// ---------------------------------------------------------------------------

/// Tokenise a Latin transliteration string into PhoneticSpans.
List<PhoneticSpan> tokenizeTranslit(String text) {
  if (text.isEmpty) return [];
  final spans = <PhoneticSpan>[];
  int i = 0;
  final buf = StringBuffer();

  void flush() {
    if (buf.isNotEmpty) {
      spans.add(PhoneticSpan(buf.toString()));
      buf.clear();
    }
  }

  while (i < text.length) {
    // Two-char sequences first
    if (i + 1 < text.length) {
      final two = text.substring(i, i + 2).toLowerCase();
      if (two == 'kh') {
        flush();
        spans.add(PhoneticSpan(text.substring(i, i + 2), PhoneticFeature.kh));
        i += 2;
        continue;
      }
      if (two == 'gh') {
        flush();
        spans.add(PhoneticSpan(text.substring(i, i + 2), PhoneticFeature.gh));
        i += 2;
        continue;
      }
      if (two == 'sh') {
        flush();
        spans.add(PhoneticSpan(text.substring(i, i + 2), PhoneticFeature.sh));
        i += 2;
        continue;
      }
      if (two == 'aa') {
        flush();
        spans.add(PhoneticSpan(text.substring(i, i + 2), PhoneticFeature.openA));
        i += 2;
        continue;
      }
    }
    final ch = text[i];
    final chl = ch.toLowerCase();
    if (chl == 'â') {
      flush();
      spans.add(PhoneticSpan(ch, PhoneticFeature.openA));
      i++;
      continue;
    }
    if (chl == 'r') {
      flush();
      spans.add(PhoneticSpan(ch, PhoneticFeature.r));
      i++;
      continue;
    }
    buf.write(ch);
    i++;
  }
  flush();
  return spans;
}

// ---------------------------------------------------------------------------
// Farsi script tokenizer
// ---------------------------------------------------------------------------

/// Map of Farsi characters to their phonetic features.
const _farsiHighlights = <String, PhoneticFeature>{
  'خ': PhoneticFeature.kh,
  'غ': PhoneticFeature.gh,
  'ق': PhoneticFeature.gh,
  'ر': PhoneticFeature.r,
  'ش': PhoneticFeature.sh,
  // Long alef forms
  'آ': PhoneticFeature.openA,
  'ا': PhoneticFeature.openA, // will refine below
};

/// Tokenise a Farsi string into PhoneticSpans.
List<PhoneticSpan> tokenizeFarsi(String text) {
  if (text.isEmpty) return [];
  final spans = <PhoneticSpan>[];
  final buf = StringBuffer();

  void flush() {
    if (buf.isNotEmpty) {
      spans.add(PhoneticSpan(buf.toString()));
      buf.clear();
    }
  }

  for (int i = 0; i < text.length; i++) {
    final ch = text[i];
    // آ is always long open-a
    if (ch == 'آ') {
      flush();
      spans.add(PhoneticSpan(ch, PhoneticFeature.openA));
      continue;
    }
    // ا after a vowel-less consonant is long a; heuristic: highlight
    if (ch == 'ا') {
      flush();
      spans.add(PhoneticSpan(ch, PhoneticFeature.openA));
      continue;
    }
    final feature = _farsiHighlights[ch];
    if (feature != null) {
      flush();
      spans.add(PhoneticSpan(ch, feature));
    } else {
      buf.write(ch);
    }
  }
  flush();
  return spans;
}

// ---------------------------------------------------------------------------
// TextSpan builder
// ---------------------------------------------------------------------------

TextSpan buildPhoneticTextSpan(
  List<PhoneticSpan> spans,
  TextStyle baseStyle, {
  bool boldHighlights = true,
}) {
  return TextSpan(
    children: spans.map((span) {
      if (span.feature == null) {
        return TextSpan(text: span.text, style: baseStyle);
      }
      final color = PhoneticColors.forFeature(span.feature!);
      return TextSpan(
        text: span.text,
        style: baseStyle.copyWith(
          color: color,
          fontWeight: boldHighlights ? FontWeight.bold : null,
          decoration: TextDecoration.underline,
          decorationColor: color,
          decorationThickness: 2,
        ),
      );
    }).toList(),
  );
}
