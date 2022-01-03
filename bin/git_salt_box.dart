import 'dart:io';
import 'dart:math';

import 'package:dart_git/dart_git.dart';
import 'package:pinenacl/api.dart';
import 'package:pinenacl/x25519.dart';

import 'package:pinenacl/src/digests/digests.dart';
import 'package:pinenacl/tweetnacl.dart';

import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  // print('Hello world: ${gitjournal_crypt.calculate()}!');

  if (arguments.isEmpty) {
    print("Arguments empty");
    exit(1);
  }

  var command = arguments.first;
  switch (command) {
    // Encrypt the file
    case "clean":
      await encrypt();
      break;

    // Decrypt the file
    case "smudge":
      await decrypt();
      break;

    case "init":
      await init();
      break;
  }
}

const _execName = "git-salt-box";
const _version = "0.0.1";

Future<void> init() async {
  var repoPath = GitRepository.findRootDir(Directory.current.path);
  if (repoPath == null) {
    print(
        'fatal: not a git repository (or any of the parent directories): .git');
    exit(1);
  }

  var repo = await GitRepository.load(repoPath).getOrThrow();
  var section =
      repo.config.getOrCreateSection('filter').getOrCreateSection(_execName);

  if (section.isNotEmpty) {
    print(
        'Error: this repository has already been initialized with $_execName.');
    exit(1);
  }

  section.options['smudge'] = '"$_execName" smudge';
  section.options['clean'] = '"$_execName" clean';

  var gjSection = repo.config.getOrCreateSection(_execName);
  gjSection.options["version"] = _version;
  gjSection.options["password"] = _generatePassword();

  var r = await repo.saveConfig();
  if (r.isFailure) {
    print(r.stackTrace);
    exit(1);
  }
}

// Wouldn't it be better to generate a more secure password and just base64 encode it?
String _generatePassword() {
  const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

  var _rnd = Random.secure();
  var length = 32;

  return String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
}

var password = "foo";
var filePath = "/home/vishesh/src/gitjournal/git-salt-box/README.md";

Uint8List buildSalt(String filePath, Uint8List fileHash) {
  var fileName = p.basename(filePath);
  var keyString = "$fileName:$password";
  var k = Hash.sha512(keyString);
  var hash = Hash.blake2b(fileHash, key: k);
  var salt = hash.sublist(hash.length - TweetNaCl.nonceLength);

  assert(salt.length == TweetNaCl.nonceLength);
  return salt;
}

Future<void> encrypt() async {
  // FIXME: Check if already encrypted!!

  var content = await File(filePath).readAsBytes();
  var salt = buildSalt(filePath, Hash.sha512(content));
  // get the password
  // get the file path
  //

  print('Salt: $salt');
  print('Salt Length: ${salt.length}');
  print("Content Length: ${content.length}");

  var passwordHashed = Hash.sha256(password);
  print(passwordHashed.length);
  print(SecretBox.keyLength);
  assert(passwordHashed.length == SecretBox.keyLength);

  final box = SecretBox(passwordHashed);
  final enc = box.encrypt(content, nonce: salt);

  print("Encrypted Length: ${enc.length}");
  print(enc.nonce.length);
  print(enc.cipherText.length);

  print('Nonce Length: ${enc.nonce.lengthInBytes}');
  print('Nonce: ${enc.nonce}');
  print("Password: $password");
  print(enc.cipherText);

  await File(filePath).writeAsBytes(enc);
}

Future<void> decrypt() async {
  var content = await File(filePath).readAsBytes();
  var nonce = content.sublist(0, 24);
  var cipherText = content.sublist(24);

  print('Nonce: $nonce');
  print('Nonce Length: ${nonce.length}');
  print("Password: $password");
  print(cipherText);

  var passwordHashed = Hash.sha256(password);
  assert(passwordHashed.length == SecretBox.keyLength);

  final box = SecretBox(passwordHashed);

  var enc = EncryptedMessage(nonce: nonce, cipherText: cipherText);
  var orig = box.decrypt(enc);

  print("Content Length: ${orig.length}");

  await File(filePath).writeAsBytes(orig);
}
