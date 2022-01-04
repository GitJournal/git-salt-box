import 'dart:convert';

import 'package:buffer/buffer.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:pinenacl/digests.dart';
import 'package:pinenacl/tweetnacl.dart';
import 'package:pinenacl/x25519.dart';

// import 'package:sodium/sodium.dart';

class GitSaltBox {
  // GITSB + version + \0
  static final _magicHeader =
      Uint8List.fromList([71, 73, 84, 83, 66, version, 0]);
  static const _magicHeaderLength = 7;
  static const version = 1;

  // final Sodium sodium;
  final Uint8List password;
  static const passwordLength = SecretBox.keyLength;

  GitSaltBox({required this.password}) {
    if (password.length != passwordLength) {
      throw ArgumentError("Password length must be $passwordLength");
    }
  }

  /// throws GSBAlreadyEncrypted
  Uint8List encrypt(String filePath, List<int> input) {
    final content = input is Uint8List ? input : Uint8List.fromList(input);
    final header = Uint8List.sublistView(content, 0, _magicHeader.length);
    if (_eq(header, _magicHeader)) {
      throw GSBAlreadyEncrypted();
    }

    final fileName = p.basename(filePath);
    final nonce = Hash.blake2b(
      content,
      key: password,
      digestSize: TweetNaCl.nonceLength,
      personalisation: utf8.encode(fileName) as Uint8List,
    );

    final box = SecretBox(password);
    final enc = box.encrypt(content, nonce: nonce);

    final builder = BytesBuilder(copy: false);
    builder.add(_magicHeader);
    builder.add(enc);
    return builder.toBytes();
  }

  /// throws GSBNotEncrypted
  Uint8List decrypt(Uint8List encMessage) {
    const minLength = TweetNaCl.nonceLength + _magicHeaderLength + 1;
    if (encMessage.length < minLength) {
      throw GSBNotEncrypted();
    }

    final reader = ByteDataReader(copy: false);
    reader.add(encMessage);

    final header = reader.read(_magicHeaderLength);
    if (!_eq(header, _magicHeader)) {
      throw GSBNotEncrypted();
    }

    final nonce = reader.read(TweetNaCl.nonceLength);
    final cipherText = reader.read(reader.remainingLength);

    final box = SecretBox(password);
    final orig = box.decrypt(ByteList.fromList(cipherText), nonce: nonce);

    return orig;
  }
}

final _eq = ListEquality().equals;

class GSBAlreadyEncrypted implements Exception {}

class GSBNotEncrypted implements Exception {}
