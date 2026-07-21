class OrderItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final double price;
  final int quantity;
  final double totalPrice;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.totalPrice,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val != null) {
        return double.tryParse(val.toString()) ?? 0.0;
      }
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val != null) {
        return int.tryParse(val.toString()) ?? 1;
      }
      return 1;
    }

    return OrderItem(
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      price: parseDouble(map['price']),
      quantity: parseInt(map['quantity']),
      totalPrice: parseDouble(map['totalPrice']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }
}
