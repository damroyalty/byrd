library utils;

DateTime? extractReplacementDate(String notes) {
  final match = RegExp(
    r'Replacement Date:\s*([0-9]{4}-[0-9]{2}-[0-9]{2})',
  ).firstMatch(notes);
  if (match != null) {
    return DateTime.tryParse(match.group(1)!);
  }
  return null;
}

String formatReplacementDate(DateTime date) {
  return '${date.month}/${date.day}/${date.year}';
}