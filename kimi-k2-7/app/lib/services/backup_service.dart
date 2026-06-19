import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:share_plus/share_plus.dart';

import '../models/profile.dart';
import '../models/shopping_and_backup.dart';
import 'data_store_service.dart';
import 'profile_service.dart';

class DecryptionException implements Exception {
  final String reason;
  const DecryptionException(this.reason);

  @override
  String toString() => 'DecryptionException: $reason';
}

class BackupService {
  final ProfileService profileService;
  final DataStoreService dataStore;

  BackupService({required this.profileService, required this.dataStore});

  static const _magic = [0x45, 0x4E, 0x43]; // ENC

  Future<String> exportPlainJson() async => (await _buildBackup()).toJsonString();

  Future<String?> export({
    bool includeEncrypted = false,
    String? password,
    required bool sharePlain,
    required bool shareCompressed,
  }) async {
    final backup = await _buildBackup();
    final plainJson = backup.toJsonString();
    final directory = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final plainPath = '${directory.path}/morphcook-backup-$stamp.json';
    final gzPath = '${directory.path}/morphcook-backup-$stamp.json.gz';

    await File(plainPath).writeAsString(plainJson);
    final gzBytes = gzip.encode(utf8.encode(plainJson));
    await File(gzPath).writeAsBytes(gzBytes);

    if (password != null && password.isNotEmpty && includeEncrypted) {
      final encrypted = _encrypt(utf8.encode(plainJson), password);
      final encPath = '${directory.path}/morphcook-backup-$stamp-encrypted.json';
      await File(encPath).writeAsBytes(encrypted);
      await Share.shareXFiles([XFile(encPath)], text: 'MorphCook encrypted backup');
      return encPath;
    }

    if (sharePlain && shareCompressed) {
      await Share.shareXFiles([XFile(plainPath), XFile(gzPath)], text: 'MorphCook backup');
    } else if (sharePlain) {
      await Share.shareXFiles([XFile(plainPath)], text: 'MorphCook backup');
    } else if (shareCompressed) {
      await Share.shareXFiles([XFile(gzPath)], text: 'MorphCook backup');
    }

    return plainPath;
  }

  Future<BackupData> importFromFile({String? password, bool replace = false}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'gz'],
    );
    if (result == null || result.files.isEmpty) {
      throw const DecryptionException('No file selected.');
    }
    final file = result.files.first;
    final path = file.path;
    if (path == null) throw const DecryptionException('Invalid file path.');
    return importFromPath(path, password: password, replace: replace);
  }

  Future<BackupData> importFromPath(String path, {String? password, bool replace = false}) async {
    final bytes = await File(path).readAsBytes();
    Uint8List payload;

    if (bytes.length >= 3 &&
        bytes[0] == _magic[0] &&
        bytes[1] == _magic[1] &&
        bytes[2] == _magic[2]) {
      if (password == null || password.isEmpty) {
        throw const DecryptionException(
          'This backup is encrypted. Please provide a password.',
        );
      }
      payload = Uint8List.fromList(_decrypt(Uint8List.fromList(bytes), password));
    } else if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      payload = Uint8List.fromList(gzip.decode(bytes));
    } else {
      payload = Uint8List.fromList(bytes);
    }

    final text = utf8.decode(payload);
    final map = jsonDecode(text) as Map<String, dynamic>;
    final backup = BackupData.fromMap(map);

    if (backup.schemaVersion != 1) {
      throw const DecryptionException('Unsupported backup schema version.');
    }

    await dataStore.importState(
      saved: backup.saved,
      history: backup.history.map((k, v) => MapEntry(k, DateTime.parse(v))),
      mealPlan: backup.mealPlan,
      contentRequests: backup.contentRequests,
      replace: replace,
    );

    if (replace) {
      await profileService.saveProfile(Profile.fromMap(backup.profile));
    }

    return backup;
  }

  Uint8List _encrypt(List<int> plaintext, String password) {
    final salt = _randomBytes(16);
    final iv = _randomBytes(12);
    final key = _deriveKey(password, salt);
    final encrypter = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(
      utf8.decode(plaintext),
      iv: enc.IV(iv),
    );
    final output = BytesBuilder()
      ..add(_magic)
      ..add(salt)
      ..add(iv)
      ..add(encrypted.bytes);
    return output.toBytes();
  }

  List<int> _decrypt(Uint8List data, String password) {
    if (data.length < 3 + 16 + 12 + 16) {
      throw const DecryptionException('Backup file is corrupted and cannot be restored.');
    }
    final salt = data.sublist(3, 19);
    final iv = data.sublist(19, 31);
    final cipher = data.sublist(31);
    final key = _deriveKey(password, salt);
    final encrypter = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.gcm));
    try {
      final decrypted = encrypter.decryptBytes(
        enc.Encrypted(cipher),
        iv: enc.IV(iv),
      );
      return decrypted;
    } catch (e) {
      throw const DecryptionException('Incorrect password. Please try again.');
    }
  }

  Uint8List _deriveKey(String password, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, 10000, 32));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  Future<BackupData> _buildBackup() async {
    final profile = profileService.profile.toMap();
    final historyStrings = dataStore.lastCookedMap.map(
      (k, v) => MapEntry(k, v.toIso8601String()),
    );
    return BackupData(
      exportedAt: DateTime.now().toUtc(),
      profile: profile,
      saved: dataStore.savedRecipeIds,
      mealPlan: dataStore.mealPlan,
      history: historyStrings,
      contentRequests: dataStore.contentRequests,
    );
  }
}
