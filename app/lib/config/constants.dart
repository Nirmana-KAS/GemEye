class AppConstants {
  // API
  static const String apiBaseUrl = 'http://localhost:5000';
  static const String gradeEndpoint = '/grade';
  static const String calibrateEndpoint = '/calibrate';

  // App Info
  static const String appName = 'GemEye';
  static const String appTagline = 'Automated Blue Sapphire Colour Grading';
  static const String appVersion = '1.0';
  static const String appYear = '2026';
  static const String developerName = 'Nirmana K.A.S.';
  static const String studentNo = '28973';

  // Certificate
  static const String defaultCertificatePrefix = 'GE';

  // Calibration
  static const int requiredPatches = 6;
  static const double maxAcceptableDeltaE = 2.0;

  // Capture
  static const double minBlurThreshold = 100.0;
  static const int minLuxGood = 300;
  static const int minLuxLow = 100;

  // ML
  static const double cnnWeight = 0.65;
  static const double rfWeight = 0.35;
  static const int mcDropoutPasses = 10;

  // Grade names
  static const List<String> gradeNames = [
    'Dark', 'Deep', 'Vivid', 'Intense', 'Medium Intense', 'Light', 'Very Light',
  ];

  static const List<String> tradeNames = [
    'Midnight Blue', 'Twilight Blue', 'Royal Blue', 'Intense Cornflower',
    'Cornflower Blue', 'Pastel Blue', 'Near-Colourless',
  ];

  static const List<String> gradeColors = [
    '#020519', '#0B0F3F', '#091A72', '#2A408C', '#47619E', '#718BB7', '#ABBDD6',
  ];

  // Links
  static const String linkedInUrl = '';
  static const String githubUrl = 'https://github.com/Nirmana-KAS';
  static const String emailAddress = '';
}