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
  static const version = 1;

  // final Sodium sodium;
  final String password;

  GitSaltBox({required this.password});

  /// throws GSBAlreadyEncrypted
  Uint8List encrypt(String filePath, List<int> input) {
    var content = input is Uint8List ? input : Uint8List.fromList(input);
    var header = Uint8List.sublistView(content, 0, _magicHeader.length);
    if (_eq(header, _magicHeader)) {
      throw GSBAlreadyEncrypted();
    }

    var salt = _buildSalt(filePath, Hash.sha512(content));
    var passwordHashed = Hash.sha256(password);
    assert(passwordHashed.length == SecretBox.keyLength);

    final box = SecretBox(passwordHashed);
    final enc = box.encrypt(content, nonce: salt);

    var builder = BytesBuilder(copy: false);
    builder.add(_magicHeader);
    builder.add(enc);
    return builder.toBytes();
  }

  /// throws GSBNotEncrypted
  Uint8List decrypt(Uint8List encMessage) {
    var mhLen = _magicHeader.length;
    if (encMessage.length < 25 + mhLen) {
      throw GSBNotEncrypted();
    }

    var reader = ByteDataReader(copy: false);
    reader.add(encMessage);

    var header = reader.read(mhLen);
    if (!_eq(header, _magicHeader)) {
      throw GSBNotEncrypted();
    }

    var _nonceLength = 24;
    var nonce = reader.read(_nonceLength);
    var cipherText = reader.read(reader.remainingLength);

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

var _eq = ListEquality().equals;

class GSBAlreadyEncrypted implements Exception {}

class GSBNotEncrypted implements Exception {}
