// lib/services/ingredient_normalizer.dart
class IngredientNormalizer {
  static List<String> normalizeIngredients(List<String> raw) {
    final stopWords = <String>{
      'ingredients',
      'ingrédient',
      'içindekiler',
      'içerikler',
      'icerikler',
      'content',
      'contents',
      'inci',
      'ingredient',
      'ingredients list',
      'içerik listesi',
      'icerik listesi'
    };

    // Satır ön-temizliği: başlıkları ve ayraçları normalize et
    String preclean(String s) {
      var t = s.replaceAll(
          RegExp(r'[\u00AD\u200B-\u200D\uFEFF]'), ''); // zero-width

      // "ingredients:", "içindekiler:" vb. başlıkları kaldır (case-insensitive)
      t = t.replaceAll(
        RegExp(
          r'\b(ingredients?|ingrédient|içindekiler|içerikler|icerikler|inci|content|contents)\s*:',
          caseSensitive: false,
        ),
        ' ',
      );

      // Ayraçları virgüle çevir: • · | / ; ve satır sonu
      t = t.replaceAll(RegExp(r'[•·\|/;]'), ',');
      t = t.replaceAll('\n', ',');

      return t;
    }

    // Tek bir tokenı sadeleştirme
    String cleanToken(String s) => s
        .toLowerCase()
        .trim()
        // tireleri boşluk yap (propylene-glycol -> propylene glycol)
        .replaceAll(RegExp(r'[-]+'), ' ')
        // kalan nokta/yıldız vs.
        .replaceAll(RegExp(r'[\.\*]'), ' ')
        // çoklu boşluk -> tek boşluk
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final set = <String>{};

    for (var line in raw) {
      if (line.trim().isEmpty) continue;

      // Ön-temizlik
      final normalized = preclean(line);

      // Ana split: virgül (çoğu ayraç zaten virgüle çevrildi)
      final parts = normalized.split(',');

      for (var p in parts) {
        if (p.trim().isEmpty) continue;

        // Parantez içlerini ayrı token yap
        final innerMatches =
            RegExp(r'\((.*?)\)').allMatches(p).map((m) => m.group(1) ?? '');

        // Parantezleri çıkarıp ana kısmı temizle
        final base = cleanToken(p.replaceAll(RegExp(r'\(.*?\)'), ''));

        if (base.isNotEmpty && base.length > 1 && !stopWords.contains(base)) {
          set.add(base);
        }

        // Parantez içlerini de token olarak ekle
        for (final x in innerMatches) {
          final v = cleanToken(x);
          if (v.isNotEmpty && v.length > 1 && !stopWords.contains(v)) {
            set.add(v);
          }
        }
      }
    }

    // Çok kısa artıkları ve dolgu kelimeleri ele
    set.removeWhere((e) => e.length <= 1);
    const tailStop = {'and', 'with', 'contains', 'ile', 've'};
    set.removeWhere((e) => tailStop.contains(e));

    return set.toList();
  }
}
