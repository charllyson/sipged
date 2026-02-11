import 'dart:collection';

class SipGedLruCache<K, V> {
  SipGedLruCache({required this.maxEntries});

  final int maxEntries;
  final _map = <K, V>{};

  V? get(K key) {
    final value = _map.remove(key);
    if (value != null) {
      // move para o fim (mais recente)
      _map[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    if (_map.containsKey(key)) {
      _map.remove(key);
    }
    _map[key] = value;

    if (_map.length > maxEntries) {
      _map.remove(_map.keys.first);
    }
  }

  void clear() => _map.clear();
}
