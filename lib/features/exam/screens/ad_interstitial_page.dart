// ============================================================================
// FLUTTER ADMOB SYSTEM - PRODUCTION READY
// ============================================================================
//
// Quick Start:
// 1. Initialize: await AdService.initialize();
// 2. Banner: AdBannerWidget(placement: AdPlacement.examResult)
// 3. Interstitial: await AdInterstitialController.show()
// 4. Rewarded: AdRewardedWidget(reward: AdReward(type: 'coins', amount: 50))
//
// ============================================================================

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../app/routes.dart';
import '../models/exam_result_model.dart';

// ============================================================================
// 1. AD CONFIGURATION
// ============================================================================

class AdConfig {
  AdConfig._();

  // ============================================================================
  // PRODUCTION IDS (Your Real AdMob IDs)
  // ============================================================================

  static const String androidAppId = 'ca-app-pub-9707055103686235~5119702290';
  static const String androidBannerId = 'ca-app-pub-9707055103686235/7468671649';
  static const String androidInterstitialId = 'ca-app-pub-9707055103686235/9409822163';
  static const String androidRewardedId = 'ca-app-pub-9707055103686235/1126624570';
  static const String androidRewardedInterstitialId = 'ca-app-pub-9707055103686235/2439706249';
  static const String androidNativeId = 'ca-app-pub-9707055103686235/8813542900';

  // ============================================================================
  // IOS IDS (Replace when you have iOS app)
  // ============================================================================

  static const String iosAppId = 'ca-app-pub-9707055103686235~5119702290'; // Update with iOS App ID when available
  static const String iosBannerId = 'ca-app-pub-9707055103686235/7468671649'; // Update with iOS Banner ID
  static const String iosInterstitialId = 'ca-app-pub-9707055103686235/9409822163'; // Update with iOS Interstitial ID
  static const String iosRewardedId = 'ca-app-pub-9707055103686235/1126624570'; // Update with iOS Rewarded ID
  static const String iosRewardedInterstitialId = 'ca-app-pub-9707055103686235/2439706249'; // Update with iOS Rewarded Interstitial ID
  static const String iosNativeId = 'ca-app-pub-9707055103686235/8813542900'; // Update with iOS Native ID

  // ============================================================================
  // GOOGLE TEST IDS (For Development/Testing ONLY)
  // ============================================================================

  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String testRewardedInterstitialId = 'ca-app-pub-3940256099942544/5354046379';
  static const String testNativeId = 'ca-app-pub-3940256099942544/2247696110';

  // ============================================================================
  // AD TIMING
  // ============================================================================

  static const int skipDelaySeconds = 5;
  static const int maxDisplaySeconds = 30;

  // ============================================================================
  // FEATURE FLAGS
  // ============================================================================

  static bool get adsEnabled => true; // Set false to disable all ads
  static bool get isProduction => kReleaseMode;
  static bool get isTest => kDebugMode;

  // ============================================================================
  // AD ID GETTERS (Auto-switch between Test and Production)
  // ============================================================================

  static String get appId {
    if (kIsWeb) return '';
    if (isTest) return ''; // Test mode doesn't need app ID
    return Platform.isAndroid ? androidAppId : iosAppId;
  }

  static String getBannerId() {
    if (kIsWeb) return '';
    if (isTest) return testBannerId;
    return Platform.isAndroid ? androidBannerId : iosBannerId;
  }

  static String getInterstitialId() {
    if (kIsWeb) return '';
    if (isTest) return testInterstitialId; // ✅ Google's test ID in debug
    return Platform.isAndroid ? androidInterstitialId : iosInterstitialId; // ✅ Your real ID in release
  }

  static String getRewardedId() {
    if (kIsWeb) return '';
    if (isTest) return testRewardedId; // ✅ Google's test ID in debug
    return Platform.isAndroid ? androidRewardedId : iosRewardedId; // ✅ Your real ID in release
  }

  static String getRewardedInterstitialId() {
    if (kIsWeb) return '';
    if (isTest) return testRewardedInterstitialId; // ✅ Google's test ID in debug
    return Platform.isAndroid ? androidRewardedInterstitialId : iosRewardedInterstitialId; // ✅ Your real ID in release
  }

  static String getNativeId() {
    if (kIsWeb) return '';
    if (isTest) return testNativeId; // ✅ Google's test ID in debug
    return Platform.isAndroid ? androidNativeId : iosNativeId; // ✅ Your real ID in release
  }
}

// ============================================================================
// 2. AD PLACEMENT ENUM
// ============================================================================

enum AdPlacement { bannerTop, bannerBottom, examResult, homeScreen }

// ============================================================================
// 3. AD REWARD MODEL
// ============================================================================

class AdReward {
  final String type;
  final int amount;
  final String? description;

  const AdReward({required this.type, required this.amount, this.description});
}

// ============================================================================
// 4. AD SERVICE - INITIALIZATION
// ============================================================================

class AdService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('✅ AdMob initialized successfully');
    } catch (e) {
      debugPrint('❌ AdMob initialization failed: $e');
    }
  }
}

// ============================================================================
// 5. BANNER AD WIDGET
// ============================================================================

class AdBannerWidget extends StatefulWidget {
  final AdPlacement placement;
  final bool showLabel;
  final EdgeInsets margin;

  const AdBannerWidget({
    super.key,
    required this.placement,
    this.showLabel = true,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    final adId = AdConfig.getBannerId();

    _bannerAd = BannerAd(
      adUnitId: adId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _isLoaded = true);
            debugPrint('✅ Banner ad loaded: ${widget.placement.name}');
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner ad failed: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showLabel)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Advertisement',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Container(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AdWidget(ad: _bannerAd!),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. INTERSTITIAL AD CONTROLLER
// ============================================================================

class AdInterstitialController {
  static InterstitialAd? _interstitialAd;
  static bool _isLoaded = false;
  static bool _isLoading = false;

  static Future<void> load() async {
    if (kIsWeb || _isLoading || _isLoaded) return;

    _isLoading = true;
    final adId = AdConfig.getInterstitialId();

    try {
      await InterstitialAd.load(
        adUnitId: adId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isLoaded = true;
            _isLoading = false;
            _setupCallbacks();
            debugPrint('✅ Interstitial ad loaded');
          },
          onAdFailedToLoad: (error) {
            _isLoading = false;
            debugPrint('❌ Interstitial ad failed: $error');
          },
        ),
      );
    } catch (e) {
      _isLoading = false;
      debugPrint('❌ Interstitial ad error: $e');
    }
  }

  static void _setupCallbacks() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isLoaded = false;
        load(); // Preload next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ Failed to show interstitial: $error');
        ad.dispose();
        _interstitialAd = null;
        _isLoaded = false;
      },
    );
  }

  static Future<bool> show({VoidCallback? onAdClosed}) async {
    if (kIsWeb) return false;

    if (!_isLoaded || _interstitialAd == null) {
      debugPrint('⚠️ Interstitial ad not ready');
      await load();
      return false;
    }

    try {
      await _interstitialAd!.show();
      onAdClosed?.call();
      return true;
    } catch (e) {
      debugPrint('❌ Error showing interstitial: $e');
      return false;
    }
  }

  static bool get isReady => _isLoaded && _interstitialAd != null;

  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoaded = false;
  }
}

// ============================================================================
// 7. REWARDED AD WIDGET
// ============================================================================

class AdRewardedWidget extends StatefulWidget {
  final AdReward reward;
  final Function(AdReward) onRewarded;
  final VoidCallback? onAdClosed;
  final Widget? customButton;

  const AdRewardedWidget({
    super.key,
    required this.reward,
    required this.onRewarded,
    this.onAdClosed,
    this.customButton,
  });

  @override
  State<AdRewardedWidget> createState() => _AdRewardedWidgetState();
}

class _AdRewardedWidgetState extends State<AdRewardedWidget> {
  RewardedAd? _rewardedAd;
  bool _isLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _loadAd();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final adId = AdConfig.getRewardedId();

    RewardedAd.load(
      adUnitId: adId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _rewardedAd = ad;
              _isLoaded = true;
              _isLoading = false;
            });
            _setupCallbacks();
            debugPrint('✅ Rewarded ad loaded');
          }
        },
        onAdFailedToLoad: (error) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
          debugPrint('❌ Rewarded ad failed: $error');
        },
      ),
    );
  }

  void _setupCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (mounted) {
          setState(() {
            _rewardedAd = null;
            _isLoaded = false;
          });
        }
        widget.onAdClosed?.call();
        _loadAd(); // Reload for next time
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ Failed to show rewarded ad: $error');
        ad.dispose();
        if (mounted) {
          setState(() {
            _rewardedAd = null;
            _isLoaded = false;
          });
        }
      },
    );
  }

  Future<void> _showAd() async {
    if (!_isLoaded || _rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad is not ready yet. Please try again.')),
      );
      return;
    }

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint(
          '🎁 User earned reward: ${widget.reward.amount} ${widget.reward.type}',
        );
        widget.onRewarded(widget.reward);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.customButton != null) {
      return GestureDetector(
        onTap: _isLoaded ? _showAd : null,
        child: Opacity(
          opacity: _isLoaded ? 1.0 : 0.5,
          child: widget.customButton,
        ),
      );
    }

    return _buildDefaultButton();
  }

  Widget _buildDefaultButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: _isLoaded ? const Color(0xFF58CC02) : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
        elevation: _isLoaded ? 4 : 0,
        child: InkWell(
          onTap: _isLoaded ? _showAd : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isLoading
                        ? Icons.hourglass_empty
                        : Icons.play_circle_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLoading ? 'Loading ad...' : 'Watch ad to earn',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.reward.amount} ${widget.reward.type}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.reward.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.reward.description!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 8. INTERSTITIAL AD SCREEN (Full-screen with timer)
// ============================================================================

// ============================================================================
// 8. INTERSTITIAL AD SCREEN - WEB + MOBILE SUPPORT
// ============================================================================

class AdInterstitialScreen extends StatefulWidget {
  final ExamResultModel result;

  const AdInterstitialScreen({super.key, required this.result});

  @override
  State<AdInterstitialScreen> createState() => _AdInterstitialScreenState();
}

class _AdInterstitialScreenState extends State<AdInterstitialScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _secondsRemaining = AdConfig.skipDelaySeconds;
  bool _canSkip = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startTimer();

    // Show AdMob for mobile only
    if (!kIsWeb) {
      _showAd();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _canSkip = true;
            timer.cancel();
          }
        });
      }
    });

    Future.delayed(const Duration(seconds: AdConfig.maxDisplaySeconds), () {
      if (mounted) _navigateNext();
    });
  }

  Future<void> _showAd() async {
    final shown = await AdInterstitialController.show();
    if (!shown && mounted) {
      setState(() => _canSkip = true);
    }
  }

  void _navigateNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.examResult,
      arguments: {'result': widget.result},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF58CC02), Color(0xFF00A86B)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative circles
              _buildDecorativeCircles(),

              // Main content - WEB: Show AdSense, MOBILE: Show placeholder
              Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: kIsWeb ? _buildWebAdSense() : _buildMobilePlaceholder(),
                ),
              ),

              // Skip button
              Positioned(top: 20, right: 20, child: _buildSkipButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeCircles() {
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ WEB: Display AdSense
  Widget _buildWebAdSense() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF58CC02),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),

          const Text(
            'Great job!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3C3C3C),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Loading your results...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),

          const SizedBox(height: 32),

          // ✅ AdSense Placeholder (Google akan inject ad disini)
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ads_click, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'Advertisement',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AdSense will load here',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Info text
          Text(
            'Please wait while we prepare your exam results',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ MOBILE: Simple placeholder (ads shown via AdMob overlay)
  Widget _buildMobilePlaceholder() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF58CC02),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'Great job!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3C3C3C),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Preparing your results...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _canSkip ? Colors.white : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(_canSkip ? 1 : 0.3),
          width: 2,
        ),
        boxShadow: _canSkip
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canSkip ? _navigateNext : null,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_canSkip) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  _canSkip ? 'Continue' : '$_secondsRemaining',
                  style: TextStyle(
                    color: _canSkip ? const Color(0xFF58CC02) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_canSkip) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF58CC02),
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/*
// 1. Initialize in main.dart:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.initialize();
  runApp(MyApp());
}

// 2. Banner Ad:
AdBannerWidget(placement: AdPlacement.examResult)

// 3. Interstitial Ad (after quiz completion):
await AdInterstitialController.load(); // Preload
// Later:
await AdInterstitialController.show(onAdClosed: () {
  print('Ad closed');
});

// 4. Or use the full-screen interstitial page:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AdInterstitialScreen(
      nextRoute: '/results',
      result: quizResults,
    ),
  ),
);

// 5. Rewarded Ad:
AdRewardedWidget(
  reward: AdReward(
    type: 'coins',
    amount: 50,
    description: 'Use to unlock premium features',
  ),
  onRewarded: (reward) {
    print('User earned: ${reward.amount} ${reward.type}');
    // Add coins to user account
  },
)
*/
