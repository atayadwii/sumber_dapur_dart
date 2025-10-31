import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart'; 

final _uuid = Uuid();

// ==========================================================
// AuthService (Sudah Benar)
// ==========================================================
class AuthService extends ChangeNotifier {
  UserModel? currentUser;

  Future<bool> register(String name, String email, String phone, String password, UserType type) async {
    await Future.delayed(Duration(milliseconds: 100));
    currentUser = UserModel(id: _uuid.v4(), name: name, email: email, phone: phone, type: type);
    notifyListeners();
    return true;
  }

  Future<bool> login(String email, String password) async {
    await Future.delayed(Duration(milliseconds: 100));
    final isProducer = email.contains('prod');
    currentUser = UserModel(id: _uuid.v4(), name: isProducer ? 'Produsen Demo' : 'Pembeli Demo', email: email, phone: '081234', type: isProducer ? UserType.Producer : UserType.Buyer);
    notifyListeners();
    return true;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }
}

// ==========================================================
// ProductService (INI YANG DIPERBARUI)
// ==========================================================
class ProductService extends ChangeNotifier {
  final List<Product> _items = [
    Product(id: 'p1', producerId: 'u1', name: 'Cabai Merah', description: 'Segar dari petani', price: 20000, stock: 50, unit: 'kg', category: 'Sayur'),
    Product(id: 'p2', producerId: 'u2', name: 'Ikan Kembung', description: 'Tangkap pagi ini', price: 30000, stock: 30, unit: 'kg', category: 'Ikan'),
  ];

  // --- PERBAIKAN DI SINI ---
  // HAPUS 'get items' yang lama
  // List<Product> get items => List.unmodifiable(_items); // <-- INI DIHAPUS

  // TAMBAHKAN 'getProducts' yang baru
  Future<List<Product>> getProducts() async {
    // Simulasi pengambilan data dari jaringan
    await Future.delayed(Duration(milliseconds: 300));
    return List.unmodifiable(_items);
  }
  // --- SELESAI ---

  List<Product> productsByProducer(String producerId) => _items.where((p) => p.producerId == producerId).toList();

  void addProduct(Product p) {
    _items.add(p);
    notifyListeners();
  }

  Future<void> updateStock(String productId, int delta) async {
    await Future.delayed(Duration(milliseconds: 50)); 
    final p = _items.firstWhere((e) => e.id == productId);
    p.stock = (p.stock + delta).clamp(0, 999999);
    notifyListeners();
  }

  Future<Product> findById(String id) async {
    await Future.delayed(Duration(milliseconds: 50)); 
    return _items.firstWhere((e) => e.id == id);
  }
}

// ==========================================================
// CartService (Sudah Benar)
// ==========================================================
class CartService extends ChangeNotifier {
  final Map<String, int> _cart = {}; 

  Map<String, int> get items => Map.unmodifiable(_cart);

  void add(String productId) {
    _cart[productId] = (_cart[productId] ?? 0) + 1;
    notifyListeners();
  }

  void remove(String productId) {
    if (!_cart.containsKey(productId)) return;
    final q = _cart[productId]!;
    if (q <= 1) _cart.remove(productId);
    else _cart[productId] = q - 1;
    notifyListeners();
  }

  void clear() {
    _cart.clear();
    notifyListeners();
  }
}

// ==========================================================
// OrderService (Sudah Benar)
// ==========================================================
class OrderService extends ChangeNotifier {
  final List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders);

  Future<Order> createOrder({required String buyerId, required String producerId, required List<OrderItem> items}) async {
    await Future.delayed(Duration(milliseconds: 100));
    
    final total = items.fold<double>(0, (s, i) => s + i.subtotal);
    final order = Order(id: _uuid.v4(), buyerId: buyerId, producerId: producerId, createdAt: DateTime.now(), status: 'Menunggu Konfirmasi', total: total, items: items);
    _orders.add(order);
    notifyListeners();
    return order;
  }

  void updateStatus(String orderId, String status) {
    final o = _orders.firstWhere((e) => e.id == orderId);
    o.status = status;
    notifyListeners();
  }
}