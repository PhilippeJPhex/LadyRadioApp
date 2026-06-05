class DateTextFormatter {
  static const Map<String, String> _monthNames = {
    'jan': 'gennaio',
    'january': 'gennaio',
    'feb': 'febbraio',
    'february': 'febbraio',
    'mar': 'marzo',
    'march': 'marzo',
    'apr': 'aprile',
    'april': 'aprile',
    'may': 'maggio',
    'jun': 'giugno',
    'june': 'giugno',
    'jul': 'luglio',
    'july': 'luglio',
    'aug': 'agosto',
    'august': 'agosto',
    'sep': 'settembre',
    'sept': 'settembre',
    'september': 'settembre',
    'oct': 'ottobre',
    'october': 'ottobre',
    'nov': 'novembre',
    'november': 'novembre',
    'dec': 'dicembre',
    'december': 'dicembre',
  };

  static const Map<String, String> _weekdayNames = {
    'mon': 'lunedi',
    'monday': 'lunedi',
    'tue': 'martedi',
    'tuesday': 'martedi',
    'wed': 'mercoledi',
    'wednesday': 'mercoledi',
    'thu': 'giovedi',
    'thursday': 'giovedi',
    'fri': 'venerdi',
    'friday': 'venerdi',
    'sat': 'sabato',
    'saturday': 'sabato',
    'sun': 'domenica',
    'sunday': 'domenica',
  };

  static String monthShortUpperFromRss(String rawDate) {
    final parsed = _parseRssDateParts(rawDate);
    if (parsed == null) return '';

    final month = _monthNames[parsed.month.toLowerCase()];
    if (month == null || month.length < 3) return parsed.month.toUpperCase();
    return month.substring(0, 3).toUpperCase();
  }

  static String dayFromRss(String rawDate) {
    return _parseRssDateParts(rawDate)?.day ?? '';
  }

  static String episodeDate(String rawDate) {
    final parsed = _parseRssDateParts(rawDate);
    if (parsed != null) {
      final month = _monthNames[parsed.month.toLowerCase()] ?? parsed.month;
      final day = int.tryParse(parsed.day)?.toString() ?? parsed.day;
      return '$day $month ${parsed.year}';
    }

    return italianizeText(rawDate);
  }

  static String episodeDateCapitalized(String rawDate) {
    final date = episodeDate(rawDate);
    final parts = date.split(' ');
    if (parts.length < 3) return date;

    final month = parts[1];
    final capitalizedMonth = month.isEmpty
        ? month
        : month[0].toUpperCase() + month.substring(1);
    return '${parts[0]} $capitalizedMonth ${parts[2]}';
  }

  static String italianizeText(String text) {
    var result = text;
    final replacements = {..._weekdayNames, ..._monthNames};

    replacements.forEach((english, italian) {
      result = result.replaceAllMapped(
        RegExp('\\b$english\\b', caseSensitive: false),
        (_) => italian,
      );
    });

    return result;
  }

  static _RssDateParts? _parseRssDateParts(String rawDate) {
    final match = RegExp(
      r'(?:[A-Za-z]{3,9},\s*)?(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{4})',
    ).firstMatch(rawDate);

    if (match == null) return null;
    return _RssDateParts(
      day: match.group(1)!,
      month: match.group(2)!,
      year: match.group(3)!,
    );
  }
}

class _RssDateParts {
  final String day;
  final String month;
  final String year;

  const _RssDateParts({
    required this.day,
    required this.month,
    required this.year,
  });
}
