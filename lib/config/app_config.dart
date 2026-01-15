/// Application-wide configuration settings.
///
/// This class centralizes all hardcoded values for easy maintenance
/// and environment-specific customization.
class AppConfig {
  // Prevent instantiation
  AppConfig._();

  // ==================== SERVER CONFIGURATION ====================



  /// WebSocket server URL
  ///
  /// Supports environment variable override via CARO_CHESS_SERVER_URL
  /// Format: ws://host:port/ws
  static const String serverUrl = String.fromEnvironment(
      'CARO_CHESS_SERVER_URL', defaultValue: _defaultServerUrl);

  static const String _defaultServerUrl = 'ws://localhost:8080/ws';

  /// Auth server URL (HTTP)
  ///
  /// Supports environment variable override via CARO_CHESS_AUTH_URL
  /// Format: http://host:port
  static const String authUrl = String.fromEnvironment(
      'CARO_CHESS_AUTH_URL', defaultValue: _defaultAuthUrl);

  static const String _defaultAuthUrl = 'http://localhost:8080';
  // ==================== GAME CONFIGURATION ====================

  /// Default game board dimensions
  static const int boardRows = 15;
  static const int boardColumns = 15;

  // ==================== AI CONFIGURATION ====================

  /// Minimax search depth for each AI difficulty level
  static const Map<AIDifficulty, int> aiDepths = {
    AIDifficulty.easy: 1,
    AIDifficulty.medium: 2,
    AIDifficulty.hard: 4,
  };

  /// Default AI difficulty
  static const AIDifficulty defaultAIDifficulty = AIDifficulty.medium;

  // ==================== UI CONFIGURATION ====================

  /// Duration for victory confetti animation
  static const Duration victoryConfettiDuration = Duration(seconds: 3);

  /// Connection timeout for WebSocket
  static const Duration connectionTimeout = Duration(seconds: 10);

  /// Reconnection delay interval
  static const Duration reconnectionDelay = Duration(seconds: 3);

  /// Maximum reconnection attempts
  static const int maxReconnectionAttempts = 5;

  // ==================== COSMETICS ====================

  /// Default board skin ID
  static const String defaultBoardSkin = 'light_board';

  /// Default piece skin ID
  static const String defaultPieceSkin = 'default_piece';

  // ==================== MATCHMAKING ====================

  /// Maximum ELO difference for matchmaking (±)
  static const int matchmakingEloRange = 200;

  /// Matchmaking timeout
  static const Duration matchmakingTimeout = Duration(seconds: 30);
}

/// AI Difficulty levels
enum AIDifficulty { easy, medium, hard }
