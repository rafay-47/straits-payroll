import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:nfc_manager/nfc_manager.dart';

/// Service for NFC operations
/// Compatible with NTAG 213, NTAG 215, NTAG 216, MIFARE Ultralight,
/// and other NFC Forum Type 2 tags (ISO 14443-3A)
class NFCService {
  // ============================================
  // NFC AVAILABILITY
  // ============================================

  Future<bool> isNFCAvailable() async {
    if (kIsWeb) return false;
    
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // READ NFC TAG
  // ============================================

  /// Read NFC tag and return the UID as hex string.
  /// Uses a Completer to properly wait for the async onDiscovered callback.
  Future<String?> readNFCTag({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (kIsWeb) throw 'NFC is not supported on web';

    final isAvailable = await isNFCAvailable();
    if (!isAvailable) throw 'NFC is not available on this device. Please enable NFC in Settings.';

    final completer = Completer<String?>();

    try {
      await NfcManager.instance.startSession(
        // Poll for ISO 14443 (NFC-A) tags - required for NTAG 213/215/216
        // and Mifare Ultralight. Without this, the session may detect
        // the tag but fail to read its UID on some devices.
        pollingOptions: {NfcPollingOption.iso14443},
        onDiscovered: (NfcTag tag) async {
          try {
            developer.log(
              'NFC tag discovered. techs=${tag.data.keys.toList()}',
              name: 'NFCService',
            );
            final tagId = _extractTagId(tag);
            developer.log(
              'NFC tag UID/CSN extracted: $tagId',
              name: 'NFCService',
            );
            await NfcManager.instance.stopSession();
            if (!completer.isCompleted) completer.complete(tagId);
          } catch (e, st) {
            developer.log(
              'Failed to read NFC tag',
              name: 'NFCService',
              error: e,
              stackTrace: st,
            );
            try {
              await NfcManager.instance.stopSession(errorMessage: 'Error reading tag');
            } catch (_) {}
            if (!completer.isCompleted) {
              completer.completeError('Failed to read NFC tag: $e');
            }
          }
        },
        onError: (error) async {
          if (!completer.isCompleted) completer.completeError('NFC error: $error');
          return;
        },
      );

      // Wait for tag discovery or timeout
      return await completer.future.timeout(timeout, onTimeout: () {
        NfcManager.instance.stopSession(errorMessage: 'Timeout');
        throw 'NFC reading timed out. Please try again.';
      });
    } catch (e) {
      if (!completer.isCompleted) {
        try { await NfcManager.instance.stopSession(); } catch (_) {}
      }
      rethrow;
    }
  }

  /// Read NFC tag with a user-facing message (iOS shows this in the NFC sheet).
  /// Uses a Completer to properly wait for the onDiscovered callback.
  Future<String?> readNFCTagWithMessage({
    required String message,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (kIsWeb) throw 'NFC is not supported on web';

    // Plain prints so they always show in `flutter run` (developer.log can be
    // filtered). If you do not see this line when you tap, the method is not
    // being reached from the UI.
    print('[NFC] >>> readNFCTagWithMessage called. message="$message"');

    final isAvailable = await isNFCAvailable();
    print('[NFC] isAvailable=$isAvailable');
    if (!isAvailable) throw 'NFC is not available on this device. Please enable NFC in Settings.';

    final completer = Completer<String?>();

    try {
      print('[NFC] starting session with pollingOptions={iso14443}');
      await NfcManager.instance.startSession(
        alertMessage: message,
        // Poll for ISO 14443 (NFC-A) tags - required for NTAG 213/215/216
        // and Mifare Ultralight. Without this, the session may detect
        // the tag but fail to read its UID on some devices.
        pollingOptions: {NfcPollingOption.iso14443},
        onDiscovered: (NfcTag tag) async {
          print('[NFC] <<< onDiscovered fired. techs=${tag.data.keys.toList()}');
          try {
            final tagId = _extractTagId(tag);
            print('[NFC] extracted UID/CSN: $tagId');
            try {
              await NfcManager.instance.stopSession(alertMessage: 'Tag read successfully!');
            } catch (e) {
              print('[NFC] stopSession after read threw (ignored): $e');
            }
            if (!completer.isCompleted) completer.complete(tagId);
          } catch (e, st) {
            print('[NFC] onDiscovered handler threw: $e\n$st');
            try {
              await NfcManager.instance.stopSession(errorMessage: 'Error reading tag');
            } catch (_) {}
            if (!completer.isCompleted) {
              completer.completeError('Failed to read NFC tag: $e');
            }
          }
        },
        onError: (error) async {
          print('[NFC] !!! onError fired: $error');
          if (!completer.isCompleted) completer.completeError('NFC error: $error');
          return;
        },
      );
      print('[NFC] startSession returned, awaiting completer...');

      return await completer.future.timeout(timeout, onTimeout: () {
        print('[NFC] --- timeout after ${timeout.inSeconds}s, no tag discovered');
        NfcManager.instance.stopSession(errorMessage: 'Timeout');
        throw 'NFC reading timed out. Please hold your phone closer to the tag.';
      });
    } catch (e) {
      print('[NFC] outer catch: $e');
      if (!completer.isCompleted) {
        try { await NfcManager.instance.stopSession(); } catch (_) {}
      }
      rethrow;
    }
  }

  // ============================================
  // WRITE NFC TAG
  // ============================================

  /// Write project data to an NFC tag (NTAG 213 has 144 bytes, NTAG 215 has 504 bytes)
  Future<bool> writeNFCTag({
    required String projectId,
    required String projectName,
  }) async {
    if (kIsWeb) throw 'NFC is not supported on web';

    final isAvailable = await isNFCAvailable();
    if (!isAvailable) throw 'NFC is not available on this device';

    final completer = Completer<bool>();

    try {
      await NfcManager.instance.startSession(
        // Poll for ISO 14443 (NFC-A) tags - required for NTAG 213/215/216.
        pollingOptions: {NfcPollingOption.iso14443},
        onDiscovered: (NfcTag tag) async {
          final ndef = Ndef.from(tag);

          if (ndef == null) {
            await NfcManager.instance.stopSession(errorMessage: 'Tag is not NDEF formatted. Please use an NTAG 213 or NTAG 215 tag.');
            if (!completer.isCompleted) completer.complete(false);
            return;
          }

          if (!ndef.isWritable) {
            await NfcManager.instance.stopSession(errorMessage: 'Tag is read-only');
            if (!completer.isCompleted) completer.complete(false);
            return;
          }

          final payload = 'PROJECT:$projectId:$projectName';
          final maxCapacity = ndef.maxSize;
          
          // NTAG 213 = 144 bytes usable, NTAG 215 = 504 bytes
          if (payload.length > maxCapacity) {
            await NfcManager.instance.stopSession(
              errorMessage: 'Tag capacity too small (${maxCapacity}B). Use NTAG 215 for longer project names.',
            );
            if (!completer.isCompleted) completer.complete(false);
            return;
          }

          try {
            final ndefMessage = NdefMessage([
              NdefRecord.createText(payload),
            ]);
            await ndef.write(ndefMessage);
            
            // Also read the UID for logging/storage
            final uid = _extractTagId(tag);
            developer.log(
              'NFC tag written successfully. Tag UID: $uid',
              name: 'NFCService',
            );
            
            await NfcManager.instance.stopSession(alertMessage: 'Tag written successfully!');
            if (!completer.isCompleted) completer.complete(true);
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessage: 'Write failed: $e');
            if (!completer.isCompleted) completer.complete(false);
          }
        },
      );

      return await completer.future.timeout(const Duration(seconds: 30), onTimeout: () {
        NfcManager.instance.stopSession(errorMessage: 'Timeout');
        return false;
      });
    } catch (e) {
      throw 'Failed to write NFC tag: $e';
    }
  }

  /// Read NFC tag UID and return it (for admin to register a tag's UID to a project)
  Future<String?> readNFCTagUid() async {
    return readNFCTagWithMessage(message: 'Hold your phone near the NFC tag to read its ID');
  }

  // ============================================
  // CANCEL OPERATION
  // ============================================

  Future<void> stopSession({String? errorMessage}) async {
    if (kIsWeb) return;
    
    try {
      await NfcManager.instance.stopSession(errorMessage: errorMessage);
    } catch (e) {
      // Ignore errors when stopping - session may already be closed
    }
  }

  // ============================================
  // TAG ID EXTRACTION
  // ============================================

  /// Convert bytes to hex string (e.g., [0x04, 0xA3, 0x12] -> "04:A3:12")
  String _bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
  }

  /// Extract the unique tag UID from an NFC tag.
  ///
  /// Supports the tag types the client is likely to deploy, plus common
  /// payment cards. All keys use the platform-native names from
  /// `nfc_manager` 3.5.1 (Android: lowercase, e.g. `nfca`; iOS: mixed case,
  /// e.g. `miFareTag`).
  ///
  /// **Android key map** (per `Translator.kt` in nfc_manager):
  /// - `nfca` — NFC-A (NTAG 213/215/216, MIFARE Ultralight/Classic/Desfire,
  ///   and the underlying transport for Visa payWave, Mastercard PayPass, etc.)
  /// - `isodep` — ISO 14443-4 / ISO-DEP layer (Type 4 cards: debit/credit,
  ///   MIFARE DESFire, NDEF-formatted smart cards)
  /// - `nfcb` — NFC-B (some ISO 14443-4B payment cards, transit cards)
  /// - `nfcf` — FeliCa (Japanese transit / e-money)
  /// - `nfcv` — ISO 15693 vicinity (library tags, laundry tags)
  /// - `mifareultralight` — MIFARE Ultralight (some NTAGs also report here)
  /// - `mifareclassic` — MIFARE Classic 1K/4K
  /// - `ndefformatable` — NDEF-formattable tags
  /// - `ndef` — NDEF-formatted tags (UID lives in `identifier`)
  ///
  /// **iOS key map** (per `Translator.swift` in nfc_manager):
  /// - `miFareTag` — MIFARE (NTAG, Ultralight, Classic, DESFire)
  /// - `mifare` — older plugin versions
  /// - `iso7816` — contactless payment cards on iOS
  /// - `felica` — FeliCa on iOS
  /// - `iso15693` — ISO 15693 on iOS
  ///
  /// The UID is 4-7 bytes for NTAG 213/215/216, 4-10 bytes for contactless
  /// payment cards, 4 bytes for MIFARE Classic, and 8 bytes for FeliCa.
  String? _extractTagId(NfcTag tag) {
    try {
      final data = tag.data;

      // Dump raw data to log so we can debug if extraction fails. The
      // nfc_manager plugin's platform channel returns the inner maps as
      // `Map<dynamic, dynamic>` (untyped) — so we MUST NOT cast them to
      // `Map<String, dynamic>` or the cast throws and we return null. We
      // use a defensive `_bytesFromMap` helper instead.
      print('[NFC] raw data keys=${data.keys.toList()} '
          'nfcaType=${data['nfca']?.runtimeType} '
          'isodepType=${data['isodep']?.runtimeType}');

      // Ordered probe of every known tech. The first one with a non-empty
      // `identifier` wins. Order is mostly arbitrary; nfca and isodep come
      // first because they cover the vast majority of tags.
      for (final key in const [
        'nfca',
        'isodep',
        'nfcb',
        'nfcf',
        'nfcv',
        'mifareultralight',
        'mifareclassic',
        'ndefformatable',
        'ndef',
        'miFareTag',
        'mifare',
        'iso7816',
        'felica',
        'iso15693',
      ]) {
        final bytes = _bytesFromMap(data[key], 'identifier');
        if (bytes != null && bytes.isNotEmpty) {
          print('[NFC] extracted UID/CSN from key="$key": ${_bytesToHex(bytes)}');
          return _bytesToHex(bytes);
        }
      }

      // Fallback: try NDEF additional data (works on some devices).
      final ndef = Ndef.from(tag);
      if (ndef != null) {
        final addId = ndef.additionalData['identifier'];
        final bytes = _asIntList(addId);
        if (bytes != null && bytes.isNotEmpty) {
          return _bytesToHex(bytes);
        }
      }

      // Generic fallback: recursively scan the platform payload for common
      // identifier keys used by different devices/plugin versions.
      final recursiveId = _findIdentifierRecursive(data);
      if (recursiveId != null && recursiveId.isNotEmpty) {
        return recursiveId;
      }

      // Last data fallback: if tag exposes NDEF records but no explicit UID,
      // build a stable fingerprint from first record payload bytes.
      if (ndef != null && ndef.cachedMessage != null) {
        final records = ndef.cachedMessage!.records;
        if (records.isNotEmpty) {
          final payload = records.first.payload;
          if (payload.isNotEmpty) {
            return 'NDEF:${_bytesToHex(payload)}';
          }
        }
      }

      // Last resort: use tag handle as string identifier.
      final handle = tag.handle;
      if (handle.isNotEmpty) return handle;

      print('[NFC] !!! could not extract UID. keys=${data.keys.toList()} '
          'nfca=${data['nfca']} isodep=${data['isodep']}');
      return null;
    } catch (e, st) {
      print('[NFC] !!! error extracting UID: $e\n$st');
      return null;
    }
  }

  /// Defensive read: given a dynamic map (which may be `Map<dynamic, dynamic>`
  /// from the platform channel, not `Map<String, dynamic>`) and a String key,
  /// return the value as `List<int>` if it is a list of ints, else null.
  /// Tolerates any map type without throwing on cast.
  List<int>? _bytesFromMap(dynamic map, String key) {
    if (map is! Map) return null;
    final value = map[key];
    return _asIntList(value);
  }

  /// Convert a dynamic value to `List<int>` if it is a list of integers
  /// (handles `List<int>`, `Uint8List`, and `List<dynamic>` of int).
  List<int>? _asIntList(dynamic value) {
    if (value == null) return null;
    if (value is List<int>) return value;
    if (value is List) {
      if (value.isEmpty) return null;
      if (value.every((e) => e is int)) {
        return List<int>.from(value);
      }
    }
    return null;
  }

  /// Check if device supports NFC
  static bool get isSupported => !kIsWeb;

  String? _findIdentifierRecursive(dynamic value) {
    if (value == null) return null;

    if (value is List<int>) {
      if (value.isEmpty) return null;
      return _bytesToHex(value);
    }

    if (value is List) {
      if (value.isEmpty) return null;
      if (value.every((e) => e is int)) {
        return _bytesToHex(List<int>.from(value));
      }
      for (final item in value) {
        final found = _findIdentifierRecursive(item);
        if (found != null && found.isNotEmpty) return found;
      }
      return null;
    }

    if (value is Map) {
      const keys = ['identifier', 'id', 'uid'];
      for (final key in keys) {
        if (value.containsKey(key)) {
          final found = _findIdentifierRecursive(value[key]);
          if (found != null && found.isNotEmpty) return found;
        }
      }
      for (final entry in value.entries) {
        final found = _findIdentifierRecursive(entry.value);
        if (found != null && found.isNotEmpty) return found;
      }
      return null;
    }

    return null;
  }
}

