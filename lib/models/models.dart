import 'package:flutter/foundation.dart';


enum UserType { Buyer, Producer }

enum OrderStatus {
  pending, 
  processing, 
  shipping, 
  completed, 
  cancelled, 
}

enum PaymentMethod {
  cash, 
  bankTransfer,
  eWallet, 
  cod, 
}

class UserModel {
  final String id;
  String name;
  String email;
  String phone;
  UserType type;
  String? address;
  String? profileImageUrl;
  DateTime createdAt;
  DateTime? lastLoginAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.type,
    this.address,
    this.profileImageUrl,
    DateTime? createdAt,
    this.lastLoginAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

 
  bool get isBuyer => type == UserType.Buyer;
  bool get isProducer => type == UserType.Producer;
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserType? type,
    String? address,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'type': type.toString(),
      'address': address,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      type: json['type'] == 'UserType.Buyer' ? UserType.Buyer : UserType.Producer,
      address: json['address'],
      profileImageUrl: json['profileImageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt']) : null,
    );
  }
}


// ===========================
// Product Model (DIPERBAIKI)
// ===========================

class Product {
  final String id;
  final String producerId;
  String name;
  String description;
  double price;
  int stock;
  String unit;
  String category;
  String? imageUrl; // <-- DIBUAT NULLABLE (String?)
  double? rating;
  int reviewCount;
  bool isAvailable;
  DateTime createdAt;
  DateTime? updatedAt;
  int minOrder;
  int? maxOrder;
  String? producerName;

  Product({
    required this.id,
    required this.producerId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.unit,
    required this.category,
    this.imageUrl, // <-- TIDAK ADA DEFAULT KOSONG
    this.rating,
    this.reviewCount = 0,
    this.isAvailable = true,
    DateTime? createdAt,
    this.updatedAt,
    this.minOrder = 1,
    this.maxOrder,
    this.producerName,
  }) : this.createdAt = createdAt ?? DateTime.now();

  bool get inStock => stock > 0;
  bool get lowStock => stock > 0 && stock <= 10;
  bool get outOfStock => stock == 0;

  String get stockStatus {
    if (outOfStock) return 'Stok Habis';
    if (lowStock) return 'Stok Terbatas';
    return 'Tersedia';
  }

  // Price formatting
  String get formattedPrice => 'Rp ${price.toStringAsFixed(0)}';
  String get pricePerUnit => '$formattedPrice/$unit';

  // Copy with method
  Product copyWith({
    String? id,
    String? producerId,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? unit,
    String? category,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? minOrder,
    int? maxOrder,
    String? producerName,
  }) {
    return Product(
      id: id ?? this.id,
      producerId: producerId ?? this.producerId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      minOrder: minOrder ?? this.minOrder,
      maxOrder: maxOrder ?? this.maxOrder,
      producerName: producerName ?? this.producerName,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producerId': producerId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'unit': unit,
      'category': category,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'minOrder': minOrder,
      'maxOrder': maxOrder,
      'producerName': producerName,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      producerId: json['producerId'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      stock: json['stock'],
      unit: json['unit'],
      category: json['category'],
      imageUrl: json['imageUrl'] ?? null, // <-- AMAN: null jika tidak ada
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      minOrder: json['minOrder'] ?? 1,
      maxOrder: json['maxOrder'],
      producerName: json['producerName'],
    );
  }
}

// ===========================
// Order Model
// ===========================

class Order {
  final String id;
  final String buyerId;
  final String producerId;
  DateTime createdAt;
  String status; // For backward compatibility
  OrderStatus orderStatus;
  double total;
  List<OrderItem> items;
  String? buyerName;
  String? buyerPhone;
  String? buyerAddress;
  String? producerName;
  String? notes;
  PaymentMethod? paymentMethod;
  DateTime? paidAt;
  DateTime? shippedAt;
  DateTime? completedAt;
  DateTime? cancelledAt;
  String? cancellationReason;

  Order({
    required this.id,
    required this.buyerId,
    required this.producerId,
    required this.createdAt,
    required this.status,
    OrderStatus? orderStatus,
    required this.total,
    required this.items,
    this.buyerName,
    this.buyerPhone,
    this.buyerAddress,
    this.producerName,
    this.notes,
    this.paymentMethod,
    this.paidAt,
    this.shippedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
  }) : this.orderStatus = orderStatus ?? _statusFromString(status);

  // Helper to convert string status to enum
  static OrderStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu konfirmasi':
        return OrderStatus.pending;
      case 'diproses':
        return OrderStatus.processing;
      case 'dikirim':
        return OrderStatus.shipping;
      case 'selesai':
        return OrderStatus.completed;
      case 'dibatalkan':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  // Helper methods
  bool get isPending => orderStatus == OrderStatus.pending;
  bool get isProcessing => orderStatus == OrderStatus.processing;
  bool get isShipping => orderStatus == OrderStatus.shipping;
  bool get isCompleted => orderStatus == OrderStatus.completed;
  bool get isCancelled => orderStatus == OrderStatus.cancelled;

  String get formattedTotal => 'Rp ${total.toStringAsFixed(0)}';
  
  int get totalItems => items.fold(0, (sum, item) => sum + item.qty);

  String get statusDisplay {
    switch (orderStatus) {
      case OrderStatus.pending:
        return 'Menunggu Konfirmasi';
      case OrderStatus.processing:
        return 'Diproses';
      case OrderStatus.shipping:
        return 'Dikirim';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  // Copy with method
  Order copyWith({
    String? id,
    String? buyerId,
    String? producerId,
    DateTime? createdAt,
    String? status,
    OrderStatus? orderStatus,
    double? total,
    List<OrderItem>? items,
    String? buyerName,
    String? buyerPhone,
    String? buyerAddress,
    String? producerName,
    String? notes,
    PaymentMethod? paymentMethod,
    DateTime? paidAt,
    DateTime? shippedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    return Order(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      producerId: producerId ?? this.producerId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      orderStatus: orderStatus ?? this.orderStatus,
      total: total ?? this.total,
      items: items ?? this.items,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      buyerAddress: buyerAddress ?? this.buyerAddress,
      producerName: producerName ?? this.producerName,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      shippedAt: shippedAt ?? this.shippedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyerId': buyerId,
      'producerId': producerId,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'orderStatus': orderStatus.toString(),
      'total': total,
      'items': items.map((item) => item.toJson()).toList(),
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerAddress': buyerAddress,
      'producerName': producerName,
      'notes': notes,
      'paymentMethod': paymentMethod?.toString(),
      'paidAt': paidAt?.toIso8601String(),
      'shippedAt': shippedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      buyerId: json['buyerId'],
      producerId: json['producerId'],
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'],
      total: json['total'].toDouble(),
      items: (json['items'] as List).map((item) => OrderItem.fromJson(item)).toList(),
      buyerName: json['buyerName'],
      buyerPhone: json['buyerPhone'],
      buyerAddress: json['buyerAddress'],
      producerName: json['producerName'],
      notes: json['notes'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      shippedAt: json['shippedAt'] != null ? DateTime.parse(json['shippedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
      cancellationReason: json['cancellationReason'],
    );
  }
}

// ===========================
// Order Item Model
// ===========================

class OrderItem {
  final String productId;
  final String name;
  final int qty;
  final double subtotal;
  double? pricePerUnit;
  String? unit;
  String? imageUrl;
  String? notes;

  OrderItem({
    required this.productId,
    required this.name,
    required this.qty,
    required this.subtotal,
    this.pricePerUnit,
    this.unit,
    this.imageUrl,
    this.notes,
  });

  // Helper methods
  String get formattedSubtotal => 'Rp ${subtotal.toStringAsFixed(0)}';
  String get formattedPricePerUnit => pricePerUnit != null ? 'Rp ${pricePerUnit!.toStringAsFixed(0)}' : '-';

  // Copy with method
  OrderItem copyWith({
    String? productId,
    String? name,
    int? qty,
    double? subtotal,
    double? pricePerUnit,
    String? unit,
    String? imageUrl,
    String? notes,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      subtotal: subtotal ?? this.subtotal,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'qty': qty,
      'subtotal': subtotal,
      'pricePerUnit': pricePerUnit,
      'unit': unit,
      'imageUrl': imageUrl,
      'notes': notes,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'],
      name: json['name'],
      qty: json['qty'],
      subtotal: json['subtotal'].toDouble(),
      pricePerUnit: json['pricePerUnit']?.toDouble(),
      unit: json['unit'],
      imageUrl: json['imageUrl'],
      notes: json['notes'],
    );
  }
}

// ===========================
// Review Model (Bonus)
// ===========================

class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  final List<String>? imageUrls;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.imageUrls,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'imageUrls': imageUrls,
    };
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      productId: json['productId'],
      userId: json['userId'],
      userName: json['userName'],
      rating: json['rating'].toDouble(),
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
      imageUrls: json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : null,
    );
  }
}