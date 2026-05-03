import 'dart:convert';
import 'package:flutter/material.dart';

class ImageUtils {
  static ImageProvider? getProfileImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;

    if (photoUrl.startsWith('http')) {
      return NetworkImage(photoUrl);
    }

    if (photoUrl.startsWith('data:image')) {
      try {
        final base64String = photoUrl.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return null;
      }
    }
    return null;
  }
}
