import 'package:flutter/material.dart';

import '../../../data/models/eventImage.dart';

/// Market pictures: mark one as cover, remove, add new ones.
class ImageListEditor extends StatelessWidget {
  final List<EventImage> images;
  final ValueChanged<List<EventImage>> onChanged;
  final VoidCallback? onAdd;
  final bool uploading;

  const ImageListEditor({
    super.key,
    required this.images,
    required this.onChanged,
    this.onAdd,
    this.uploading = false,
  });

  bool _isCover(int index) {
    final marked = images.indexWhere((i) => i.isStandard);
    return index == (marked < 0 ? 0 : marked);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < images.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Image.network(
                      images[i].url,
                      width: 170,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 170,
                        height: 120,
                        color: Colors.black12,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                    Positioned(
                      left: 4,
                      top: 4,
                      child: _OverlayButton(
                        icon: _isCover(i) ? Icons.star : Icons.star_border,
                        tooltip: _isCover(i) ? 'Titelbild' : 'Als Titelbild verwenden',
                        onPressed: () => onChanged([
                          for (var j = 0; j < images.length; j++)
                            EventImage(url: images[j].url, isStandard: j == i),
                        ]),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: _OverlayButton(
                        icon: Icons.close,
                        tooltip: 'Bild entfernen',
                        onPressed: () => onChanged([...images]..removeAt(i)),
                      ),
                    ),
                    if (_isCover(i))
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: const Text('Titelbild',
                              textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (onAdd != null)
            SizedBox(
              width: 120,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: uploading ? null : onAdd,
                child: uploading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [Icon(Icons.add_photo_alternate_outlined), SizedBox(height: 4), Text('Bild')],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _OverlayButton({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: IconButton(
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          color: Colors.white,
          tooltip: tooltip,
          icon: Icon(icon),
          onPressed: onPressed,
        ),
      );
}
