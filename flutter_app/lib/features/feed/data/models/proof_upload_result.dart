class ProofUploadResult {
  const ProofUploadResult({
    required this.url,
    required this.publicId,
    required this.provider,
    required this.width,
    required this.height,
    required this.bytes,
    required this.format,
  });

  final String url;
  final String publicId;
  final String provider;
  final int width;
  final int height;
  final int bytes;
  final String format;

  factory ProofUploadResult.fromJson(Map<String, dynamic> json) {
    return ProofUploadResult(
      url: json['url'] as String? ?? '',
      publicId: json['publicId'] as String? ?? '',
      provider: json['provider'] as String? ?? 'cloudinary',
      width: _asInt(json['width']),
      height: _asInt(json['height']),
      bytes: _asInt(json['bytes']),
      format: json['format'] as String? ?? 'jpg',
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}
