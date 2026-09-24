import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Avatar circulaire standard de FixNow (spec : cached_network_image avec
/// placeholder + errorWidget + avatar par défaut).
///
/// Remplace les `CircleAvatar(backgroundImage: NetworkImage(...))` qui
/// n'avaient ni cache, ni placeholder, ni gestion d'erreur (écran cassé
/// si l'image charge mal ou hors-ligne).
class AppAvatar extends StatelessWidget {
  final String? url;
  final double radius;

  /// Icône par défaut (pas d'image) ou en cas d'échec de chargement.
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppAvatar({
    super.key,
    this.url,
    this.radius = 22,
    this.icon = Icons.person,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = radius * 2;
    final hasImage = url != null && url!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? scheme.primaryContainer,
      child: !hasImage
          ? Icon(
              icon,
              size: size * 0.6,
              color: foregroundColor ?? scheme.primary,
            )
          : ClipOval(
              child: SizedBox(
                width: size,
                height: size,
                child: CachedNetworkImage(
                  imageUrl: url!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Center(
                    child: SizedBox(
                      width: size * 0.35,
                      height: size * 0.35,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Icon(
                    icon,
                    size: size * 0.6,
                    color: foregroundColor ?? scheme.primary,
                  ),
                ),
              ),
            ),
    );
  }
}
