import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class MapUtils {
  MapUtils._();

  static Future<void> openMap(
    double latitude,
    double longitude,
    BuildContext context,
  ) async {
    // 1. Create the official Google Maps search URL using the coordinates
    final Uri googleUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    // 2. Try to launch
    try {
      if (await canLaunchUrl(googleUrl)) {
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open maps application.')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error launching map: $e");
    }
  }
}
