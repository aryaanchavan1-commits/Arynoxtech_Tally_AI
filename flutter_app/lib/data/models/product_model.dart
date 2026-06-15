class ProductModel {
  final int id;
  final String name;
  final String? sku;
  final String? barcode;
  final String? description;
  final int? categoryId;
  final String? categoryName;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final double mrp;
  final double gstRate;
  final double currentStock;
  final double reorderLevel;

  ProductModel({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    this.description,
    this.categoryId,
    this.categoryName,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.mrp,
    required this.gstRate,
    required this.currentStock,
    required this.reorderLevel,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      sku: json['sku'],
      barcode: json['barcode'],
      description: json['description'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      unit: json['unit'] ?? 'Pieces',
      purchasePrice: (json['purchase_price'] ?? 0).toDouble(),
      sellingPrice: (json['selling_price'] ?? 0).toDouble(),
      mrp: (json['mrp'] ?? 0).toDouble(),
      gstRate: (json['gst_rate'] ?? 0).toDouble(),
      currentStock: (json['current_stock'] ?? 0).toDouble(),
      reorderLevel: (json['reorder_level'] ?? 0).toDouble(),
    );
  }
}
