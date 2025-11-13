import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart'; 

// AuthService (Tidak ada perubahan, sudah benar)
class AuthService extends ChangeNotifier {
  final String _baseUrl = 'http://127.0.0.1:8000/api';
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = true;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    final extractedData = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    final token = extractedData['token'] as String;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        _currentUser = UserModel(
          id: data['id'].toString(),
          name: data['nama'],
          email: data['email'],
          phone: data['noHp'] ?? '',
          type: data['tipeUser'] == 'Producer' ? UserType.Producer : UserType.Buyer,
        );
        _token = token;
      } else {
        prefs.remove('userData');
      }
    } catch (e) {
      print('Auto-login error: $e');
      prefs.remove('userData');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register(String name, String email, String phone, String password, UserType type) async {
    final roleString = type == UserType.Producer ? 'Producer' : 'Buyer';
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'nama': name,
          'email': email,
          'password': password,
          'no_hp': phone,
          'tipe_user': roleString,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['user'];
        _token = data['token'];
        _currentUser = UserModel(
          id: userData['id'].toString(),
          name: userData['nama'],
          email: userData['email'],
          phone: userData['noHp'] ?? '',
          type: userData['tipeUser'] == 'Producer' ? UserType.Producer : UserType.Buyer,
        );
        final prefs = await SharedPreferences.getInstance();
        final prefsData = json.encode({'token': _token, 'userId': _currentUser!.id});
        await prefs.setString('userData', prefsData);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    if (_token == null) return;
    try {
      await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: {'Authorization': 'Bearer $_token', 'Accept': 'application/json'},
      );
    } catch (e) {
      print('Logout API error: $e');
    }
    _currentUser = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');
    notifyListeners();
  }
}

// ==========================================================
// ProductService (PERUBAHAN BESAR)
// ==========================================================
class ProductService extends ChangeNotifier {
  final String _baseUrl = 'http://127.0.0.1:8000/api';
  List<Product> _items = [];
  String? _token;
  bool _isLoggedIn = false;

  // 1. Fungsi baru untuk menerima update dari ProxyProvider
  void updateAuth(AuthService auth) {
    _token = auth.token;
    _isLoggedIn = auth.isLoggedIn;

    // 2. Jika user baru login DAN produk belum di-load, load produknya
    if (_isLoggedIn && _items.isEmpty) {
      getProducts();
    }
    // 3. Jika user logout, bersihkan list produk
    if (!_isLoggedIn) {
      _items = [];
      notifyListeners();
    }
  }

  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/produk'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        _items = data.map((item) {
          return Product(
            id: item['id'].toString(),
            producerId: item['penjual']['id'].toString(),
            name: item['namaProduk'],
            description: item['deskripsi'] ?? 'Deskripsi produk',
            price: item['harga'],
            stock: item['stok'],
            unit: item['satuan'],
            category: item['kategori']?['namaKategori'] ?? 'Lainnya',
            producerName: item['penjual']?['nama'] ?? 'Penjual',
          );
        }).toList();
        
        notifyListeners();
        return _items;
      }
    } catch (e) {
      print('getProducts error: $e');
    }
    return [];
  }

  // 4. Implementasi 'addProduct' yang sebenarnya
  Future<bool> addProduct(Product product, String kategoriId) async {
    if (!_isLoggedIn || _token == null) return false; // Cek login

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/produsen/produk'), // Endpoint khusus produsen
        headers: {
          'Authorization': 'Bearer $_token', // Kirim token
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          // Sesuaikan dengan nama field di Laravel
          'nama_produk': product.name,
          'deskripsi_produk': product.description,
          'harga': product.price,
          'stok': product.stock,
          'satuan': product.unit,
          'kategori_id': kategoriId, // Kirim ID kategori
        }),
      );

      if (response.statusCode == 201) {
        // Jika berhasil, panggil getProducts() untuk refresh list
        getProducts(); 
        return true;
      } else {
        print('addProduct failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('addProduct error: $e');
      return false;
    }
  }

  // Fungsi helper
  List<Product> productsByProducer(String producerId) =>
      _items.where((p) => p.producerId == producerId).toList();

  Future<void> updateStock(String productId, int delta) async {
    // TODO: Panggil API Laravel untuk update stok
    final p = _items.firstWhere((e) => e.id == productId);
    p.stock = (p.stock + delta).clamp(0, 999999);
    notifyListeners();
  }

  Future<Product> findById(String id) async {
    return _items.firstWhere((e) => e.id == id);
  }
}

// CartService (Tidak ada perubahan)
class CartService extends ChangeNotifier {
  final Map<String, int> _cart = {};
  Map<String, int> get items => Map.unmodifiable(_cart);
  void add(String productId) { _cart[productId] = (_cart[productId] ?? 0) + 1; notifyListeners(); }
  void remove(String productId) { if (!_cart.containsKey(productId)) return; final q = _cart[productId]!; if (q <= 1) _cart.remove(productId); else _cart[productId] = q - 1; notifyListeners(); }
  void clear() { _cart.clear(); notifyListeners(); }
}

// ==========================================================
// OrderService (PERUBAHAN BESAR)
// ==========================================================
class OrderService extends ChangeNotifier {
  final String _baseUrl = 'http://127.0.0.1:8000/api';
  List<Order> _orders = [];
  List<Order> get orders => List.unmodifiable(_orders);

  String? _token;
  bool _isLoggedIn = false;

  // 1. Fungsi baru untuk menerima update dari ProxyProvider
  void updateAuth(AuthService auth) {
    _token = auth.token;
    _isLoggedIn = auth.isLoggedIn;

    // 2. Jika user baru login, otomatis fetch pesanannya
    if (_isLoggedIn && _orders.isEmpty) {
      _fetchOrders();
    }
    // 3. Jika user logout, bersihkan list pesanan
    if (!_isLoggedIn) {
      _orders = [];
      notifyListeners();
    }
  }

  // 4. Perbarui 'createOrder' agar otomatis pakai token
  Future<Order> createOrder({
    required String buyerId,
    required String producerId,
    required List<OrderItem> items,
    // 'token' sudah tidak perlu di-pass dari cart_screen
  }) async {
    if (!_isLoggedIn || _token == null) throw Exception('User not logged in');

    final itemsJson = items.map((item) => {
      'produk_id': int.parse(item.productId),
      'jumlah': item.qty,
    }).toList();

    final response = await http.post(
      Uri.parse('$_baseUrl/pesanan'),
      headers: {
        'Authorization': 'Bearer $_token', // <- Otomatis pakai token
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'user_penjual_id': int.parse(producerId),
        'items': itemsJson,
      }),
    );

    if (response.statusCode == 201) {
      _fetchOrders(); // Refresh daftar pesanan
      return Order(id: 'dummy', buyerId: '', producerId: '', createdAt: DateTime.now(), status: 'pending', total: 0, items: []);
    } else {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Gagal membuat pesanan');
    }
  }

  // 5. Fungsi '_fetchOrders' sekarang pakai token internal
  Future<void> _fetchOrders() async {
     if (!_isLoggedIn || _token == null) return;
     try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pesanan'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _orders = data.map((orderData) {
          // TODO: Parse 'detail'
          return Order(
            id: orderData['id'].toString(),
            buyerId: orderData['user_pembeli_id'].toString(),
            producerId: orderData['user_penjual_id'].toString(),
            createdAt: DateTime.parse(orderData['tgl_pesanan']),
            status: orderData['status_pesanan'],
            total: double.parse(orderData['total_harga']),
            items: [], 
          );
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      print('fetchOrders error: $e');
    }
  }

  void updateStatus(String orderId, String status) {
    // TODO: Panggil API Laravel untuk update status
    final o = _orders.firstWhere((e) => e.id == orderId);
    o.status = status;
    notifyListeners();
  }
}