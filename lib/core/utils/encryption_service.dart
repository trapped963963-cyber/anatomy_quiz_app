import 'package:encrypt/encrypt.dart';

class EncryptionService {
  Encrypter? _encrypter;
  final _iv = IV.fromLength(16); // Initialization Vector

  // This method will be called once on app startup to set the key.
  void initialize(String base64Key) {
    final key = Key.fromBase64(base64Key);
    _encrypter = Encrypter(AES(key));
  }

  // This is the main method we'll use to decrypt text from the database.
  String decrypt(String encryptedText) {
    // If the service hasn't been initialized, return an error message.
    if (_encrypter == null) {
      return 'Encryption key not set';
    }

    try {
      final encrypted = Encrypted.fromBase64(encryptedText);
      // Use the IV for AES decryption
      return _encrypter!.decrypt(encrypted, iv: _iv);
    } catch (e) {
      // If decryption fails, return the original text to avoid crashes.
      print('Decryption failed: $e');
      return encryptedText;
    }
  }
}