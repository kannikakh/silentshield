import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/onboarding_page.dart';

/// Onboarding Flow screen that introduces new users to SilentShield's capabilities
/// Implements three-screen sequence with skip functionality and smooth transitions
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Stay Safe Silently",
      "subtitle":
          "Activate emergency response discretely through motion detection and voice triggers without alerting potential threats",
      "animationAsset":
          "https://assets10.lottiefiles.com/packages/lf20_jcikwtux.json",
      "semanticLabel":
          "Animation showing a smartphone detecting distress signals with shield icon and location pin appearing",
      "features": [
        {"icon": "sensors", "text": "Motion Detection"},
        {"icon": "mic", "text": "Voice Triggers"},
        {"icon": "location_on", "text": "Live Tracking"},
      ],
    },
    {
      "title": "Silent SOS Protection",
      "subtitle":
          "Practice emergency activation patterns with haptic feedback. Your safety signal works even when you can't speak",
      "animationAsset":
          "https://assets2.lottiefiles.com/packages/lf20_w51pcehl.json",
      "semanticLabel":
          "Interactive demonstration of phone detecting button patterns and voice keywords with haptic feedback confirmation",
      "features": [
        {"icon": "touch_app", "text": "Button Patterns"},
        {"icon": "record_voice_over", "text": "Voice Keywords"},
        {"icon": "vibration", "text": "Haptic Feedback"},
      ],
    },
    {
      "title": "VoiceShield Protection",
      "subtitle":
          "Real-time scam call detection with AI-powered analysis. See risk percentages and call warnings instantly",
      "animationAsset":
          "https://assets5.lottiefiles.com/packages/lf20_yd0b1xzf.json",
      "semanticLabel":
          "Mock call interface displaying real-time scam detection with risk percentage meter and call analysis indicators",
      "features": [
        {"icon": "phone_in_talk", "text": "Call Analysis"},
        {"icon": "warning", "text": "Risk Detection"},
        {"icon": "block", "text": "Scam Blocking"},
      ],
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _skipOnboarding() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacementNamed('/permissions-setup');
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed('/permissions-setup');
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(theme),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return OnboardingPageWidget(
                    title: _onboardingData[index]["title"] as String,
                    subtitle: _onboardingData[index]["subtitle"] as String,
                    animationAsset:
                        _onboardingData[index]["animationAsset"] as String,
                    semanticLabel:
                        _onboardingData[index]["semanticLabel"] as String,
                    features:
                        _onboardingData[index]["features"]
                            as List<Map<String, dynamic>>,
                  );
                },
              ),
            ),
            _buildBottomSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _currentPage > 0
              ? GestureDetector(
                  onTap: _previousPage,
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    child: CustomIconWidget(
                      iconName: 'arrow_back',
                      color: theme.colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                )
              : SizedBox(width: 10.w),
          TextButton(
            onPressed: _skipOnboarding,
            child: Text(
              'Skip',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SmoothPageIndicator(
            controller: _pageController,
            count: _onboardingData.length,
            effect: ExpandingDotsEffect(
              activeDotColor: theme.colorScheme.primary,
              dotColor: theme.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.3,
              ),
              dotHeight: 1.h,
              dotWidth: 2.w,
              expansionFactor: 3,
              spacing: 1.w,
            ),
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                _currentPage == _onboardingData.length - 1
                    ? 'Get Started'
                    : 'Continue',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}
