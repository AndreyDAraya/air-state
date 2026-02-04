import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'air_controller.dart';

/// Configuration for state persistence
class StatePersistenceConfig {
  /// State keys to persist
  final List<String> keys;

  /// Debounce duration before saving (prevents too frequent saves)
  final Duration debounce;

  /// Storage key prefix
  final String storageKey;

  /// Whether to automatically restore on initialization
  final bool autoRestore;

  const StatePersistenceConfig({
    required this.keys,
    this.debounce = const Duration(milliseconds: 500),
    this.storageKey = 'air_state',
    this.autoRestore = true,
  });
}

/// Abstract storage adapter for state persistence
abstract class PersistenceStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

/// In-memory storage for testing
class InMemoryPersistenceStorage implements PersistenceStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }
}

/// State persistence manager for Air Framework
class AirStatePersistence {
  static final AirStatePersistence _instance = AirStatePersistence._();
  factory AirStatePersistence() => _instance;
  AirStatePersistence._();

  StatePersistenceConfig? _config;
  PersistenceStorage _storage = InMemoryPersistenceStorage();
  Timer? _debounceTimer;
  bool _isDirty = false;
  final List<VoidCallback> _listeners = [];
  String? _stateObserverId;

  /// Current configuration
  StatePersistenceConfig? get config => _config;

  /// Check if persistence is configured
  bool get isConfigured => _config != null;

  /// Set the storage adapter
  void setStorage(PersistenceStorage storage) {
    _storage = storage;
  }

  /// Configure persistence for specific state keys
  Future<void> configure(StatePersistenceConfig config) async {
    _config = config;

    // Setup listener for state changes
    _stateObserverId = Air().addStateObserver((key, value) {
      if (config.keys.contains(key)) {
        _markDirty();
      }
    });

    Air.delegate.log(
      'Configured state persistence',
      context: {'keys': config.keys, 'storageKey': config.storageKey},
    );

    // Auto-restore if configured
    if (config.autoRestore) {
      await restore();
    }
  }

  /// Mark state as dirty (needs saving)
  void _markDirty() {
    if (_config == null) return;

    _isDirty = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_config!.debounce, () {
      if (_isDirty) {
        save();
        _isDirty = false;
      }
    });
  }

  /// Save current state to storage
  Future<void> save() async {
    if (_config == null) {
      Air.delegate.log('State persistence not configured', isError: true);
      return;
    }

    try {
      final stateData = <String, dynamic>{};

      for (final key in _config!.keys) {
        final controller = Air().debugStates[key];
        if (controller != null) {
          stateData[key] = _serialize(controller.value);
        }
      }

      final jsonString = jsonEncode({
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'data': stateData,
      });

      await _storage.write(_config!.storageKey, jsonString);

      Air.delegate.log(
        'State saved',
        context: {'keys': stateData.keys.toList()},
      );

      for (final listener in _listeners) {
        listener();
      }
    } catch (e) {
      Air.delegate.log('Failed to save state: $e', isError: true);
    }
  }

  /// Restore state from storage
  Future<void> restore() async {
    if (_config == null) {
      Air.delegate.log('State persistence not configured', isError: true);
      return;
    }

    try {
      final jsonString = await _storage.read(_config!.storageKey);

      if (jsonString == null) {
        Air.delegate.log('No persisted state found');
        return;
      }

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>?;

      if (data == null) return;

      for (final entry in data.entries) {
        if (_config!.keys.contains(entry.key)) {
          Air()
              .state(entry.key, initialValue: entry.value)
              .setValue(entry.value, sourceModuleId: 'persistence');
        }
      }

      Air.delegate.log('State restored', context: {'keys': data.keys.toList()});
    } catch (e) {
      Air.delegate.log('Failed to restore state: $e', isError: true);
    }
  }

  /// Clear persisted state
  Future<void> clear() async {
    if (_config == null) return;

    try {
      await _storage.remove(_config!.storageKey);
      Air.delegate.log('Persisted state cleared');
    } catch (e) {
      Air.delegate.log('Failed to clear persisted state: $e', isError: true);
    }
  }

  /// Add listener for save events
  void addSaveListener(VoidCallback callback) {
    _listeners.add(callback);
  }

  /// Remove save listener
  void removeSaveListener(VoidCallback callback) {
    _listeners.remove(callback);
  }

  /// Serialize a value for storage
  dynamic _serialize(dynamic value) {
    if (value == null || value is bool || value is num || value is String) {
      return value;
    }

    if (value is DateTime) {
      return {'__type': 'DateTime', 'value': value.toIso8601String()};
    }

    if (value is List) {
      return value.map((e) => _serialize(e)).toList();
    }

    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _serialize(v)));
    }

    // Try toJson for custom objects
    try {
      final dynamic obj = value;
      if (obj.toJson != null) {
        return _serialize(obj.toJson());
      }
    } catch (_) {}

    // Try toMap for custom objects
    try {
      final dynamic obj = value;
      if (obj.toMap != null) {
        return _serialize(obj.toMap());
      }
    } catch (_) {}

    // Fallback to string representation
    return value.toString();
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
    _listeners.clear();
    if (_stateObserverId != null) {
      Air().removeStateObserverById(_stateObserverId!);
    }
    _config = null;
  }
}
