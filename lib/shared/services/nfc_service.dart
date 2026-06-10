import 'dart:async';
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
        onDiscovered: (NfcTag tag) async {
          try {
            final tagId = _extractTagId(tag);
            await NfcManager.instance.stopSession();
            if (!completer.isCompleted) completer.complete(tagId);
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessage: 'Error reading tag');
            if (!completer.isCompleted) completer.completeError('Failed to read NFC tag: $e');
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

    final isAvailable = await isNFCAvailable();
    if (!isAvailable) throw 'NFC is not available on this device. Please enable NFC in Settings.';

    final completer = Completer<String?>();

    try {
      await NfcManager.instance.startSession(
        alertMessage: message,
        onDiscovered: (NfcTag tag) async {
          try {
            final tagId = _extractTagId(tag);
            print('NFC Tag discovered - UID: $tagId');
            await NfcManager.instance.stopSession(alertMessage: 'Tag read successfully!');
            if (!completer.isCompleted) completer.complete(tagId);
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessage: 'Error reading tag');
            if (!completer.isCompleted) completer.completeError('Failed to read NFC tag: $e');
          }
        },
        onError: (error) async {
          if (!completer.isCompleted) completer.completeError('NFC error: $error');
          return;
        },
      );

      return await completer.future.timeout(timeout, onTimeout: () {
        NfcManager.instance.stopSession(errorMessage: 'Timeout');
        throw 'NFC reading timed out. Please hold your phone closer to the tag.';
      });
    } catch (e) {
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
            print('NFC tag written successfully. Tag UID: $uid');
            
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
  /// NTAG 213/215/216 are NFC Forum Type 2 tags (ISO 14443-3A / NFC-A).
  /// - Android: UID is in tag.data['nfca']['identifier'] or tag.data['mifareultralight']['identifier']
  /// - iOS: UID is in tag.data['mifare']['identifier'] or tag.data['iso7816']['identifier']
  /// 
  /// The UID is 7 bytes for NTAG 213/215/216 (e.g., "04:A3:12:5B:6C:7D:8E")
  String? _extractTagId(NfcTag tag) {
    try {
      final data = tag.data;

      // Android: NFC-A tags (NTAG 213, NTAG 215, NTAG 216, MIFARE Ultralight)
      if (data.containsKey('nfca')) {
        final nfca = _toMapStringDynamic(data['nfca']);
        if (nfca != null && nfca['identifier'] != null) {
          final bytes = _toBytes(nfca['identifier']);
          if (bytes.isNotEmpty) return _bytesToHex(bytes);
        }
      }

      // Android: MIFARE Ultralight (NTAG 213/215 report as this too)
      if (data.containsKey('mifareultralight')) {
        final mifare = _toMapStringDynamic(data['mifareultralight']);
        if (mifare != null && mifare['identifier'] != null) {
          final bytes = _toBytes(mifare['identifier']);
          if (bytes.isNotEmpty) return _bytesToHex(bytes);
        }
      }

      // iOS: MiFare technology (covers NTAG 213/215/216)
      if (data.containsKey('mifare')) {
        final mifare = _toMapStringDynamic(data['mifare']);
        if (mifare != null && mifare['identifier'] != null) {
          final bytes = _toBytes(mifare['identifier']);
          if (bytes.isNotEmpty) return _bytesToHex(bytes);
        }
      }

      // iOS: ISO 7816 (some tags expose UID here)
      if (data.containsKey('iso7816')) {
        final iso7816 = _toMapStringDynamic(data['iso7816']);
        if (iso7816 != null && iso7816['identifier'] != null) {
          final bytes = _toBytes(iso7816['identifier']);
          if (bytes.isNotEmpty) return _bytesToHex(bytes);
        }
      }

      // Fallback: try NDEF additional data (works on some devices)
      final ndef = Ndef.from(tag);
      if (ndef != null) {
        final additionalData = _toMapStringDynamic(ndef.additionalData);
        if (additionalData != null && additionalData['identifier'] != null) {
          final bytes = _toBytes(additionalData['identifier']);
          if (bytes.isNotEmpty) return _bytesToHex(bytes);
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

      // Last resort: use tag handle as string identifier
      final handle = tag.handle;
      if (handle.isNotEmpty) return handle;

      return null;
    } catch (e) {
      print('Error extracting NFC tag UID: $e');
      return null;
    }
  }

  /// Safely convert a dynamic value to Map<String, dynamic>.
  /// Handles _Map<Object?, Object?> from Android platform channel.
  Map<String, dynamic>? _toMapStringDynamic(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  /// Safely convert a dynamic value to List<int>.
  List<int> _toBytes(dynamic value) {
    if (value == null) return [];
    if (value is List<int>) return value;
    if (value is List) {
      try {
        return value.map((e) => (e as num).toInt()).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
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

