import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';

class FullscreenImagePreview extends StatefulWidget {
  final List<dynamic> images;
  final int initialIndex;

  const FullscreenImagePreview({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  /// Shows full screen image preview: modal on Web, full screen page route on Mobile
  static Future<void> show(
    BuildContext context, {
    required List<dynamic> images,
    int initialIndex = 0,
  }) {
    if (images.isEmpty) return Future.value();
    final clampedIndex = initialIndex.clamp(0, images.length - 1);

    if (kIsWeb) {
      return showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 850),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FullscreenImagePreview(
                images: images,
                initialIndex: clampedIndex,
              ),
            ),
          ),
        ),
      );
    } else {
      return Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (ctx) => FullscreenImagePreview(
            images: images,
            initialIndex: clampedIndex,
          ),
        ),
      );
    }
  }

  @override
  State<FullscreenImagePreview> createState() => _FullscreenImagePreviewState();
}

class _FullscreenImagePreviewState extends State<FullscreenImagePreview> {
  late final PageController _pageController;
  late final ScrollController _thumbnailScrollController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _thumbnailScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToThumbnail(_currentIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbnailScrollController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _scrollToThumbnail(index);
  }

  void _selectImage(int index) {
    if (index == _currentIndex) return;
    final isAdjacent = (index - _currentIndex).abs() == 1;
    setState(() => _currentIndex = index);
    if (isAdjacent) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.jumpToPage(index);
    }
    _scrollToThumbnail(index);
  }

  void _scrollToThumbnail(int index) {
    if (!_thumbnailScrollController.hasClients) return;
    const itemWidth = 68.0; // 60 width + 8 margin
    final targetOffset =
        (index * itemWidth) -
        (MediaQuery.of(context).size.width / 2) +
        (itemWidth / 2);
    _thumbnailScrollController.animateTo(
      targetOffset.clamp(
        0.0,
        _thumbnailScrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = widget.images.length > 1;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
              _currentIndex > 0) {
            _selectImage(_currentIndex - 1);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
              _currentIndex < widget.images.length - 1) {
            _selectImage(_currentIndex + 1);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main Interactive Viewer / PageView
              PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Center(
                      child: CachedAppImage.fromProfileImageMap(
                        image: widget.images[index],
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(
                            LucideIcons.image_off,
                            color: Colors.white54,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Close Button (Top Right)
              Positioned(
                top: 16,
                right: 16,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ),
              ),

              // Counter Badge (Top Left)
              if (hasMultiple)
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Web Chevron Left
              if (kIsWeb && _currentIndex > 0)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(
                          LucideIcons.chevron_left,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => _selectImage(_currentIndex - 1),
                      ),
                    ),
                  ),
                ),

              // Web Chevron Right
              if (kIsWeb && _currentIndex < widget.images.length - 1)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(
                          LucideIcons.chevron_right,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => _selectImage(_currentIndex + 1),
                      ),
                    ),
                  ),
                ),

              // Bottom Thumbnail Dock Strip (macOS Dock style magnifier)
              if (hasMultiple)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      height: 76,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        controller: _thumbnailScrollController,
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.images.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final isSelected = index == _currentIndex;
                          final size = isSelected ? 60.0 : 48.0;
                          final radius = isSelected ? 14.0 : 10.0;
                          final borderWidth = isSelected ? 2.5 : 1.0;

                          return GestureDetector(
                            onTap: () => _selectImage(index),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.center,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(radius),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.white.withValues(alpha: 0.25),
                                    width: borderWidth,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.45),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    (radius - borderWidth).clamp(0.0, radius),
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedAppImage.fromProfileImageMap(
                                        image: widget.images[index],
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          color: Colors.grey.shade900,
                                        ),
                                        errorWidget: (_, __, ___) => const Icon(
                                          LucideIcons.image_off,
                                          color: Colors.white38,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
