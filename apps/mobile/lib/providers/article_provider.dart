import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/article.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final articlesByCategoryProvider = StreamProvider.family<List<Article>, String>((ref, category) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('articles')
      .where('category', isEqualTo: category)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => Article.fromFirestore(doc)).toList();
      });
});

class Brand {
  final String id;
  final String name;

  Brand({required this.id, required this.name});

  factory Brand.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Brand(
      id: doc.id,
      name: data['name'] as String? ?? doc.id,
    );
  }
}

final brandsProvider = StreamProvider<List<Brand>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('brands')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => Brand.fromFirestore(doc)).toList();
      });
});

final articlesByCategoryAndBrandProvider = StreamProvider.family<List<Article>, Map<String, String>>((ref, params) {
  final category = params['category'] ?? '';
  final brand = params['brand'] ?? '';
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('articles')
      .where('category', isEqualTo: category)
      .where('brand', isEqualTo: brand)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => Article.fromFirestore(doc)).toList();
      });
});

final allArticlesProvider = StreamProvider<List<Article>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('articles')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => Article.fromFirestore(doc)).toList();
      });
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setCategory(String category) {
    state = category;
  }
}

final searchCategoryProvider = NotifierProvider<SearchCategoryNotifier, String>(SearchCategoryNotifier.new);

final filteredArticlesProvider = Provider<List<Article>>((ref) {
  final articlesAsync = ref.watch(allArticlesProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final category = ref.watch(searchCategoryProvider);

  return articlesAsync.when(
    data: (articles) {
      return articles.where((article) {
        final matchesCategory = category == 'all' || article.category == category;
        final matchesQuery = query.isEmpty ||
            article.titleVi.toLowerCase().contains(query) ||
            article.causesVi.toLowerCase().contains(query) ||
            article.stepsVi.toLowerCase().contains(query) ||
            article.notesVi.toLowerCase().contains(query);
        return matchesCategory && matchesQuery;
      }).toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

final latestArticlesProvider = FutureProvider<List<Article>>((ref) async {
  final firestore = ref.watch(firestoreProvider);
  final snapshot = await firestore
      .collection('articles')
      .orderBy('createdAt', descending: true)
      .limit(10)
      .get();
  return snapshot.docs.map((doc) => Article.fromFirestore(doc)).toList();
});

final popularArticlesProvider = FutureProvider<List<Article>>((ref) async {
  ref.keepAlive();
  final firestore = ref.watch(firestoreProvider);
  final snapshot = await firestore
      .collection('articles')
      .orderBy('viewCount', descending: true)
      .limit(10)
      .get();
  return snapshot.docs.map((doc) => Article.fromFirestore(doc)).toList();
});
