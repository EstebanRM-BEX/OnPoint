class UpdateProductRequest {
  final int productId;
  final String name;
  final String barcode;
  final String defaultCode;
  final String listPrice;
  final String weight;
  final String volume;

  UpdateProductRequest({
    required this.productId,
    required this.name,
    required this.barcode,
    required this.defaultCode,
    required this.listPrice,
    required this.weight,
    required this.volume,
  });

  Map<String, dynamic> toMap() {
    return {
      "product_id": productId,
      "name": name,
      "barcode": barcode,
      "default_code": defaultCode, 
      "list_price": listPrice,
      "weight": weight,
      "volume": volume,
    };
  }
}
