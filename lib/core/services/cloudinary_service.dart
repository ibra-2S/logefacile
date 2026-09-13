import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Upload d'images vers Cloudinary (preset non signé), utilisé pour les
/// photos de profil, les pièces d'identité et les photos de biens.
class CloudinaryService {
  static const String _cloudName = 'dfxnwioow';
  static const String _uploadPreset = 'g1qqzyep';

  /// Envoie une image et retourne son URL sécurisée, ou `null` en cas d'échec.
  static Future<String?> uploaderImage(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', image.path),
      );
      final response = await request.send();
      final jsonData = jsonDecode(await response.stream.bytesToString());
      if (response.statusCode == 200) return jsonData['secure_url'] as String;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Envoie plusieurs images en série et retourne les URLs de celles qui ont
  /// réussi (dans l'ordre). Les échecs individuels sont simplement absents
  /// du résultat — comparez la longueur au nombre d'images passées pour
  /// prévenir l'utilisateur d'un envoi partiel.
  static Future<List<String>> uploaderImages(List<File> images) async {
    final urls = <String>[];
    for (final image in images) {
      final url = await uploaderImage(image);
      if (url != null) urls.add(url);
    }
    return urls;
  }
}
