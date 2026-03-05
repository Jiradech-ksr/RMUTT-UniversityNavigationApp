import 'package:flutter/material.dart';

class ImageCard extends StatelessWidget {
  final String imagePath;

  const ImageCard({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      // This clips the image to the card's rounded corners
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 220, // Width for each image card
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
