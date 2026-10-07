import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fixnow/core/theme/app_theme.dart';

/// Galerie horizontale des photos jointes à une demande de service.
/// Utilisée côté client (détail de la demande) et côté pro (liste des
/// demandes). Un tap ouvre la photo en plein écran.
class RequestPhotoGallery extends StatelessWidget {
  final List<String> photoUrls;

  const RequestPhotoGallery({super.key, required this.photoUrls});

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (${photoUrls.length})',
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photoUrls.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final url = photoUrls[index];
              return GestureDetector(
                onTap: () => _openViewer(context, photoUrls, index),
                child: ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openViewer(BuildContext context, List<String> urls, int initial) {
    Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      pageBuilder: (_, __, ___) => _PhotoViewer(urls: urls, initial: initial),
    ));
  }
}

/// Visionneuse plein écran (swipe entre les photos, tap pour fermer).
class _PhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int initial;

  const _PhotoViewer({required this.urls, required this.initial});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.urls.length,
        itemBuilder: (context, index) => Center(
          child: InteractiveViewer(
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: widget.urls[index],
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
