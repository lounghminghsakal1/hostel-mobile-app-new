import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/widgets.dart';
import 'media_providers.dart';

/// Loads a private S3 image through a fresh signed URL, showing [placeholder]
/// while loading, when there is no key, or if anything fails.
class SignedImage extends ConsumerWidget {
  const SignedImage({
    super.key,
    required this.objectKey,
    required this.placeholder,
    this.fit = BoxFit.cover,
    this.directUrl,
  });

  final String? objectKey;

  /// Use when the API already returned a signed URL (e.g. `studentImageUrl`).
  final String? directUrl;
  final Widget placeholder;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (directUrl != null) return _network(directUrl!);
    final key = objectKey;
    if (key == null || key.isEmpty) return placeholder;
    return ref.watch(signedImageUrlProvider(key)).maybeWhen(
          data: _network,
          orElse: () => placeholder,
        );
  }

  Widget _network(String url) => Image.network(
        url,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
      );
}

/// Round photo of a person, falling back to their initials.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.name, this.imageKey, this.imageUrl, this.size = 40});

  final String name;
  final String? imageKey;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = InitialsAvatar(name: name, size: size);
    if ((imageKey == null || imageKey!.isEmpty) && imageUrl == null) return initials;
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: SignedImage(objectKey: imageKey, directUrl: imageUrl, placeholder: initials),
      ),
    );
  }
}
