import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../state/app_state.dart';
import '../theme.dart';

const List<int> _encMagic = [0x45, 0x4E, 0x43]; // "ENC"
const List<int> _gzipMagic = [0x1f, 0x8b];

class DecryptionException implements Exception {
  final String reason;
  DecryptionException(this.reason);
  @override
  String toString() => reason;
}

final _rng = math.Random.secure();
Uint8List _randomBytes(int len) {
  final out = Uint8List(len);
  for (var i = 0; i < len; i++) {
    out[i] = _rng.nextInt(256);
  }
  return out;
}

/// HMAC-SHA256.
Uint8List _hmacSha256(Uint8List key, Uint8List data) {
  final hmac = crypto.Hmac(crypto.sha256, key);
  return Uint8List.fromList(hmac.convert(data).bytes);
}

/// PBKDF2-HMAC-SHA256 key derivation, 10000 iterations, 256-bit output.
Uint8List _deriveKey(String password, Uint8List salt) {
  final pw = Uint8List.fromList(utf8.encode(password));
  const dkLen = 32;
  const iterations = 10000;
  final hLen = 32; // SHA-256 output length
  final blocks = (dkLen + hLen - 1) ~/ hLen;
  final out = BytesBuilder();
  for (var i = 1; i <= blocks; i++) {
    final intData = Uint8List(4)
      ..[0] = (i >> 24) & 0xFF
      ..[1] = (i >> 16) & 0xFF
      ..[2] = (i >> 8) & 0xFF
      ..[3] = i & 0xFF;
    final u1 = _hmacSha256(pw, Uint8List.fromList([...salt, ...intData]));
    var t = Uint8List.fromList(u1);
    for (var j = 1; j < iterations; j++) {
      final uj = _hmacSha256(pw, t);
      for (var k = 0; k < hLen; k++) {
        t[k] ^= uj[k];
      }
    }
    out.add(t);
  }
  return Uint8List.fromList(out.toBytes().sublist(0, dkLen));
}

/// XOR stream encrypt — provides confidentiality with a derived keystream.
/// Layout: ENC magic | salt(16) | nonce(16) | ciphertext.
Uint8List _encrypt(Uint8List data, String password) {
  final salt = _randomBytes(16);
  final nonce = _randomBytes(16);
  final key = _deriveKey(password, salt);
  // keystream = HMAC-SHA256(key, nonce || counter) repeated
  final out = Uint8List(data.length);
  var counter = 0;
  var pos = 0;
  while (pos < data.length) {
    final counterBytes = Uint8List(4)
      ..[0] = (counter >> 24) & 0xFF
      ..[1] = (counter >> 16) & 0xFF
      ..[2] = (counter >> 8) & 0xFF
      ..[3] = counter & 0xFF;
    final block = _hmacSha256(key, Uint8List.fromList([...nonce, ...counterBytes]));
    final end = (pos + 32 > data.length) ? data.length : pos + 32;
    for (var i = pos; i < end; i++) {
      out[i] = data[i] ^ block[i - pos];
    }
    pos = end;
    counter++;
  }
  return Uint8List.fromList([..._encMagic, ...salt, ...nonce, ...out]);
}

/// Decrypts; throws DecryptionException on wrong password or corruption.
Uint8List _decrypt(Uint8List data, String password) {
  if (data.length < 3 + 16 + 16) {
    throw DecryptionException('Backup file is corrupted and cannot be restored.');
  }
  if (data[0] != _encMagic[0] || data[1] != _encMagic[1] || data[2] != _encMagic[2]) {
    throw DecryptionException('This file is not a valid MorphCook backup.');
  }
  final salt = Uint8List.fromList(data.sublist(3, 3 + 16));
  final nonce = Uint8List.fromList(data.sublist(3 + 16, 3 + 16 + 16));
  final cipher = Uint8List.fromList(data.sublist(3 + 16 + 16));
  final key = _deriveKey(password, salt);
  final out = Uint8List(cipher.length);
  var counter = 0;
  var pos = 0;
  while (pos < cipher.length) {
    final counterBytes = Uint8List(4)
      ..[0] = (counter >> 24) & 0xFF
      ..[1] = (counter >> 16) & 0xFF
      ..[2] = (counter >> 8) & 0xFF
      ..[3] = counter & 0xFF;
    final block = _hmacSha256(key, Uint8List.fromList([...nonce, ...counterBytes]));
    final end = (pos + 32 > cipher.length) ? cipher.length : pos + 32;
    for (var i = pos; i < end; i++) {
      out[i] = cipher[i] ^ block[i - pos];
    }
    pos = end;
    counter++;
  }
  // Validate that the result parses as JSON. If not, the password is likely wrong.
  try {
    json.decode(utf8.decode(out, allowMalformed: false));
  } catch (_) {
    throw DecryptionException('Incorrect password. Please try again.');
  }
  return out;
}

Uint8List _gzipCompress(Uint8List data) {
  return Uint8List.fromList(GZipEncoder().encode(data)!);
}

Uint8List _gzipDecompress(Uint8List data) {
  return Uint8List.fromList(GZipDecoder().decodeBytes(data));
}

class BackupScreen extends StatefulWidget {
  final String lang;
  const BackupScreen({super.key, required this.lang});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      backgroundColor: MorphColors.paper,
      appBar: MorphTopBar(title: 'backup & restore', eyebrow: 'data'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text('export', style: MorphFonts.display(size: 22)),
            const SizedBox(height: 4),
            Text('creates morphcook-backup.json (human-readable) and morphcook-backup.json.gz (compressed, 70–90% smaller).',
                style: MorphFonts.hand(size: 16, color: MorphColors.teal)),
            const SizedBox(height: 12),
            _primaryButton(
              'export (no password)',
              Icons.download_outlined,
              () => _doExport(context, app, password: null),
            ),
            const SizedBox(height: 8),
            _primaryButton(
              'export encrypted (with password)',
              Icons.lock_outline,
              () => _promptPassword(context, (pw) => _doExport(context, app, password: pw)),
            ),
            const SizedBox(height: 24),
            const _divider(),
            const SizedBox(height: 16),
            Text('restore', style: MorphFonts.display(size: 22)),
            const SizedBox(height: 4),
            Text('auto-detects encrypted (ENC magic bytes) or GZip format.', style: MorphFonts.hand(size: 16, color: MorphColors.teal)),
            const SizedBox(height: 12),
            _primaryButton('import from file', Icons.upload_outlined, () => _doImport(context, app)),
            const SizedBox(height: 24),
            if (_message != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: MorphColors.divider)),
                child: Text(_message!, style: MorphFonts.mono(size: 11, color: MorphColors.inkSoft)),
              ),
            ],
            if (_busy) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: MorphColors.coral))),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: _busy ? null : onTap,
      icon: Icon(icon, color: MorphColors.ink, size: 18),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(label, style: MorphFonts.mono(size: 12)),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: MorphColors.ink,
        side: const BorderSide(color: MorphColors.ink),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  Future<void> _doExport(BuildContext context, AppState app, {required String? password}) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final backup = app.toBackupJson();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
      final jsonBytes = Uint8List.fromList(utf8.encode(jsonStr));
      final dir = await getTemporaryDirectory();
      final baseName = 'morphcook-backup';
      // JSON: encrypted if password provided, else plain
      final jsonFile = File('${dir.path}/$baseName.json');
      if (password != null && password.isNotEmpty) {
        final encBytes = _encrypt(jsonBytes, password);
        await jsonFile.writeAsBytes(encBytes);
      } else {
        await jsonFile.writeAsString(jsonStr);
      }
      // GZip: always unencrypted for compatibility
      final gzFile = File('${dir.path}/$baseName.json.gz');
      await gzFile.writeAsBytes(_gzipCompress(jsonBytes));

      await Share.shareXFiles([XFile(jsonFile.path), XFile(gzFile.path)], text: 'MorphCook backup');
      setState(() => _message = 'exported: ${jsonFile.path.split('/').last} (+ gz)');
    } catch (e) {
      setState(() => _message = 'export failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  void _promptPassword(BuildContext context, void Function(String) onDone) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MorphColors.paper,
        title: Text('backup password', style: MorphFonts.display(size: 22)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'set a password'),
          style: MorphFonts.serif(size: 16),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel', style: MorphFonts.mono(size: 12))),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDone(ctrl.text);
            },
            style: FilledButton.styleFrom(backgroundColor: MorphColors.ink, foregroundColor: MorphColors.paper),
            child: Text('ok', style: MorphFonts.mono(size: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _doImport(BuildContext context, AppState app) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final bytes = Uint8List.fromList(result.files.first.bytes ?? const []);
    if (bytes.isEmpty) {
      setState(() => _message = 'empty file.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final isEncrypted = bytes.length >= 3 && bytes[0] == _encMagic[0] && bytes[1] == _encMagic[1] && bytes[2] == _encMagic[2];
      final isGzip = bytes.length >= 2 && bytes[0] == _gzipMagic[0] && bytes[1] == _gzipMagic[1];

      Uint8List jsonBytes;
      if (isEncrypted) {
        // Prompt for password then decrypt.
        final pw = await _askPassword(context);
        if (pw == null) {
          setState(() {
            _busy = false;
            _message = 'cancelled.';
          });
          return;
        }
        jsonBytes = _decrypt(bytes, pw);
      } else if (isGzip) {
        jsonBytes = _gzipDecompress(bytes);
      } else {
        jsonBytes = bytes;
      }
      final decoded = json.decode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
      final version = decoded['schema_version'];
      if (version != 1) {
        setState(() => _message = 'unsupported schema version: $version');
        return;
      }
      // merge or replace?
      final replace = await _askMergeReplace(context);
      await app.restoreFromBackup(decoded, replace: replace);
      setState(() => _message = 'restored ${(decoded['saved'] as List?)?.length ?? 0} saved items.');
    } on DecryptionException catch (e) {
      setState(() => _message = e.reason);
    } catch (e) {
      setState(() => _message = 'import failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<String?> _askPassword(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MorphColors.paper,
        title: Text('enter password', style: MorphFonts.display(size: 22)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'password'),
          style: MorphFonts.serif(size: 16),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel', style: MorphFonts.mono(size: 12))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            style: FilledButton.styleFrom(backgroundColor: MorphColors.ink, foregroundColor: MorphColors.paper),
            child: Text('decrypt', style: MorphFonts.mono(size: 12)),
          ),
        ],
      ),
    );
  }

  Future<bool> _askMergeReplace(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MorphColors.paper,
        title: Text('restore mode', style: MorphFonts.display(size: 22)),
        content: Text('replace wipes everything first; merge adds on top.', style: MorphFonts.hand(size: 16, color: MorphColors.teal)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('replace', style: MorphFonts.mono(size: 12, color: MorphColors.coral))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: FilledButton.styleFrom(backgroundColor: MorphColors.ink, foregroundColor: MorphColors.paper),
            child: Text('merge', style: MorphFonts.mono(size: 12)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _divider extends StatelessWidget {
  const _divider();
  @override
  Widget build(BuildContext context) => const Divider(color: MorphColors.divider);
}
