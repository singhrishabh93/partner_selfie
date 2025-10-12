import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const SplashScreen({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _imageController;
  late Animation<double> _textOpacity;
  late Animation<double> _textScale;
  late List<AnimationController> _imageControllers;
  late List<Animation<double>> _imageScales;
  late List<Animation<double>> _imageOpacities;

  final List<String> _imagePaths = [
    'assets/images/1.jpg',
    'assets/images/2.jpg',
    'assets/images/3.jpg',
    'assets/images/4.jpg',
    'assets/images/5.jpg',
    'assets/images/6.jpg',
    'assets/images/7.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _imageController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _textOpacity = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
    ));

    _textScale = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    // Image animations
    _imageControllers = List.generate(
      _imagePaths.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 800 + (index * 100)),
        vsync: this,
      ),
    );

    _imageScales = _imageControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
    }).toList();

    _imageOpacities = _imageControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ));
    }).toList();
  }

  void _startAnimationSequence() async {
    // Start text animation
    _textController.forward();

    // Wait a bit then start image animations
    await Future.delayed(const Duration(milliseconds: 500));

    // Start image animations with staggered timing
    for (int i = 0; i < _imageControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _imageControllers[i].forward();
        }
      });
    }

    // Complete animation after all images are shown
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) {
      widget.onAnimationComplete();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _imageController.dispose();
    for (var controller in _imageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated images that grow from center to cover whole screen
          ...List.generate(_imagePaths.length, (index) {
            return AnimatedBuilder(
              animation: _imageControllers[index],
              builder: (context, child) {
                return Opacity(
                  opacity: _imageOpacities[index].value,
                  child: Transform.scale(
                    scale: _imageScales[index].value,
                    child: Center(
                      child: Container(
                        width: screenSize.width,
                        height: screenSize.height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.asset(
                            _imagePaths[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Animated text with image mask effect
          Center(
            child: AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _textScale.value,
                  child: Opacity(
                    opacity: _textOpacity.value,
                    child: _buildTextWithImageMask(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextWithImageMask() {
    return Stack(
      children: [
        // Black stroke text (always visible)
        Text(
          'Image Maker',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        // Base white text (always visible)
        const Text(
          'Image Maker',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
