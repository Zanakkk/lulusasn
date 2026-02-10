// ============================================================================
// FLUTTER WEB ADSENSE SYSTEM - FIXED VERSION
// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'dart:js' as js;

// ============================================================================
// 1. ADSENSE CONFIGURATION
// ============================================================================

// ============================================================================
// FLUTTER WEB ADSENSE SYSTEM - CLEAN VERSION (No dart:js)
// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// HANYA import yang diperlukan untuk web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

// ============================================================================
// 1. ADSENSE CONFIGURATION
// ============================================================================

class AdSenseConfig {
  static const String publisherId = 'ca-pub-9707055103686235';

  // Ad Unit IDs
  static const String displaySquareSlot = '4489630376';
  static const String displayHorizontalSlot = '9550385362';
  static const String displayVerticalSlot = '8237303698';
  static const String inFeedSlot = '8152816865';
  static const String inArticleSlot = '9686116738';

  // Layout keys
  static const String inFeedLayoutKey = '-6t+ed+2i-1n-4w';

  static bool get isEnabled => kIsWeb;
}

// ============================================================================
// 2. ADSENSE BASE WIDGET
// ============================================================================

class _AdSenseSimpleWidget extends StatefulWidget {
  final String adSlot;
  final String adFormat;
  final String? layoutKey;
  final String? layout;
  final double? height;
  final bool showLabel;
  final EdgeInsets margin;
  final String? textAlign;

  const _AdSenseSimpleWidget({
    required this.adSlot,
    required this.adFormat,
    this.layoutKey,
    this.layout,
    this.height,
    this.showLabel = true,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
    this.textAlign,
  });

  @override
  State<_AdSenseSimpleWidget> createState() => _AdSenseSimpleWidgetState();
}

class _AdSenseSimpleWidgetState extends State<_AdSenseSimpleWidget> {
  static int _adCounter = 0;
  late String _viewId;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _viewId = 'adsense-${widget.adSlot}-${_adCounter++}-${DateTime.now().millisecondsSinceEpoch}';
      _registerAdView();
    }
  }

  void _registerAdView() {
    if (_isRegistered) return;

    try {
      final adHtml = _buildCompleteAdHtml();

      final container = html.DivElement()
        ..id = _viewId
        ..style.width = '100%'
        ..style.height = widget.height != null ? '${widget.height}px' : 'auto'
        ..style.minHeight = '${widget.height ?? 100}px'
        ..setInnerHtml(adHtml, treeSanitizer: html.NodeTreeSanitizer.trusted);

      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _pushAd(container);
        });
        return container;
      });

      _isRegistered = true;
    } catch (e) {
      debugPrint('❌ AdSense registration error: $e');
    }
  }

  String _buildCompleteAdHtml() {
    final layoutKeyAttr = widget.layoutKey != null
        ? 'data-ad-layout-key="${widget.layoutKey}"'
        : '';
    final layoutAttr = widget.layout != null
        ? 'data-ad-layout="${widget.layout}"'
        : '';
    final textAlignStyle = widget.textAlign != null
        ? 'text-align:${widget.textAlign};'
        : '';

    return '''
      <ins class="adsbygoogle"
           style="display:block; ${textAlignStyle}"
           data-ad-client="${AdSenseConfig.publisherId}"
           data-ad-slot="${widget.adSlot}"
           data-ad-format="${widget.adFormat}"
           ${layoutKeyAttr}
           ${layoutAttr}
           data-full-width-responsive="true">
      </ins>
    ''';
  }

  void _pushAd(html.Element container) {
    try {
      final script = html.ScriptElement()
        ..type = 'text/javascript'
        ..text = '(adsbygoogle = window.adsbygoogle || []).push({});';

      container.append(script);
      debugPrint('✅ AdSense ad pushed: ${widget.adSlot}');
    } catch (e) {
      debugPrint('❌ AdSense push error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    return Container(
      margin: widget.margin,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.showLabel)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Advertisement',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: 800,
              minHeight: widget.height ?? 100,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: widget.height,
                child: HtmlElementView(viewType: _viewId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. AD WIDGETS
// ============================================================================

/// Display Square Ad (300x250, auto)
class AdSenseSimpleSquare extends StatelessWidget {
  final bool showLabel;
  final EdgeInsets margin;

  const AdSenseSimpleSquare({
    super.key,
    this.showLabel = true,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return _AdSenseSimpleWidget(
      adSlot: AdSenseConfig.displaySquareSlot,
      adFormat: 'auto',
      height: 280,
      showLabel: showLabel,
      margin: margin,
    );
  }
}

/// Display Horizontal Ad (728x90, auto)
class AdSenseSimpleHorizontal extends StatelessWidget {
  final bool showLabel;
  final EdgeInsets margin;

  const AdSenseSimpleHorizontal({
    super.key,
    this.showLabel = true,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return _AdSenseSimpleWidget(
      adSlot: AdSenseConfig.displayHorizontalSlot,
      adFormat: 'auto',
      height: 90,
      showLabel: showLabel,
      margin: margin,
    );
  }
}

/// Display Vertical Ad (160x600, auto)
class AdSenseSimpleVertical extends StatelessWidget {
  final bool showLabel;
  final EdgeInsets margin;

  const AdSenseSimpleVertical({
    super.key,
    this.showLabel = true,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return _AdSenseSimpleWidget(
      adSlot: AdSenseConfig.displayVerticalSlot,
      adFormat: 'auto',
      height: 600,
      showLabel: showLabel,
      margin: margin,
    );
  }
}

/// In-feed Ad (Native)
class AdSenseSimpleInFeed extends StatelessWidget {
  final bool showLabel;
  final EdgeInsets margin;

  const AdSenseSimpleInFeed({
    super.key,
    this.showLabel = false,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return _AdSenseSimpleWidget(
      adSlot: AdSenseConfig.inFeedSlot,
      adFormat: 'fluid',
      layoutKey: AdSenseConfig.inFeedLayoutKey,
      height: 120,
      showLabel: showLabel,
      margin: margin,
    );
  }
}

/// In-article Ad (Native)
class AdSenseSimpleInArticle extends StatelessWidget {
  final bool showLabel;
  final EdgeInsets margin;

  const AdSenseSimpleInArticle({
    super.key,
    this.showLabel = false,
    this.margin = const EdgeInsets.symmetric(vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return _AdSenseSimpleWidget(
      adSlot: AdSenseConfig.inArticleSlot,
      adFormat: 'fluid',
      layout: 'in-article',
      textAlign: 'center',
      height: 150,
      showLabel: showLabel,
      margin: margin,
    );
  }
}


// ============================================================================
// 2. ADSENSE BASE WIDGET
// ============================================================================

class _AdSenseBaseWidget extends StatefulWidget {
  final String adSlot;
  final String adFormat;
  final String? layoutKey;
  final String? layout;
  final String displayStyle;
  final double? height;
  final bool showLabel;
  final EdgeInsets margin;

  const _AdSenseBaseWidget({
    required this.adSlot,
    required this.adFormat,
    this.layoutKey,
    this.layout,
    this.displayStyle = 'block',
    this.height,
    this.showLabel = true,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  State<_AdSenseBaseWidget> createState() => _AdSenseBaseWidgetState();
}

class _AdSenseBaseWidgetState extends State<_AdSenseBaseWidget> {
  static int _adCounter = 0;
  late String _viewId;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _viewId =
          'adsense-${widget.adSlot}-${_adCounter++}-${DateTime.now().millisecondsSinceEpoch}';
      _registerAdView();
    }
  }

  void _registerAdView() {
    // Create the ad container
    final adElement = html.Element.html('''
      <ins class="adsbygoogle"
           style="display:${widget.displayStyle}; ${widget.height != null ? 'height:${widget.height}px;' : ''}"
           data-ad-client="${AdSenseConfig.publisherId}"
           data-ad-slot="${widget.adSlot}"
           data-ad-format="${widget.adFormat}"
           ${widget.layoutKey != null ? 'data-ad-layout-key="${widget.layoutKey}"' : ''}
           ${widget.layout != null ? 'data-ad-layout="${widget.layout}"' : ''}
           data-full-width-responsive="true">
      </ins>
    ''');

    // Register the view
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      // Push ad after a small delay to ensure DOM is ready
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          // Push the ad using js.context
          if (js.context.hasProperty('adsbygoogle')) {
            final adsbygoogle = js.context['adsbygoogle'] as js.JsArray;
            adsbygoogle.callMethod('push', [js.JsObject.jsify({})]);
          } else {
            debugPrint('⚠️ AdSense script not loaded yet');
          }
        } catch (e) {
          debugPrint('❌ AdSense push error: $e');
        }
      });

      return adElement;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.showLabel)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Advertisement',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: 800,
              minHeight: widget.height ?? 100,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: HtmlElementView(viewType: _viewId),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. DISPLAY ADS (Square, Horizontal, Vertical)
// ============================================================================

/// Display Ad - Square format (flexible size)
class AdSenseDisplaySquare extends StatelessWidget {
  final bool showLabel;
  final EdgeInsets margin;

  const AdSenseDisplaySquare({
    super.key,
    this.showLabel = true,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return _AdSenseBaseWidget(
      adSlot: AdSenseConfig.displaySquareSlot,
      adFormat: 'auto',
      displayStyle: 'block',
      height: 280,
      showLabel: showLabel,
      margin: margin,
    );
  }
}

/// Display Ad - Horizontal banner (728x90, 468x60, or responsive)
class AdSenseDisplayHorizontal extends StatelessWidget {
  final bool showLabel;
  final EdgeInsets margin;

  const AdSenseDisplayHorizontal({
    super.key,
    this.showLabel = true,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return _AdSenseBaseWidget(
      adSlot: AdSenseConfig.displayHorizontalSlot,
      adFormat: 'auto',
      displayStyle: 'block',
      height: 90,
      showLabel: showLabel,
      margin: margin,
    );
  }
}

/// Display Ad - Vertical skyscraper (160x600, 120x600, or responsive)
class AdSenseDisplayVertical extends StatelessWidget {
  final bool showLabel;
  final EdgeInsets margin;

  const AdSenseDisplayVertical({
    super.key,
    this.showLabel = true,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return _AdSenseBaseWidget(
      adSlot: AdSenseConfig.displayVerticalSlot,
      adFormat: 'auto',
      displayStyle: 'block',
      height: 600,
      showLabel: showLabel,
      margin: margin,
    );
  }
}

// ============================================================================
// 4. NATIVE ADS (In-feed, In-article)
// ============================================================================

/// In-feed Ad - Matches your content feed/list
class AdSenseInFeed extends StatelessWidget {
  final bool showLabel;
  final EdgeInsets margin;

  const AdSenseInFeed({
    super.key,
    this.showLabel = false,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return _AdSenseBaseWidget(
      adSlot: AdSenseConfig.inFeedSlot,
      adFormat: 'fluid',
      layoutKey: AdSenseConfig.inFeedLayoutKey,
      displayStyle: 'block',
      showLabel: showLabel,
      margin: margin,
    );
  }
}

/// In-article Ad - Flows naturally within article/content
class AdSenseInArticle extends StatelessWidget {
  final bool showLabel;
  final EdgeInsets margin;

  const AdSenseInArticle({
    super.key,
    this.showLabel = false,
    this.margin = const EdgeInsets.symmetric(vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return _AdSenseBaseWidget(
      adSlot: AdSenseConfig.inArticleSlot,
      adFormat: 'fluid',
      layout: 'in-article',
      displayStyle: 'block',
      showLabel: showLabel,
      margin: margin,
    );
  }
}

// ============================================================================
// 5. AD PLACEMENT HELPERS
// ============================================================================

/// Helper widget to show ads conditionally on web only
class WebOnlyAd extends StatelessWidget {
  final Widget webAd;
  final Widget? mobileWidget;

  const WebOnlyAd({super.key, required this.webAd, this.mobileWidget});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return webAd;
    }
    return mobileWidget ?? const SizedBox.shrink();
  }
}

// ============================================================================
// 6. RESPONSIVE AD WRAPPER
// ============================================================================

/// Automatically choose the best ad format based on screen size
class AdSenseResponsive extends StatelessWidget {
  final bool showLabel;
  final EdgeInsets margin;

  const AdSenseResponsive({
    super.key,
    this.showLabel = true,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile/Tablet: horizontal banner
        if (constraints.maxWidth < 728) {
          return AdSenseDisplayHorizontal(showLabel: showLabel, margin: margin);
        }
        // Desktop: square ad
        return AdSenseDisplaySquare(showLabel: showLabel, margin: margin);
      },
    );
  }
}



// ============================================================================
// ADS ONLY PAGE
// ============================================================================

class AdsOnlyPage extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final VoidCallback? onContinue;
  final int skipDelaySeconds;
  final bool showSkipButton;
  final Color? backgroundColor;
  final Widget? headerWidget;
  final Widget? footerWidget;

  const AdsOnlyPage({
    super.key,
    this.title,
    this.subtitle,
    this.onContinue,
    this.skipDelaySeconds = 5,
    this.showSkipButton = true,
    this.backgroundColor,
    this.headerWidget,
    this.footerWidget,
  });

  @override
  State<AdsOnlyPage> createState() => _AdsOnlyPageState();
}

class _AdsOnlyPageState extends State<AdsOnlyPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _canSkip = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.skipDelaySeconds;
    _initAnimations();
    if (widget.showSkipButton) {
      _startTimer();
    } else {
      _canSkip = true; // Langsung bisa skip jika showSkipButton = false
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
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
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
  }

  void _handleContinue() {
    if (!_canSkip) return;

    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content with ads
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildMainContent(),
            ),

            // Skip button (top-right)
            if (widget.showSkipButton)
              Positioned(
                top: 16,
                right: 16,
                child: _buildSkipButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Custom header widget (optional)
          if (widget.headerWidget != null) ...[
            widget.headerWidget!,
            const SizedBox(height: 24),
          ],

          // Default header (if no custom widget)
          if (widget.headerWidget == null) _buildDefaultHeader(),

          const SizedBox(height: 32),

          // ============================================
          // IKLAN 1: HORIZONTAL BANNER (Top)
          // ============================================
          if (kIsWeb)
            const AdSenseSimpleHorizontal(
              showLabel: true,
              margin: EdgeInsets.only(bottom: 24),
            ),

          // Divider
          _buildDivider('Featured Content'),
          const SizedBox(height: 16),

          // ============================================
          // IKLAN 2: SQUARE AD (Featured)
          // ============================================
          if (kIsWeb)
            const AdSenseSimpleSquare(
              showLabel: true,
              margin: EdgeInsets.only(bottom: 24),
            ),

          // Divider
          _buildDivider('Recommended'),
          const SizedBox(height: 16),

          // ============================================
          // IKLAN 3: IN-FEED AD (Native style)
          // ============================================
          if (kIsWeb)
            const AdSenseSimpleInFeed(
              showLabel: false,
              margin: EdgeInsets.only(bottom: 24),
            ),

          // Spacing
          const SizedBox(height: 16),

          // ============================================
          // IKLAN 4: SQUARE AD (Bottom)
          // ============================================
          if (kIsWeb)
            const AdSenseSimpleSquare(
              showLabel: true,
              margin: EdgeInsets.only(bottom: 24),
            ),

          // Divider
          _buildDivider('More Content'),
          const SizedBox(height: 16),

          // ============================================
          // IKLAN 5: HORIZONTAL BANNER (Bottom)
          // ============================================
          if (kIsWeb)
            const AdSenseSimpleHorizontal(
              showLabel: true,
              margin: EdgeInsets.only(bottom: 24),
            ),

          const SizedBox(height: 32),

          // Custom footer widget (optional)
          if (widget.footerWidget != null) widget.footerWidget!,

          // Bottom spacing
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDefaultHeader() {
    return Column(
      children: [
        // Icon/Emoji
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF58CC02).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.hourglass_empty,
            size: 48,
            color: Color(0xFF58CC02),
          ),
        ),
        const SizedBox(height: 20),

        // Title
        Text(
          widget.title ?? 'Please Wait...',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3C3C3C),
          ),
          textAlign: TextAlign.center,
        ),

        // Subtitle
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtitle!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildDivider(String label) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildSkipButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _canSkip ? const Color(0xFF58CC02) : Colors.grey[300],
        borderRadius: BorderRadius.circular(30),
        boxShadow: _canSkip
            ? [
          BoxShadow(
            color: const Color(0xFF58CC02).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canSkip ? _handleContinue : null,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_canSkip) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[600]!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  _canSkip ? 'Continue' : 'Wait $_secondsRemaining s',
                  style: TextStyle(
                    color: _canSkip ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (_canSkip) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
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
// ============================================================================
// CONTOH 1: Simple (default settings)
// ============================================================================
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AdsOnlyPage(
      onContinue: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen()),
        );
      },
    ),
  ),
);

// ============================================================================
// CONTOH 2: Custom title & subtitle
// ============================================================================
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AdsOnlyPage(
      title: 'Great Job! 🎉',
      subtitle: 'Preparing your exam results...',
      skipDelaySeconds: 8,
      onContinue: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen()),
        );
      },
    ),
  ),
);

// ============================================================================
// CONTOH 3: Custom header widget
// ============================================================================
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AdsOnlyPage(
      headerWidget: Column(
        children: [
          Image.asset('assets/trophy.png', height: 100),
          SizedBox(height: 16),
          Text(
            'Congratulations!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text('Your score: 95/100'),
        ],
      ),
      skipDelaySeconds: 5,
      onContinue: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen()),
        );
      },
    ),
  ),
);

// ============================================================================
// CONTOH 4: Tanpa skip button (manual navigation)
// ============================================================================
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AdsOnlyPage(
      title: 'Loading...',
      showSkipButton: false, // No skip button
      onContinue: null, // Will auto-close if back button pressed
    ),
  ),
);

// Then navigate programmatically after some action:
Future.delayed(Duration(seconds: 10), () {
  Navigator.pop(context);
});

// ============================================================================
// CONTOH 5: Custom background color
// ============================================================================
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AdsOnlyPage(
      title: 'Please Wait',
      backgroundColor: Colors.grey[50],
      skipDelaySeconds: 6,
      onContinue: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResultScreen()),
        );
      },
    ),
  ),
);

// ============================================================================
// CONTOH 6: Integrasi dengan ExamResultModel (seperti existing code Anda)
// ============================================================================
import 'your_models/exam_result_model.dart';

// Setelah quiz selesai:
final examResult = ExamResultModel(
  score: 85,
  correctAnswers: 85,
  totalQuestions: 100,
  // ... other fields
);

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AdsOnlyPage(
      title: 'Calculating Your Score... 🧮',
      subtitle: 'Please wait while we prepare your results',
      skipDelaySeconds: 7,
      onContinue: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ExamResultScreen(result: examResult),
          ),
        );
      },
    ),
  ),
);
*/
// ============================================================================
// MAXIMUM ADS PAGE - Halaman Dengan Iklan Maksimal (Web Only)
// ============================================================================
//
// Halaman ini menampilkan BANYAK iklan untuk maksimalkan revenue.
// PERINGATAN: Terlalu banyak iklan bisa melanggar policy AdSense!
// Gunakan dengan bijak, jangan terlalu sering.
//
// Usage:
// Navigator.push(context, MaterialPageRoute(
//   builder: (_) => MaximumAdsPage(onDone: () => Navigator.pop(context)),
// ));
//
// ============================================================================


class MaximumAdsPage extends StatefulWidget {
  final VoidCallback? onDone;
  final int autoCloseSeconds;
  final String? title;

  const MaximumAdsPage({
    super.key,
    this.onDone,
    this.autoCloseSeconds = 10,
    this.title,
  });

  @override
  State<MaximumAdsPage> createState() => _MaximumAdsPageState();
}

class _MaximumAdsPageState extends State<MaximumAdsPage> {
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _canClose = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.autoCloseSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _canClose = true;
            timer.cancel();
          }
        });
      }
    });
  }

  void _handleClose() {
    if (!_canClose) return;
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          widget.title ?? 'Sponsored Content',
          style: const TextStyle(
            color: Color(0xFF3C3C3C),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _buildCloseButton(),
            ),
          ),
        ],
      ),
      body: !kIsWeb
          ? _buildMobileFallback()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info banner
            _buildInfoBanner(),
            const SizedBox(height: 16),

            // ============================================
            // SECTION 1: TOP ADS
            // ============================================
            _buildSectionHeader('Top Stories', Icons.trending_up),
            const SizedBox(height: 12),

            // Ad 1: Horizontal
            const AdSenseSimpleHorizontal(showLabel: true),

            // Ad 2: Square
            const AdSenseSimpleSquare(showLabel: true),

            const SizedBox(height: 24),

            // ============================================
            // SECTION 2: FEATURED CONTENT
            // ============================================
            _buildSectionHeader('Featured', Icons.star),
            const SizedBox(height: 12),

            // Ad 3: Square
            const AdSenseSimpleSquare(showLabel: true),

            // Ad 4: In-feed
            const AdSenseSimpleInFeed(showLabel: false),

            const SizedBox(height: 24),

            // ============================================
            // SECTION 3: RECOMMENDED
            // ============================================
            _buildSectionHeader('Recommended', Icons.recommend),
            const SizedBox(height: 12),

            // Ad 5: Horizontal
            const AdSenseSimpleHorizontal(showLabel: true),

            // Ad 6: Square
            const AdSenseSimpleSquare(showLabel: true),

            const SizedBox(height: 24),

            // ============================================
            // SECTION 4: MORE CONTENT
            // ============================================
            _buildSectionHeader('More For You', Icons.apps),
            const SizedBox(height: 12),

            // Ad 7: In-feed
            const AdSenseSimpleInFeed(showLabel: false),

            // Ad 8: Square
            const AdSenseSimpleSquare(showLabel: true),

            const SizedBox(height: 24),

            // ============================================
            // SECTION 5: BOTTOM ADS
            // ============================================
            _buildSectionHeader('Popular Now', Icons.whatshot),
            const SizedBox(height: 12),

            // Ad 9: Horizontal
            const AdSenseSimpleHorizontal(showLabel: true),

            // Ad 10: Square
            const AdSenseSimpleSquare(showLabel: true),

            const SizedBox(height: 32),

            // Bottom info
            _buildBottomInfo(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFallback() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.web, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'This page is web-only',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _canClose ? const Color(0xFF58CC02) : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: _canClose ? _handleClose : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_canClose) ...[
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _canClose ? 'Close' : '$_secondsRemaining s',
              style: TextStyle(
                color: _canClose ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (_canClose) ...[
              const SizedBox(width: 4),
              const Icon(Icons.close, color: Colors.white, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Please browse sponsored content while we prepare your results',
              style: TextStyle(
                color: Colors.blue[900],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF58CC02)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3C3C3C),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '📢 Thank you for supporting us!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ads help us keep this platform free for everyone.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// USAGE
// ============================================================================

/*
// Setelah quiz selesai, tampilkan halaman iklan dulu:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => MaximumAdsPage(
      title: 'Please Wait...',
      autoCloseSeconds: 10,
      onDone: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ExamResultScreen(result: examResult),
          ),
        );
      },
    ),
  ),
);
*/

// ============================================================================
// ADS INTERSTITIAL PAGE - Platform Aware (Web: AdSense | Mobile: AdMob)
// ============================================================================
//
// Widget ini otomatis menampilkan:
// - Web: Halaman penuh dengan banyak iklan AdSense
// - Mobile: AdMob Interstitial atau halaman custom dengan AdMob
//
// Usage:
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (_) => AdsInterstitialPage(
//       title: 'Preparing Your Results...',
//       subtitle: 'Please wait while we calculate your score',
//       onContinue: () {
//         Navigator.pushReplacement(context, ...);
//       },
//     ),
//   ),
// );
//
// ============================================================================


// Import AdMob service (pastikan file ini ada)
// import 'package:your_app/services/ad_service.dart';

// ============================================================================
// MAIN WIDGET - Platform Aware
// ============================================================================

class AdsInterstitialPage extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final VoidCallback? onContinue;
  final int skipDelaySeconds;
  final bool showSkipButton;
  final Color? backgroundColor;

  const AdsInterstitialPage({
    super.key,
    this.title,
    this.subtitle,
    this.onContinue,
    this.skipDelaySeconds = 5,
    this.showSkipButton = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? _WebAdsPage(
      title: title,
      subtitle: subtitle,
      onContinue: onContinue,
      skipDelaySeconds: skipDelaySeconds,
      showSkipButton: showSkipButton,
      backgroundColor: backgroundColor,
    )
        : _MobileAdsPage(
      title: title,
      subtitle: subtitle,
      onContinue: onContinue,
      skipDelaySeconds: skipDelaySeconds,
      showSkipButton: showSkipButton,
      backgroundColor: backgroundColor,
    );
  }
}

// ============================================================================
// WEB ADS PAGE - Maximum AdSense Implementation
// ============================================================================

class _WebAdsPage extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final VoidCallback? onContinue;
  final int skipDelaySeconds;
  final bool showSkipButton;
  final Color? backgroundColor;

  const _WebAdsPage({
    this.title,
    this.subtitle,
    this.onContinue,
    required this.skipDelaySeconds,
    required this.showSkipButton,
    this.backgroundColor,
  });

  @override
  State<_WebAdsPage> createState() => _WebAdsPageState();
}

class _WebAdsPageState extends State<_WebAdsPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _canSkip = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.skipDelaySeconds;
    _initAnimations();
    widget.showSkipButton ? _startTimer() : _canSkip = true;
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
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canSkip = true;
          timer.cancel();
        }
      });
    });
  }

  void _handleContinue() {
    if (!_canSkip) return;
    widget.onContinue ?? Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildWebContent(),
            ),
            if (widget.showSkipButton)
              Positioned(
                top: 16,
                right: 16,
                child: _buildSkipButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 32),

          // ============================================
          // SECTION 1: TOP ADS
          // ============================================
          _buildSectionDivider('Featured Content', Icons.star),
          const SizedBox(height: 16),
          const AdSenseSimpleHorizontal(showLabel: true, margin: EdgeInsets.only(bottom: 20)),
          const AdSenseSimpleSquare(showLabel: true, margin: EdgeInsets.only(bottom: 20)),
          const SizedBox(height: 24),

          // ============================================
          // SECTION 2: NATIVE ADS
          // ============================================
          _buildSectionDivider('Recommended For You', Icons.recommend),
          const SizedBox(height: 16),
          const AdSenseSimpleInFeed(showLabel: false, margin: EdgeInsets.only(bottom: 20)),
          const AdSenseSimpleSquare(showLabel: true, margin: EdgeInsets.only(bottom: 20)),
          const SizedBox(height: 24),

          // ============================================
          // SECTION 3: MORE ADS
          // ============================================
          _buildSectionDivider('Trending Now', Icons.trending_up),
          const SizedBox(height: 16),
          const AdSenseSimpleInArticle(showLabel: false, margin: EdgeInsets.only(bottom: 20)),
          const AdSenseSimpleHorizontal(showLabel: true, margin: EdgeInsets.only(bottom: 20)),
          const SizedBox(height: 24),

          // ============================================
          // SECTION 4: ADDITIONAL ADS
          // ============================================
          _buildSectionDivider('Popular Content', Icons.whatshot),
          const SizedBox(height: 16),
          const AdSenseSimpleSquare(showLabel: true, margin: EdgeInsets.only(bottom: 20)),
          const AdSenseSimpleInFeed(showLabel: false, margin: EdgeInsets.only(bottom: 20)),
          const SizedBox(height: 24),

          // ============================================
          // SECTION 5: BOTTOM ADS
          // ============================================
          _buildSectionDivider('More For You', Icons.apps),
          const SizedBox(height: 16),
          const AdSenseSimpleHorizontal(showLabel: true, margin: EdgeInsets.only(bottom: 20)),
          const AdSenseSimpleSquare(showLabel: true, margin: EdgeInsets.only(bottom: 20)),
          const SizedBox(height: 32),

          // Thank you message
          _buildThankYouMessage(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF58CC02).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.hourglass_empty,
            size: 48,
            color: Color(0xFF58CC02),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          widget.title ?? 'Please Wait...',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3C3C3C),
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtitle!,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildSectionDivider(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF58CC02)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF3C3C3C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildThankYouMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.favorite, color: Colors.blue[700], size: 32),
          const SizedBox(height: 8),
          Text(
            'Thank You for Supporting Us! 💙',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Ads help us keep this platform free for everyone.',
            style: TextStyle(fontSize: 12, color: Colors.blue[800]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _canSkip ? const Color(0xFF58CC02) : Colors.grey[300],
        borderRadius: BorderRadius.circular(30),
        boxShadow: _canSkip
            ? [
          BoxShadow(
            color: const Color(0xFF58CC02).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canSkip ? _handleContinue : null,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_canSkip) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  _canSkip ? 'Continue' : 'Wait $_secondsRemaining s',
                  style: TextStyle(
                    color: _canSkip ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (_canSkip) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
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
// MOBILE ADS PAGE - AdMob Implementation
// ============================================================================

class _MobileAdsPage extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final VoidCallback? onContinue;
  final int skipDelaySeconds;
  final bool showSkipButton;
  final Color? backgroundColor;

  const _MobileAdsPage({
    this.title,
    this.subtitle,
    this.onContinue,
    required this.skipDelaySeconds,
    required this.showSkipButton,
    this.backgroundColor,
  });

  @override
  State<_MobileAdsPage> createState() => _MobileAdsPageState();
}

class _MobileAdsPageState extends State<_MobileAdsPage> {
  bool _isAdLoading = true;
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.skipDelaySeconds;
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadInterstitialAd() async {
    // TODO: Uncomment dan sesuaikan dengan AdService Anda
    /*
    try {
      await AdService.instance.loadInterstitialAd();
      if (!mounted) return;
      setState(() => _isAdLoading = false);
      final adShown = await AdService.instance.showInterstitialAd();
      if (mounted && adShown) {
        _startTimer();
      } else {
        _handleContinue();
      }
    } catch (e) {
      debugPrint('Error loading interstitial: $e');
      if (mounted) {
        setState(() => _isAdLoading = false);
        _handleContinue();
      }
    }
    */

    // TEMPORARY: Simulasi loading ad (hapus ini saat AdService sudah siap)
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isAdLoading = false);
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
          _handleContinue();
        }
      });
    });
  }

  void _handleContinue() {
    widget.onContinue ?? Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Colors.white,
      body: SafeArea(
        child: Center(
          child: _isAdLoading ? _buildLoadingState() : _buildWaitingState(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58CC02)),
        ),
        const SizedBox(height: 24),
        Text(
          'Loading...',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildWaitingState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF58CC02).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Color(0xFF58CC02),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.title ?? 'Please Wait...',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3C3C3C),
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.subtitle!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          if (_secondsRemaining > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Redirecting in $_secondsRemaining s...',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}