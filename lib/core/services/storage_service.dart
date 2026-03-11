import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // choisir une image depuis la galerie
  Future<File?> choisirImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75, // compression pour ne pas surcharger Firebase
    );
    if (image == null) return null;
    return File(image.path);
  }

  // prendre une photo avec la caméra
  Future<File?> prendrePhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (photo == null) return null;
    return File(photo.path);
  }

  // uploader la photo de profil d'un utilisateur
  Future<String> uploaderPhotoProfile(String uid, File image) async {
    final ref = _storage.ref().child('profiles/$uid/photo.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  // uploader la carte d'identité d'un locataire
  Future<String> uploaderCarteIdentite(String uid, File image) async {
    final ref = _storage.ref().child('documents/$uid/carte_identite.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  // uploader les photos d'un bien (max 10)
  Future<List<String>> uploaderPhotosBien(
    String bienId,
    List<File> images,
  ) async {
    final urls = <String>[];
    for (int i = 0; i < images.length; i++) {
      final ref = _storage.ref().child('properties/$bienId/photo_$i.jpg');
      await ref.putFile(images[i]);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  // supprimer une photo d'un bien
  Future<void> supprimerPhoto(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // photo déjà supprimée ou inexistante
    }
  }

  // supprimer toutes les photos d'un bien
  Future<void> supprimerPhotosBien(String bienId) async {
    final ref = _storage.ref().child('properties/$bienId');
    final liste = await ref.listAll();
    for (final item in liste.items) {
      await item.delete();
    }
  }
}
