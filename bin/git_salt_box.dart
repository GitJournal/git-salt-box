#!/usr/bin/env dart

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_git/dart_git.dart';
import 'package:git_salt_box/git_salt_box.dart';

var password = "foo";

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    log("Arguments Missing");
    exit(1);
  }
  log(arguments);

  var command = arguments[0];
  switch (command) {
    // Encrypt the file
    case "clean":
      var filePath = arguments[1];
      var box = GitSaltBox(password: password);
      var fileContents = File(filePath).readAsBytesSync();
      var encFile = box.encrypt(filePath, fileContents);
      stdout.add(encFile);

      break;

    // Decrypt the file
    case "smudge":
      var encMessage = readInput();
      try {
        var box = GitSaltBox(password: password);
        var origMsg = box.decrypt(encMessage);
        stdout.add(origMsg);
      } catch (ex) {
        log(ex);
        stdout.add(encMessage);
      }
      break;

    // Decrypt the file (for git-diff)
    case "textconv":
      var filePath = arguments[1];
      var encMessage = File(filePath).readAsBytesSync();

      try {
        var box = GitSaltBox(password: password);
        var origMsg = box.decrypt(encMessage);
        stdout.add(origMsg);
      } catch (ex) {
        log(ex);
        stdout.add(encMessage);
      }
      break;

    case "init":
      await init();
      break;
  }
}

Uint8List readInput() {
  var input = <int>[];
  while (true) {
    var b = stdin.readByteSync();
    if (b == -1) {
      return Uint8List.fromList(input);
    }
    input.add(b);
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

void log(dynamic message) {
  File('/tmp/k').writeAsStringSync(
    message.toString() + '\n',
    mode: FileMode.writeOnlyAppend,
  );
}
