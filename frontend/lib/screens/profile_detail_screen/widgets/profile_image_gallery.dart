import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileImageGallery extends StatelessWidget {
  final List<dynamic> images;

  const ProfileImageGallery({
    super.key,
    required this.images,
  });

  void _openFullScreenViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];
    
    for (int i = 0; i < images.length; i += 2) {
      if (i + 1 < images.length) {
        // Pair of images
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: _GalleryImageItem(
                    imageUrl: images[i]['imageUrl'],
                    onTap: () => _openFullScreenViewer(context, i),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _GalleryImageItem(
                    imageUrl: images[i + 1]['imageUrl'],
                    onTap: () => _openFullScreenViewer(context, i + 1),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Single image (last one)
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _GalleryImageItem(
              imageUrl: images[i]['imageUrl'],
              onTap: () => _openFullScreenViewer(context, i),
              isFullWidth: true,
            ),
          ),
        );
      }
    }

    return Column(
      children: rows,
    );
  }
}

class _GalleryImageItem extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;
  final bool isFullWidth;

  const _GalleryImageItem({
    required this.imageUrl,
    required this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: isFullWidth ? 16 / 9 : 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey.withValues(alpha: 0.1),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.withValues(alpha: 0.1),
              child: const Icon(Icons.error, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<dynamic> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '${_currentIndex + 1} / ${widget.images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: widget.images[index]['imageUrl'],
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.error, color: Colors.white, size: 48),
              ),
            ),
          );
        },
      ),
    );
  }
}
