import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/widgets/intellekt_wordmark.dart';
import '../../routes/app_routes.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      icon: Icons.school_rounded,
      title: 'Premium Coaching\nCenter',
      description:
          'Specialized coaching in Mathematics and Physics for higher secondary students.',
    ),
    _OnboardingData(
      icon: Icons.groups_rounded,
      title: 'About Us',
      description:
          'Intellekt Academy provides concept-oriented coaching focused on clarity, analytical thinking, and academic excellence.',
    ),
    _OnboardingData(
      icon: Icons.flag_rounded,
      title: 'Our Mission',
      description:
          'To inspire students to achieve their highest potential in Mathematics and Physics through innovative teaching, strategic guidance, and personal mentoring.',
    ),
    _OnboardingData(
      icon: Icons.visibility_rounded,
      title: 'Our Vision',
      description:
          'To create a generation of INTELLEKTUALS who lead with logic, creativity, and academic excellence.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FE),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 700;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const IntellektWordmark(fontSize: 26),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: compact ? 154 : 178,
                              height: compact ? 154 : 178,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8ECFD),
                                borderRadius: BorderRadius.circular(38),
                              ),
                              child: Icon(
                                page.icon,
                                size: compact ? 74 : 86,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: compact ? 30 : 48),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontFamily: 'Roboto',
                                fontSize: compact ? 27 : 30,
                                fontWeight: FontWeight.w800,
                                height: 1.22,
                              ),
                            ),
                            SizedBox(height: compact ? 14 : 20),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 370),
                              child: Text(
                                page.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF737783),
                                  fontFamily: 'Roboto',
                                  fontSize: compact ? 15 : 16.5,
                                  height: 1.52,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    final selected = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: selected ? 25 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFFDADCE4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 26),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
