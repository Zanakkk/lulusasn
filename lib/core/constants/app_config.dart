/// Application Configuration
/// All app-wide constants and settings
class AppConfig {
  AppConfig._(); // Private constructor

  // ============================================================================
  // APP INFO
  // ============================================================================

  static const String appName = 'LULUZZZ';
  static const String appDescription = 'Platform Latihan Ujian Nasional';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // ============================================================================
  // ENERGY SYSTEM
  // ============================================================================

  // Free User Energy
  static const int freeMaxEnergy = 5;
  static const int freeRegenMinutes = 10; // 1 energy per 10 minutes

  // Premium User Energy
  static const int premiumMaxEnergy = 10;
  static const int premiumRegenMinutes = 5; // 1 energy per 5 minutes

  // Energy Costs
  static const int energyPerExam = 1;
  static const int diamondPerRefill = 1; // 1 diamond = full refill

  // ============================================================================
  // EXAM SETTINGS
  // ============================================================================

  static const int questionsPerExam = 10;
  static const int secondsPerQuestion = 90; // 1.5 minutes
  static const int totalExamSeconds = questionsPerExam * secondsPerQuestion;

  // Question difficulty range
  static const int minDifficulty = 0;
  static const int maxDifficulty = 100;

  // Adaptive question distribution (out of 10 questions)
  static const int weakAreaQuestions = 4;      // 40% weak areas
  static const int currentLevelQuestions = 4;  // 40% current level
  static const int challengingQuestions = 2;   // 20% challenging

  // Anti-repetition days
  static const int questionRepeatCooldownDays = 7;

  // ============================================================================
  // XP & LEVELING
  // ============================================================================

  static const int xpPerCorrectAnswer = 10;
  static const int xpPerWrongAnswer = 2; // Participation XP
  static const int bonusXpPerfectScore = 50; // 10/10 correct
  static const int bonusXpFirstExamDaily = 20;

  // XP required per level (exponential growth)
  static int xpForLevel(int level) {
    return (100 * level * 1.2).round();
  }

  // ============================================================================
  // STREAK SYSTEM
  // ============================================================================

  // Streak milestones and rewards
  static const Map<int, Map<String, dynamic>> streakRewards = {
    3: {'xp': 50, 'diamond': 0, 'badge': 'Konsisten'},
    7: {'xp': 100, 'diamond': 1, 'badge': 'Semangat'},
    14: {'xp': 200, 'diamond': 2, 'badge': 'Tekun'},
    30: {'xp': 500, 'diamond': 5, 'badge': 'Dedikasi'},
    60: {'xp': 1000, 'diamond': 10, 'badge': 'Juara'},
    100: {'xp': 2000, 'diamond': 20, 'badge': 'Legenda'},
  };

  // Streak notification time (19:00 local time)
  static const int streakReminderHour = 19;
  static const int streakReminderMinute = 0;

  // ============================================================================
  // DIAMOND SYSTEM
  // ============================================================================

  static const int diamondValueRupiah = 10000; // 1 Diamond = Rp 10.000

  // Diamond packages
  static const Map<int, int> diamondPackages = {
    5: 50000,    // 5 Diamond = Rp 50.000
    10: 95000,   // 10 Diamond = Rp 95.000 (save 5%)
    25: 225000,  // 25 Diamond = Rp 225.000 (save 10%)
  };

  // Diamond usage
  static const int diamondForEnergyRefill = 1;
  static const int diamondForPremiumMonth = 5;
  static const int diamondForStreakFreeze = 1;

  // ============================================================================
  // PREMIUM SUBSCRIPTION
  // ============================================================================

  static const int premiumMonthlyPrice = 49000; // Rp 49.000/bulan
  static const int premiumQuarterlyPrice = 132000; // Rp 44K/bulan (save 10%)
  static const int premiumYearlyPrice = 480000; // Rp 40K/bulan (save 18%)

  static const int premiumDurationDays = 30;

  // ============================================================================
  // ADS CONFIGURATION
  // ============================================================================

  // Ad eCPM (for estimation only - actual from AdMob)
  static const double bannerAdEcpm = 500;        // Rp 500 per 1000 impressions
  static const double interstitialAdEcpm = 3000; // Rp 3.000 per 1000 impressions
  static const double rewardedAdEcpm = 8000;     // Rp 8.000 per 1000 impressions

  // Rewarded ad cooldown (prevent spam)
  static const int rewardedAdCooldownSeconds = 60;

  // Rewarded ad energy reward
  static const int rewardedAdEnergyReward = 1;

  // ============================================================================
  // LEADERBOARD
  // ============================================================================

  static const int leaderboardTopCount = 100; // Top 100 users
  static const int leaderboardRefreshMinutes = 15; // Refresh every 15 minutes

  // ============================================================================
  // CATEGORIES
  // ============================================================================

  static const List<String> examCategories = ['TWK', 'TIU', 'TKP'];

  static const Map<String, String> categoryNames = {
    'TWK': 'Tes Wawasan Kebangsaan',
    'TIU': 'Tes Intelegensi Umum',
    'TKP': 'Tes Karakteristik Pribadi',
  };

  static const Map<String, String> categoryDescriptions = {
    'TWK': 'Nasionalisme, Pancasila, UUD 1945, NKRI',
    'TIU': 'Logika, Numerik, Verbal, Figural',
    'TKP': 'Integritas, Kerjasama, Orientasi Pelayanan',
  };

  // ============================================================================
  // QUESTION TYPES
  // ============================================================================

  static const String questionTypeYesNo = 'yesno';
  static const String questionTypeLikert = 'likert';
  static const String questionTypeObjective = 'objective';

  static const List<String> questionTypes = [
    questionTypeYesNo,
    questionTypeLikert,
    questionTypeObjective,
  ];

  // ============================================================================
  // PAGINATION
  // ============================================================================

  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ============================================================================
  // CACHE DURATION
  // ============================================================================

  static const int userProfileCacheMinutes = 5;
  static const int leaderboardCacheMinutes = 15;
  static const int questionsCacheMinutes = 30;

  // ============================================================================
  // FILE SIZE LIMITS
  // ============================================================================

  static const int maxProfileImageSizeKB = 2048; // 2MB
  static const int maxCsvFileSizeMB = 10;

  // ============================================================================
  // VALIDATION
  // ============================================================================

  static const int minPasswordLength = 6;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;

  // ============================================================================
  // FLIP PAYMENT GATEWAY
  // ============================================================================

  static const String flipApiUrl = 'https://bigflip.id/api/v2/pwf/bill';
  static const double flipFeePercentage = 2.5; // 2.5% transaction fee
  static const int paymentExpiryHours = 24;

  // ============================================================================
  // FIREBASE COLLECTIONS
  // ============================================================================

  static const String usersCollection = 'users';
  static const String questionsCollection = 'questions';
  static const String examsCollection = 'exams';
  static const String answersCollection = 'answers';
  static const String paymentsCollection = 'payments';
  static const String leaderboardCollection = 'leaderboard';
  static const String adminsCollection = 'admins';

  // ============================================================================
  // URLS
  // ============================================================================

  static const String termsUrl = 'https://lulusasn.app/terms';
  static const String privacyUrl = 'https://lulusasn.app/privacy';
  static const String supportEmail = 'support@lulusasn.app';
  static const String feedbackUrl = 'https://lulusasn.app/feedback';

  // ============================================================================
  // RESPONSIVE BREAKPOINTS
  // ============================================================================

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Helper methods
  static bool isMobile(double width) => width < mobileBreakpoint;
  static bool isTablet(double width) =>
      width >= mobileBreakpoint && width < desktopBreakpoint;
  static bool isDesktop(double width) => width >= desktopBreakpoint;

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================

  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // ============================================================================
  // FEATURE FLAGS (for development)
  // ============================================================================

  static const bool enableAds = true;
  static const bool enablePayments = true;
  static const bool enableLeaderboard = true;
  static const bool enablePremium = true;
  static const bool enableDiamonds = true;

  // Debug mode
  static const bool isDebugMode = true; // Set to false in production

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Calculate net revenue after Flip fee
  static int calculateNetRevenue(int grossAmount) {
    final fee = (grossAmount * flipFeePercentage / 100).round();
    return grossAmount - fee;
  }

  /// Get energy regen rate based on premium status
  static int getEnergyRegenRate(bool isPremium) {
    return isPremium ? premiumRegenMinutes : freeRegenMinutes;
  }

  /// Get max energy based on premium status
  static int getMaxEnergy(bool isPremium) {
    return isPremium ? premiumMaxEnergy : freeMaxEnergy;
  }

  /// Calculate time until next energy
  static Duration timeUntilNextEnergy(bool isPremium) {
    final minutes = getEnergyRegenRate(isPremium);
    return Duration(minutes: minutes);
  }
}