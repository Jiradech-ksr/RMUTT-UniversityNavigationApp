import 'package:flutter/material.dart';

class LocationCard extends StatelessWidget {
  final String title;
  final String room;
  final String floor;
  final bool isFavorite;
  final VoidCallback onTap;

  const LocationCard({
    super.key,
    required this.title,
    required this.room,
    required this.floor,
    this.isFavorite = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.location_pin, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'room : $room',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'floor : $floor',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (isFavorite)
                const Icon(
                  Icons.star,
                  color: Color(0xFFFFC107),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
