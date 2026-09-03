/// Converts numeric currency values to Indian English words
/// Example: 180 -> "Rupees One Hundred and Eighty Only"
/// Example: 12500 -> "Rupees Twelve Thousand Five Hundred Only"
class NumberToWords {
  NumberToWords._();

  static const List<String> _units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  static const List<String> _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  static String convert(double amount) {
    final int rupees = amount.floor();
    final int paise = ((amount - rupees) * 100).round();

    if (rupees == 0 && paise == 0) {
      return 'Rupees Zero Only';
    }

    String result = '';
    if (rupees > 0) {
      result = 'Rupees ${_convertInteger(rupees)}';
    }

    if (paise > 0) {
      if (result.isNotEmpty) {
        result += ' and ${_convertInteger(paise)} Paise';
      } else {
        result = '${_convertInteger(paise)} Paise';
      }
    }

    return '$result Only';
  }

  static String _convertInteger(int n) {
    if (n == 0) return 'Zero';

    String words = '';

    // Crores (1,00,00,000)
    if ((n ~/ 10000000) > 0) {
      words += '${_convertInteger(n ~/ 10000000)} Crore ';
      n %= 10000000;
    }

    // Lakhs (1,00,000)
    if ((n ~/ 100000) > 0) {
      words += '${_convertThreeDigits(n ~/ 100000)} Lakh ';
      n %= 100000;
    }

    // Thousands (1,000)
    if ((n ~/ 1000) > 0) {
      words += '${_convertThreeDigits(n ~/ 1000)} Thousand ';
      n %= 1000;
    }

    // Hundreds (100)
    if ((n ~/ 100) > 0) {
      words += '${_units[n ~/ 100]} Hundred ';
      n %= 100;
    }

    if (n > 0) {
      if (words.isNotEmpty) {
        words += 'and ';
      }
      if (n < 20) {
        words += _units[n];
      } else {
        words += _tens[n ~/ 10];
        if ((n % 10) > 0) {
          words += ' ${_units[n % 10]}';
        }
      }
    }

    return words.trim();
  }

  static String _convertThreeDigits(int n) {
    String words = '';
    if ((n ~/ 100) > 0) {
      words += '${_units[n ~/ 100]} Hundred ';
      n %= 100;
    }
    if (n > 0) {
      if (words.isNotEmpty) words += 'and ';
      if (n < 20) {
        words += _units[n];
      } else {
        words += _tens[n ~/ 10];
        if ((n % 10) > 0) {
          words += ' ${_units[n % 10]}';
        }
      }
    }
    return words.trim();
  }
}
