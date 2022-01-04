#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_git/dart_git.dart';
import 'package:pinenacl/api.dart';

import 'package:git_salt_box/git_salt_box.dart';

import 'qr.dart';

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
      try {
        init();
      } on NotAGitRepoException catch (e) {
        print(e);
        exit(1);
      } on GitSaltBoxNotInitialized catch (e) {
        print(e);
        exit(1);
      }
      break;

    case "display":
      final password = _fetchPassword();
      var pStr = base64.encode(password);
      print('Password: $pStr\n');
      print(printQr(pStr));
      break;

    case "merge":
      var baseEnc = arguments[1];
      var localEnc = arguments[2];
      var remoteEnc = arguments[3];

      var markerSize = arguments[4];
      var tempFile = arguments[5];

      // TODO: Decrypt all of them

      // Call git-merge-file

      try {
        init();
      } on NotAGitRepoException catch (e) {
        print(e);
        exit(1);
      } on GitSaltBoxNotInitialized catch (e) {
        print(e);
        exit(1);
      }
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
    throw NotAGitRepoException();
  }

  var repo = GitRepository.load(repoPath).getOrThrow();
  var gjSection = repo.config.getOrCreateSection(_execName);
  if (gjSection.isNotEmpty) {
    throw GitSaltBoxNotInitialized();
  }

  gjSection.options["version"] = GitSaltBox.version.toString();
  gjSection.options["password"] = _generatePassword();

  var filterSection =
      repo.config.getOrCreateSection('filter').getOrCreateSection(_execName);
  filterSection.options['smudge'] = '"$_execName" smudge';
  filterSection.options['clean'] = '"$_execName" clean %f';

  var diffSection =
      repo.config.getOrCreateSection('diff').getOrCreateSection(_execName);
  diffSection.options['textconv'] = '"$_execName" textconv';
  diffSection.options['binary'] = 'true';

  var mergeSection =
      repo.config.getOrCreateSection('merge').getOrCreateSection(_execName);
  mergeSection.options['driver'] = '"$_execName" merge %O %A %B %L %P';
  mergeSection.options['name'] = 'Merge Git-Salt-Box Secret Files';

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
