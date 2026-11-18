class AppConstants {
  // Storage Keys
  static const String accessTokenKey = 'datamint_access_token';
  static const String refreshTokenKey = 'datamint_refresh_token';
  static const String activeWorkspaceKey = 'datamint_active_workspace';
  static const String linkedWalletKey = 'datamint_linked_wallet';
  static const String themeModeKey = 'datamint_theme_mode';

  // Network
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 25);
  static const Duration sendTimeout = Duration(seconds: 60);

  // Pagination
  static const int defaultPageSize = 20;

  // Validation Limits
  static const int minPasswordLength = 8;
  static const int maxAudioDurationSeconds = 300; // 5 minutes
  static const int maxImageBytes = 10 * 1024 * 1024; // 10 MB
}

enum WorkspaceRole {
  contributor,
  creator,
}

enum DataModality {
  text,
  voice,
  image,
}

extension DataModalityExt on DataModality {
  String toBackendString() {
    switch (this) {
      case DataModality.text:
        return 'TEXT';
      case DataModality.voice:
        return 'VOICE';
      case DataModality.image:
        return 'IMAGE';
    }
  }

  static DataModality fromString(String val) {
    switch (val.toUpperCase()) {
      case 'VOICE':
      case 'AUDIO':
        return DataModality.voice;
      case 'IMAGE':
        return DataModality.image;
      case 'TEXT':
      default:
        return DataModality.text;
    }
  }
}
