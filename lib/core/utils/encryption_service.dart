import 'dart:convert'; // Import the dart:convert library for utf8
import 'package:fernet/fernet.dart';
import 'package:flutter/foundation.dart'; // Import for Uint8List

class EncryptionService {
  Fernet? _fernet;

  // This method will be called once on app startup to set the key.
  void initialize(String base64Key) {
    try {
      _fernet = Fernet(base64Key);
    } catch (e) {
    }
  }

  // This is the main method we'll use to decrypt text from the database.
  String decrypt(String encryptedText) {
    // If the service hasn't been initialized, return an error message.
    if (_fernet == null) {
      return 'Encryption key not set';
    }

    try {
          // Step 1: Decrypt the text into a list of bytes (Uint8List).
          final Uint8List decryptedBytes = _fernet!.decrypt(encryptedText);

          // Step 2: Decode the bytes into a human-readable string using UTF-8.
          return utf8.decode(decryptedBytes);
    } catch (e) {
      // If decryption fails, return the original text to avoid crashes.
      return encryptedText;
    }
  }
}