/// 「182 KB」 under a megabyte (at least 1 KB), else 「1.2 MB」.
String sizeText(int bytes) {
  const kb = 1024;
  if (bytes < kb * kb) return '${(bytes / kb).round().clamp(1, kb)} KB';
  return '${(bytes / (kb * kb)).toStringAsFixed(1)} MB';
}
