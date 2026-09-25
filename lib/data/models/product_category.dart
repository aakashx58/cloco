import 'package:equatable/equatable.dart';

import '../../core/utils/formatters.dart';

class ProductCategory extends Equatable {
  const ProductCategory({required this.slug, required this.name});

  /// dummyjson returns `{slug, name, url}` objects; older versions returned
  /// plain strings. Accept both.
  factory ProductCategory.fromJson(dynamic json) {
    if (json is String) {
      return ProductCategory(slug: json, name: Formatters.humanize(json));
    }
    final map = json as Map<String, dynamic>;
    final slug = map['slug'] as String;
    return ProductCategory(
      slug: slug,
      name: map['name'] as String? ?? Formatters.humanize(slug),
    );
  }

  final String slug;
  final String name;

  @override
  List<Object?> get props => [slug, name];
}
