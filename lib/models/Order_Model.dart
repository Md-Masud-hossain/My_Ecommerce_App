
class OrderItem {
  final String productName;
  final int quantity;
  final double price;

  const OrderItem({
    required this.productName,
    required this.quantity,
    required this.price,
  });

  double get subtotal => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: (json['product_name'] ?? '').toString(),
      quantity: int.tryParse('${json['quantity']}') ?? 0,
      price: double.tryParse('${json['price']}') ?? 0,
    );
  }
}

class OrderModel {
  final int id;
  final double totalPrice;
  final String paymentMethod; // 'bkash' or 'cod'
  final String paymentStatus; // 'Paid' or 'Pending'
  final String? trxId;
  final String? createdAt;
  final List<OrderItem> items;

  const OrderModel({
    required this.id,
    required this.totalPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.items,
    this.trxId,
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? [];
    return OrderModel(
      id: int.tryParse('${json['id']}') ?? 0,
      totalPrice: double.tryParse('${json['total_price']}') ?? 0,
      paymentMethod: (json['payment_method'] ?? '').toString(),
      paymentStatus: (json['payment_status'] ?? '').toString(),
      trxId: json['trx_id']?.toString(),
      createdAt: json['created_at']?.toString(),
      items: rawItems
          .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}