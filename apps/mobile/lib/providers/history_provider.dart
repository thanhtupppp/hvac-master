import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryNotifier extends AsyncNotifier<List<String>> {
  static const _historyKey = 'recent_articles_history';
  static const _maxItems = 20;

  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? [];
  }

  Future<void> addArticleToHistory(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHistory = prefs.getStringList(_historyKey) ?? [];
    
    // Only increment viewCount if this is a new view (not already at top)
    final isNewView = currentHistory.isEmpty || currentHistory.first != articleId;
    
    // Remove if exists to move to top
    currentHistory.remove(articleId);
    
    // Insert at top
    currentHistory.insert(0, articleId);
    
    // Keep max limit
    if (currentHistory.length > _maxItems) {
      currentHistory.removeLast();
    }
    
    await prefs.setStringList(_historyKey, currentHistory);
    state = AsyncData(currentHistory);
    
    // Increment viewCount in Firestore (fire-and-forget)
    if (isNewView) {
      FirebaseFirestore.instance
          .collection('articles')
          .doc(articleId)
          .update({'viewCount': FieldValue.increment(1)})
          .catchError((_) {}); // Silently ignore errors
    }
  }
  
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    state = const AsyncData([]);
  }
}

final historyProvider = AsyncNotifierProvider<HistoryNotifier, List<String>>(HistoryNotifier.new);
