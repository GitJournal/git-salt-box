import 'dart:typed_data';

// import 'package:sodium/sodium.dart';

import 'package:pinenacl/api.dart';
import 'package:pinenacl/digests.dart';
import 'package:pinenacl/x25519.dart';

import 'package:pinenacl/tweetnacl.dart';

import 'package:path/path.dart' as p;

class GitSaltBox {
  // final Sodium sodium;
  final String password;

  GitSaltBox({required this.password});

  Uint8List encrypt(String filePath, List<int> input) {
    var content = input is Uint8List ? input : Uint8List.fromList(input);
    // FIXME: Check if already encrypted!!

    var salt = _buildSalt(filePath, Hash.sha512(content));
    var passwordHashed = Hash.sha256(password);
    assert(passwordHashed.length == SecretBox.keyLength);

    final box = SecretBox(passwordHashed);
    final enc = box.encrypt(content, nonce: salt);

    return enc.toUint8List();
  }

  Uint8List decrypt(Uint8List encMessage) {
    if (encMessage.length < 25) {
      throw ArgumentError('Encrypted Cipher too short: ${encMessage.length}');
    }
    var nonce = encMessage.sublist(0, 24);
    var cipherText = encMessage.sublist(24);

    var passwordHashed = Hash.sha256(password);
    assert(passwordHashed.length == SecretBox.keyLength);

    final box = SecretBox(passwordHashed);

    var enc = EncryptedMessage(nonce: nonce, cipherText: cipherText);
    var orig = box.decrypt(enc);
    return orig;
  }

  Uint8List _buildSalt(String filePath, Uint8List fileHash) {
    var fileName = p.basename(filePath);
    var keyString = "$fileName:$password";
    var k = Hash.sha512(keyString);
    var hash = Hash.blake2b(fileHash, key: k);
    var salt = hash.sublist(hash.length - TweetNaCl.nonceLength);

    assert(salt.length == TweetNaCl.nonceLength);
    return salt;
  }
}

// Fuck it, just always use lib-sodium

// SecretBox
// * encrypt
// * decrypt
//
