class Formatters {
  static String currency(dynamic value) {
    final amount = (value ?? 0).toDouble();
    return '₹${amount.toStringAsFixed(2)}';
  }

  static String compactNumber(dynamic value) {
    final num = (value ?? 0).toDouble();
    if (num >= 10000000) return '${(num / 10000000).toStringAsFixed(2)}Cr';
    if (num >= 100000) return '${(num / 100000).toStringAsFixed(2)}L';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toStringAsFixed(0);
  }

  static String date(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final parts = isoDate.split('T')[0].split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (e) {
      return isoDate;
    }
  }

  static String fileSize(dynamic bytes) {
    final size = (bytes ?? 0).toDouble();
    if (size < 1024) return '${size.toStringAsFixed(0)} B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
