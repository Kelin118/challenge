class DeviceSession {
  const DeviceSession({
    required this.id,
    this.deviceName,
    this.platform,
    this.userAgent,
    this.ipAddress,
    this.createdAt,
    this.lastUsedAt,
    this.expiresAt,
  });

  final int id;
  final String? deviceName;
  final String? platform;
  final String? userAgent;
  final String? ipAddress;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;
  final DateTime? expiresAt;

  factory DeviceSession.fromJson(Map<String, dynamic> json) {
    return DeviceSession(
      id: json['id'] as int? ?? 0,
      deviceName: json['device_name'] as String?,
      platform: json['platform'] as String?,
      userAgent: json['user_agent'] as String?,
      ipAddress: json['ip_address'] as String?,
      createdAt: _parseDate(json['created_at']),
      lastUsedAt: _parseDate(json['last_used_at']),
      expiresAt: _parseDate(json['expires_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}

