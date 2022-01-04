#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_git/dart_git.dart';
import 'package:pinenacl/api.dart';

import 'package:git_salt_box/git_salt_box.dart';

void main(List<String> arguments) {
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
      var fileContents = File(filePath).readAsBytesSync();

      try {
        var box = GitSaltBox(password: _fetchPassword());
        var encFile = box.encrypt(filePath, fileContents);
        stdout.add(encFile);
      } on GSBAlreadyEncrypted catch (_) {
        stdout.add(fileContents);
      } on NotAGitRepoException catch (e) {
        print(e);
        exit(1);
      } on GitSaltBoxNotInitialized catch (e) {
        print(e);
        exit(1);
      }

      break;

    // Decrypt the file
    case "smudge":
      var encMessage = readInput();

      try {
        var box = GitSaltBox(password: _fetchPassword());
        var origMsg = box.decrypt(encMessage);
        stdout.add(origMsg);
      } on GSBNotEncrypted catch (_) {
        stdout.add(encMessage);
      } on NotAGitRepoException catch (e) {
        print(e);
        exit(1);
      } on GitSaltBoxNotInitialized catch (e) {
        print(e);
        exit(1);
      }
      break;

    // Decrypt the file (for git-diff)
    case "textconv":
      var filePath = arguments[1];
      var encMessage = File(filePath).readAsBytesSync();

      try {
        var box = GitSaltBox(password: _fetchPassword());
        var origMsg = box.decrypt(encMessage);
        stdout.add(origMsg);
      } on GSBNotEncrypted catch (_) {
        stdout.add(encMessage);
      } on NotAGitRepoException catch (e) {
        print(e);
        exit(1);
      } on GitSaltBoxNotInitialized catch (e) {
        print(e);
        exit(1);
      }
      break;

    case "init":
      init();
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

void init() {
  var repoPath = GitRepository.findRootDir(Directory.current.path);
  if (repoPath == null) {
    print(
        'fatal: not a git repository (or any of the parent directories): .git');
    exit(1);
  }

  var repo = GitRepository.load(repoPath).getOrThrow();
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
  gjSection.options["version"] = GitSaltBox.version.toString();
  gjSection.options["password"] = _generatePassword();

  var r = repo.saveConfig();
  if (r.isFailure) {
    print(r.stackTrace);
    exit(1);
  }
}

Uint8List _fetchPassword() {
  var repoPath = GitRepository.findRootDir(Directory.current.path);
  if (repoPath == null) {
    throw NotAGitRepoException();
  }

  var repo = GitRepository.load(repoPath).getOrThrow();
  var gjSection = repo.config.section(_execName);
  if (gjSection == null) {
    throw GitSaltBoxNotInitialized();
  }

  var password = gjSection.options["password"];
  if (password == null) {
    throw GitSaltBoxNotInitialized();
  }
  var p = base64.decode(password);
  if (p.length != GitSaltBox.passwordLength) {
    throw PasswordCorrupted();
  }
  return p;
}

String _generatePassword() {
  var bytes = PineNaClUtils.randombytes(32);
  return base64.encode(bytes);
}

void log(dynamic message) {
  File('/tmp/k').writeAsStringSync(
    message.toString() + '\n',
    mode: FileMode.writeOnlyAppend,
  );
}

class NotAGitRepoException implements Exception {
  @override
  String toString() =>
      "fatal: not a git repository (or any of the parent directories): .git";
}

class GitSaltBoxNotInitialized implements Exception {
  @override
  String toString() => "GitSaltBox has not been installed";
}

class PasswordCorrupted implements Exception {}
