import 'package:flutter/services.dart';
import 'package:sound_effect/sound_effect.dart';

import 'sfx_asset.dart';

class SfxService {
  SfxService._();

  static final SfxService instance = SfxService._();

  final SoundEffect _plugin = SoundEffect();

  bool _initialized = false;
  Future<void>? _initializing;

  final Set<String> _loadedKeys = {};
  final Map<String, Future<void>> _loadingByKey = {};

  Future<void> init() {
    if (_initialized) return Future.value();
    return _initializing ??= _doInit();
  }

  Future<void> _doInit() async {
    try {
      await _plugin.initialize(maxStreams: 4);
      _initialized = true;
    } on PlatformException catch (e) {
      // O plugin já se encontra inicializado (ex.: hot reload ou
      // inicialização externa). Consideramos o estado válido.
      if (e.code == 'Already initialized') {
        _initialized = true;
        return;
      }
      rethrow;
    } finally {
      _initializing = null;
    }
  }

  Future<void> load(SfxAsset asset) async {
    await init();

    if (_loadedKeys.contains(asset.key)) return;

    final existing = _loadingByKey[asset.key];
    if (existing != null) return existing;

    final future = _doLoad(asset);
    _loadingByKey[asset.key] = future;

    try {
      await future;
      _loadedKeys.add(asset.key);
    } finally {
      _loadingByKey.remove(asset.key);
    }
  }

  Future<void> _doLoad(SfxAsset asset) async {
    try {
      await _plugin.load(asset.key, asset.path);
    } on PlatformException catch (e) {
      if (e.code == 'Already loaded') return;
      rethrow;
    }
  }

  Future<void> loadAll(Iterable<SfxAsset> assets) async {
    await Future.wait(assets.map(load));
  }

  Future<void> play(SfxAsset asset) async {
    try{
      await load(asset);
      await _plugin.play(asset.key);
    } catch (_) {
      // Ignorar falhas de audio, para não quebrar a experiência do jogo.
    }
  }
}