import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../utils/api_constants.dart';

class CategoryService {
  /// Backend currently has no dedicated GET /categories endpoint, so we
  /// fetch products with their embedded category and return unique ones.
  static Future<List<Category>> listCategories() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/products');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Không tải được danh sách danh mục (HTTP ${response.statusCode})');
    }
    final data = jsonDecode(response.body) as List;
    final seen = <int>{};
    final result = <Category>[];
    for (final p in data) {
      final cat = p['category'];
      if (cat == null) continue;
      final c = Category.fromJson(cat as Map<String, dynamic>);
      if (seen.add(c.id)) result.add(c);
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }
}
