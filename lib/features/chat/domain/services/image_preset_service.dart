import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../entities/image_preset.dart';

class ImagePresetService {
  ImagePresetService._();
  static final ImagePresetService instance = ImagePresetService._();

  final ValueNotifier<List<ImagePreset>> presetsNotifier =
      ValueNotifier<List<ImagePreset>>(defaultImagePresets);

  List<ImagePreset> get presets => presetsNotifier.value;

  bool _initialized = false;

  /// Returns true only if presets were successfully loaded from Firestore.
  bool get isLoaded => _initialized;

  Future<List<ImagePreset>>? _inFlightFetch;

  /// Loads presets from Firestore.
  /// Falls back to [defaultImagePresets] immediately, updating asynchronously
  /// with live data from Firestore.
  Future<List<ImagePreset>> fetchPresets({bool forceRefresh = false}) {
    if (_initialized && !forceRefresh) {
      return Future.value(presets);
    }

    if (_inFlightFetch != null && !forceRefresh) {
      return _inFlightFetch!;
    }

    final future = _fetchFromFirestore(forceRefresh: forceRefresh);
    _inFlightFetch = future;
    return future;
  }

  Future<List<ImagePreset>> _fetchFromFirestore({bool forceRefresh = false}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('image_presets')
          .get(GetOptions(
            source: forceRefresh ? Source.server : Source.serverAndCache,
          ));

      if (snapshot.docs.isNotEmpty) {
        final Map<String, ImagePreset> defaultMap = {
          for (final p in defaultImagePresets) p.id: p,
        };

        final List<ImagePreset> loaded = [];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final id = doc.id;
          final fallback = defaultMap[id];

          final title = data['title'] as String? ?? fallback?.title ?? id;
          final imagePath = data['imagePath'] as String? ??
              fallback?.imagePath ??
              'assets/images/create_image_categories/$id.png';
          final prompt = data['prompt'] as String? ?? fallback?.prompt ?? '';
          final order = (data['order'] as num?)?.toInt() ?? fallback?.order;

          loaded.add(ImagePreset(
            id: id,
            title: title,
            imagePath: imagePath,
            prompt: prompt,
            order: order,
          ));
        }

        // Sort by order field if available
        loaded.sort((a, b) {
          final ordA = a.order ?? 999;
          final ordB = b.order ?? 999;
          return ordA.compareTo(ordB);
        });

        // Append any default presets that might be missing from Firestore
        final loadedIds = loaded.map((e) => e.id).toSet();
        for (final def in defaultImagePresets) {
          if (!loadedIds.contains(def.id)) {
            loaded.add(def);
          }
        }

        debugPrint('[ImagePresetService] Successfully fetched ${loaded.length} presets from Firestore:');
        for (final p in loaded) {
          debugPrint('  • [${p.id}] "${p.title}" (order: ${p.order}, len: ${p.prompt.length} chars)');
          debugPrint('    Prompt: ${p.prompt}');
        }

        presetsNotifier.value = loaded;
        _initialized = true;
        return loaded;
      }
    } catch (e) {
      debugPrint('Warning: Failed to fetch image presets from Firestore: $e');
    } finally {
      _inFlightFetch = null;
    }

    return defaultImagePresets;
  }
}
