import 'package:cloud_firestore/cloud_firestore.dart';

class Article {
  final String id;
  final String titleVi;
  final String causesVi;
  final String stepsVi;
  final String notesVi;
  final String? imageUrl;
  final String? pdfUrl;
  final String? videoUrl;
  final String category;
  final String brand;
  final bool isPremium;
  final Map<String, dynamic> translations;
  final int viewCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Article({
    required this.id,
    required this.titleVi,
    required this.causesVi,
    required this.stepsVi,
    required this.notesVi,
    this.imageUrl,
    this.pdfUrl,
    this.videoUrl,
    required this.category,
    required this.brand,
    required this.isPremium,
    required this.translations,
    this.viewCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Article.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? getDocDateTime(dynamic field) {
      if (field is Timestamp) {
        return field.toDate();
      }
      return null;
    }

    return Article(
      id: doc.id,
      titleVi: data['title_vi'] as String? ?? '',
      causesVi:
          data['causes_vi'] as String? ??
          data['content_vi'] as String? ??
          '', // Fallback to content_vi
      stepsVi: data['steps_vi'] as String? ?? '',
      notesVi: data['notes_vi'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      pdfUrl: data['pdfUrl'] as String?,
      videoUrl: data['videoUrl'] as String?,
      category: data['category'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      isPremium: data['isPremium'] as bool? ?? false,
      viewCount: data['viewCount'] as int? ?? 0,
      translations: data['translations'] as Map<String, dynamic>? ?? {},
      createdAt: getDocDateTime(data['createdAt']),
      updatedAt: getDocDateTime(data['updatedAt']),
    );
  }

  // Fallback preview text getter for backward compatibility
  String get contentVi =>
      causesVi.isNotEmpty ? causesVi : (stepsVi.isNotEmpty ? stepsVi : notesVi);

  // Fallback preview method for backward compatibility
  String getContent(String langCode) {
    final causes = getCauses(langCode);
    final steps = getSteps(langCode);
    final notes = getNotes(langCode);
    return causes.isNotEmpty ? causes : (steps.isNotEmpty ? steps : notes);
  }

  String getTitle(String langCode) {
    if (langCode == 'vi') return titleVi;
    if (translations.containsKey(langCode)) {
      final translation = translations[langCode];
      if (translation is Map) {
        return translation['title']?.toString() ?? titleVi;
      }
    }
    return titleVi;
  }

  String getCauses(String langCode) {
    if (langCode == 'vi') return causesVi;
    if (translations.containsKey(langCode)) {
      final translation = translations[langCode];
      if (translation is Map) {
        return translation['causes']?.toString() ?? causesVi;
      }
    }
    return causesVi;
  }

  String getSteps(String langCode) {
    if (langCode == 'vi') return stepsVi;
    if (translations.containsKey(langCode)) {
      final translation = translations[langCode];
      if (translation is Map) {
        return translation['steps']?.toString() ?? stepsVi;
      }
    }
    return stepsVi;
  }

  String getNotes(String langCode) {
    if (langCode == 'vi') return notesVi;
    if (translations.containsKey(langCode)) {
      final translation = translations[langCode];
      if (translation is Map) {
        return translation['notes']?.toString() ?? notesVi;
      }
    }
    return notesVi;
  }
}
