import 'package:equatable/equatable.dart';

import '../../core/utils/formatters.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.category,
    required this.thumbnail,
    this.brand,
    this.images = const [],
    this.isLocal = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: (json['id'] as num).toInt(),
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0,
    discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    stock: (json['stock'] as num?)?.toInt() ?? 0,
    brand: json['brand'] as String?,
    category: json['category'] as String? ?? '',
    thumbnail: json['thumbnail'] as String? ?? '',
    images:
        (json['images'] as List<dynamic>?)?.whereType<String>().toList() ??
        const [],
  );

  final int id;
  final String title;
  final String description;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String? brand;
  final String category;
  final String thumbnail;
  final List<String> images;

  /// True for products created in this session. dummyjson simulates writes
  /// without persisting them, so these exist only in the app's memory.
  final bool isLocal;

  String get categoryLabel => Formatters.humanize(category);

  bool get hasDiscount => discountPercentage > 0 && discountPercentage < 100;

  /// Price before discount (dummyjson's `price` is the selling price).
  double get originalPrice =>
      hasDiscount ? price / (1 - discountPercentage / 100) : price;

  List<String> get galleryImages {
    if (images.isNotEmpty) return images;
    return thumbnail.isEmpty ? const [] : [thumbnail];
  }

  /// Body for POST /products/add and PUT /products/{id}.
  Map<String, dynamic> toApiJson() => {
    'title': title,
    'description': description,
    'price': price,
    'discountPercentage': discountPercentage,
    'stock': stock,
    'category': category,
    if (brand != null) 'brand': brand,
    if (thumbnail.isNotEmpty) 'thumbnail': thumbnail,
  };

  Product copyWith({
    int? id,
    int? stock,
    List<String>? images,
    bool? isLocal,
  }) => Product(
    id: id ?? this.id,
    title: title,
    description: description,
    price: price,
    discountPercentage: discountPercentage,
    rating: rating,
    stock: stock ?? this.stock,
    brand: brand,
    category: category,
    thumbnail: thumbnail,
    images: images ?? this.images,
    isLocal: isLocal ?? this.isLocal,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    price,
    discountPercentage,
    rating,
    stock,
    brand,
    category,
    thumbnail,
    images,
    isLocal,
  ];
}
