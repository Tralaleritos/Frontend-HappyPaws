import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';

class CarouselAds extends StatefulWidget {
  final List<String> bannerImages;

  const CarouselAds({
    super.key,
    required this.bannerImages,
  });

  @override
  State<CarouselAds> createState() => _CarouselAdsState();
}

class _CarouselAdsState extends State<CarouselAds> {
  int _currentBannerIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7.0),
          child: CarouselSlider.builder(
            itemCount: widget.bannerImages.length,
            itemBuilder: (context, index, realIndex) {
              // Determinar si este banner es el central
              bool isCentral = index == _currentBannerIndex;

              return Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 0.2),
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(
                    image: AssetImage(widget.bannerImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: isCentral
                      ? null // El banner central no tiene gradiente
                      : LinearGradient(
                    begin: index < _currentBannerIndex
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    end: index < _currentBannerIndex
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.8),
                    ],
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: 120,
              viewportFraction: 0.7,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              enlargeCenterPage: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentBannerIndex = index;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 1),
        SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.bannerImages.asMap().entries.map((entry) {
              final index = entry.key;
              final isActive = index == _currentBannerIndex;

              // Indicador circular para inactivos
              if (!isActive) {
                return Container(
                  width: 6.0,
                  height: 6.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    color: Colors.grey.withOpacity(0.3),
                  ),
                );
              }

              // Indicador tipo barra con progreso para el activo
              return Container(
                width: 20.0,
                height: 3.5,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: Colors.grey.withOpacity(0.3),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ProgressBarIndicator(
                      duration: const Duration(seconds: 5),
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// Widget para la barra de progreso del carousel
class ProgressBarIndicator extends StatefulWidget {
  final Duration duration;
  final double width;
  final double height;

  const ProgressBarIndicator({
    super.key,
    required this.duration,
    required this.width,
    required this.height,
  });

  @override
  State<ProgressBarIndicator> createState() => _ProgressBarIndicatorState();
}

class _ProgressBarIndicatorState extends State<ProgressBarIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: 0, end: widget.width).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Stack(
        children: [
          Container(
            width: _animation.value,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}