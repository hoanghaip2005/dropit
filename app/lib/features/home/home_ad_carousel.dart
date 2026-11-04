import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class HomeAdCarousel extends StatefulWidget {
  const HomeAdCarousel({super.key});

  @override
  State<HomeAdCarousel> createState() => _HomeAdCarouselState();
}

class _HomeAdCarouselState extends State<HomeAdCarousel>
    with WidgetsBindingObserver {
  static const _ads = [
    _SampleAd(
      title: 'Bắt đầu từ một mục tiêu nhỏ',
      icon: Icons.flag_outlined,
      background: Color(0xFFFFF1E6),
      accent: Color(0xFFFFD7B8),
    ),
    _SampleAd(
      title: 'Dành thời gian cho điều quan trọng',
      icon: Icons.auto_stories_outlined,
      background: Color(0xFFEAF2FF),
      accent: Color(0xFFD3E2FF),
    ),
    _SampleAd(
      title: 'Mỗi phiên tập trung đều tạo khác biệt',
      icon: Icons.lightbulb_outline,
      background: Color(0xFFEAF5EE),
      accent: Color(0xFFD1EAD9),
    ),
  ];

  final _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  bool _isForeground = true;
  bool _isVisible = true;

  bool get _isActive => _isForeground && _isVisible;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isForeground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isVisible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    _updateTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    _updateTimer();
  }

  void _updateTimer() {
    if (!_isActive) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _scheduleNextPage();
  }

  void _scheduleNextPage() {
    _timer?.cancel();
    if (!_isActive) return;
    _timer = Timer(const Duration(seconds: 5), () {
      _timer = null;
      if (!mounted || !_isActive || !_pageController.hasClients) return;
      _pageController.animateToPage(
        (_currentPage + 1) % _ads.length,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int index) {
    if (_currentPage != index) {
      setState(() => _currentPage = index);
    }
    _scheduleNextPage();
  }

  void _showPage(int index) {
    _scheduleNextPage();
    if (index == _currentPage) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          key: const Key('homeAdPageView'),
          height: 168 * scale,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _ads.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) => _SampleAdCard(
              ad: _ads[index],
              index: index,
              total: _ads.length,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < _ads.length; index++)
              Semantics(
                button: true,
                selected: _currentPage == index,
                label: 'Quảng cáo mẫu ${index + 1} trên ${_ads.length}',
                child: InkWell(
                  key: Key('homeAdDot_$index'),
                  borderRadius: BorderRadius.circular(DT.pill),
                  onTap: () => _showPage(index),
                  child: SizedBox(
                    width: 44,
                    height: 40,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: _currentPage == index ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? DT.accent : DT.outline,
                          borderRadius: BorderRadius.circular(DT.pill),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SampleAd {
  const _SampleAd({
    required this.title,
    required this.icon,
    required this.background,
    required this.accent,
  });

  final String title;
  final IconData icon;
  final Color background;
  final Color accent;
}

class _SampleAdCard extends StatelessWidget {
  const _SampleAdCard({
    required this.ad,
    required this.index,
    required this.total,
  });

  final _SampleAd ad;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Semantics(
      label:
          'Quảng cáo mẫu ${index + 1} trên $total. ${ad.title}. '
          'Nội dung minh họa, chưa có liên kết.',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DT.spaceMd),
          decoration: BoxDecoration(
            color: ad.background,
            borderRadius: BorderRadius.circular(DT.radiusCard),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ad.accent,
                  borderRadius: BorderRadius.circular(DT.radiusSm),
                ),
                child: Icon(ad.icon, color: DT.accent, size: 26),
              ),
              const SizedBox(width: DT.spaceSm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUẢNG CÁO MẪU · ${index + 1}/$total',
                      style: text.labelSmall!.copyWith(color: DT.textSecondary),
                    ),
                    const SizedBox(height: DT.spaceXs),
                    Text(
                      ad.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium,
                    ),
                    const SizedBox(height: DT.spaceXs),
                    Text(
                      'Nội dung minh họa, chưa có liên kết.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
