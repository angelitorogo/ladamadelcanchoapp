import 'package:flutter/material.dart';
import 'package:ladamadelcanchoapp/config/constants/environment.dart';

class FullScreenCarouselView extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenCarouselView({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenCarouselView> createState() => _FullScreenCarouselViewState();
}

class _FullScreenCarouselViewState extends State<FullScreenCarouselView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Imágenes', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: widget.initialIndex),
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          final imageUrl = "${Environment.apiUrl}/files/tracks/${widget.images[index]}";

          return Center(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
            ),
          );
        },
      ),

    );
  }
}
