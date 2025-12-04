import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';

// AuthService (Tidak ada perubahan, sudah benar)
class AuthService extends ChangeNotifier {
  final String _baseUrl = 'http://10.0.2.2:8000/api';
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
    final extractedData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
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
          type: data['tipeUser'] == 'Producer'
              ? UserType.Producer
              : UserType.Buyer,
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

  Future<bool> register(String name, String email, String phone,
      String password, UserType type) async {
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
          type: userData['tipeUser'] == 'Producer'
              ? UserType.Producer
              : UserType.Buyer,
        );
        final prefs = await SharedPreferences.getInstance();
        final prefsData =
            json.encode({'token': _token, 'userId': _currentUser!.id});
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
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json'
        },
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
  final String _baseUrl = 'http://10.0.2.2:8000/api';
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
          // Konversi harga ke double dengan aman
          final harga = item['harga'];
          final price = harga is double
              ? harga
              : (harga is int
                  ? harga.toDouble()
                  : double.parse(harga.toString()));

          // Konversi stok ke int dengan aman
          final stok = item['stok'];
          final stock = stok is int ? stok : int.parse(stok.toString());

          return Product(
            id: item['id'].toString(),
            producerId: item['penjual']['id'].toString(),
            name: item['namaProduk'],
            description: item['deskripsi'] ?? 'Deskripsi produk',
            price: price,
            stock: stock,
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

  // Update produk
  Future<bool> updateProduct(String productId, Product product, String kategoriId) async {
    if (!_isLoggedIn || _token == null) return false;

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/produsen/produk/$productId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'nama_produk': product.name,
          'deskripsi_produk': product.description,
          'harga': product.price,
          'stok': product.stock,
          'satuan': product.unit,
          'kategori_id': kategoriId,
        }),
      );

      if (response.statusCode == 200) {
        await getProducts(); // Refresh list
        return true;
      } else {
        print('updateProduct failed: Status ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('updateProduct error: $e');
      return false;
    }
  }

  // Delete produk
  Future<bool> deleteProduct(String productId) async {
    if (!_isLoggedIn || _token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/produsen/produk/$productId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await getProducts(); // Refresh list
        return true;
      } else {
        print('deleteProduct failed: Status ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('deleteProduct error: $e');
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
  void add(String productId) {
    _cart[productId] = (_cart[productId] ?? 0) + 1;
    notifyListeners();
  }

  void remove(String productId) {
    if (!_cart.containsKey(productId)) return;
    final q = _cart[productId]!;
    if (q <= 1)
      _cart.remove(productId);
    else
      _cart[productId] = q - 1;
    notifyListeners();
  }

  void clear() {
    _cart.clear();
    notifyListeners();
  }
}

// ==========================================================
// OrderService (PERUBAHAN BESAR)
// ==========================================================
class OrderService extends ChangeNotifier {
  final String _baseUrl = 'http://10.0.2.2:8000/api';
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

    final itemsJson = items
        .map((item) => {
              'produk_id': int.parse(item.productId),
              'jumlah': item.qty,
            })
        .toList();

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

    print('Create order response: ${response.statusCode} - ${response.body}');
    
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      
      // ✅ WAJIB ambil pesanan_id dari response backend (bukan generate sendiri!)
      final realOrderId = data['pesanan_id'];
      if (realOrderId == null) {
        throw Exception('Backend tidak mengembalikan pesanan_id');
      }
      
      // ✅ Ambil data pesanan lengkap dari field 'pesanan'
      final pesananData = data['pesanan'];
      if (pesananData == null) {
        throw Exception('Backend tidak mengembalikan data pesanan');
      }
      
      print('✅ Pesanan berhasil dibuat dengan ID: $realOrderId');
      
      // Calculate total from items subtotals
      double total = 0;
      for (var item in items) {
        total += item.subtotal;
      }
      
      // ✅ Create order dengan ID dari backend (BUKAN timestamp lokal!)
      final order = Order(
        id: realOrderId.toString(), // ✅ GUNAKAN ID DARI BACKEND
        buyerId: pesananData['user_pembeli_id']?.toString() ?? buyerId,
        producerId: pesananData['user_penjual_id']?.toString() ?? producerId,
        createdAt: pesananData['created_at'] != null 
            ? DateTime.parse(pesananData['created_at'])
            : DateTime.now(),
        status: pesananData['status_pesanan'] ?? 'menunggu_pembayaran',
        total: pesananData['total_harga'] != null 
            ? double.parse(pesananData['total_harga'].toString())
            : total,
        items: items,
        isPaid: false,
      );
      
      print('✅ Order object created: ID=${order.id}, Status=${order.status}');
      
      // Add to local orders list
      _orders.add(order);
      notifyListeners();
      
      return order;
    } else {
      final data = json.decode(response.body);
      final errorMsg = data['message'] ?? 'Gagal membuat pesanan';
      print('❌ Create order failed: $errorMsg');
      throw Exception(errorMsg);
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
      print('Fetch orders response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Fetched ${data.length} orders');
        
        List<Order> parsedOrders = [];
        for (var orderData in data) {
          try {
            // Parse dengan safe null handling
            final order = Order(
              id: orderData['id'].toString(),
              buyerId: orderData['user_pembeli_id']?.toString() ?? '',
              producerId: orderData['user_penjual_id']?.toString() ?? '',
              createdAt: orderData['tgl_pesanan'] != null 
                  ? DateTime.parse(orderData['tgl_pesanan'])
                  : DateTime.now(),
              status: orderData['status_pesanan'] ?? 'menunggu_pembayaran',
              total: orderData['total_harga'] != null 
                  ? double.parse(orderData['total_harga'].toString())
                  : 0.0,
              items: [],
              buktiPembayaran: orderData['bukti_pembayaran'],
              isPaid: orderData['is_paid'] == 1 || orderData['is_paid'] == true,
              rating: orderData['rating']?.toDouble(),
              review: orderData['review'],
            );
            parsedOrders.add(order);
          } catch (e) {
            print('Error parsing order ${orderData['id']}: $e');
            // Skip order yang gagal di-parse
          }
        }
        
        _orders = parsedOrders;
        notifyListeners();
        print('Successfully parsed ${_orders.length} orders');
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

  // Method untuk update status pesanan via API
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    if (!_isLoggedIn || _token == null) throw Exception('User not logged in');

    final statusString = _statusToString(newStatus);
    
    final response = await http.put(
      Uri.parse('$_baseUrl/pesanan/$orderId/status'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'status': statusString,
      }),
    );

    if (response.statusCode == 200) {
      // Update local state
      final orderIndex = _orders.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex] = _orders[orderIndex].copyWith(
          status: statusString,
          orderStatus: newStatus,
        );
        notifyListeners();
      }
    } else {
      throw Exception('Failed to update order status: ${response.body}');
    }
  }

  // Method untuk upload bukti penerimaan dan complete order
  Future<void> completeOrderWithProof(String orderId, XFile imageFile) async {
    if (!_isLoggedIn || _token == null) throw Exception('User not logged in');

    // Create multipart request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/pesanan/$orderId/complete'),
    );

    request.headers['Authorization'] = 'Bearer $_token';
    request.headers['Accept'] = 'application/json';

    // Add image file
    request.files.add(
      await http.MultipartFile.fromPath('bukti_penerimaan', imageFile.path),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      // Update local state to completed
      final orderIndex = _orders.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex] = _orders[orderIndex].copyWith(
          status: 'selesai',
          orderStatus: OrderStatus.selesai,
          completedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } else {
      throw Exception('Failed to complete order: $responseBody');
    }
  }

  // Upload bukti pembayaran (setelah checkout)
  Future<void> uploadPaymentProof(String orderId, XFile imageFile) async {
    if (!_isLoggedIn || _token == null) throw Exception('User not logged in');

    print('🔵 Upload payment proof untuk Order ID: $orderId');
    print('🔵 URL: $_baseUrl/pesanan/$orderId/upload-bukti-pembayaran');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/pesanan/$orderId/upload-bukti-pembayaran'),
    );

    request.headers['Authorization'] = 'Bearer $_token';
    request.headers['Accept'] = 'application/json';

    request.files.add(
      await http.MultipartFile.fromPath('bukti_pembayaran', imageFile.path),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    print('Upload payment proof response ($orderId): ${response.statusCode} - $responseBody');

    if (response.statusCode == 200) {
      print('Upload payment proof SUCCESS for order $orderId');
      
      // Update local state (tanpa re-fetch)
      try {
        final orderIndex = _orders.indexWhere((o) => o.id == orderId);
        if (orderIndex != -1) {
          _orders[orderIndex] = _orders[orderIndex].copyWith(
            status: 'menunggu_konfirmasi',
            orderStatus: OrderStatus.menunggu_konfirmasi,
            buktiPembayaran: 'uploaded', // Mark as uploaded
          );
          print('Updated order $orderId status to menunggu_konfirmasi');
          notifyListeners();
        } else {
          print('Order $orderId not found in local state, will notify anyway');
          notifyListeners();
        }
      } catch (e) {
        print('Error updating local order state: $e');
        notifyListeners();
      }
    } else {
      // Parse error message dari JSON response
      try {
        final errorResponse = json.decode(responseBody);
        final errorMessage = errorResponse['message'] ?? responseBody;
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception(responseBody);
      }
    }
  }

  // Konfirmasi pembayaran oleh penjual (terima/tolak)
  Future<void> confirmPayment(String orderId, bool isAccepted) async {
    if (!_isLoggedIn || _token == null) throw Exception('User not logged in');

    final response = await http.post(
      Uri.parse('$_baseUrl/pesanan/$orderId/konfirmasi-pembayaran'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'is_accepted': isAccepted,
      }),
    );

    print('Confirm payment response ($orderId): ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      print('Confirm payment SUCCESS for order $orderId');
      
      // Update local state terlebih dahulu (tanpa re-fetch untuk menghindari error)
      try {
        final orderIndex = _orders.indexWhere((o) => o.id == orderId);
        if (orderIndex != -1) {
          _orders[orderIndex] = _orders[orderIndex].copyWith(
            status: isAccepted ? 'proses' : 'batal',
            orderStatus: isAccepted ? OrderStatus.proses : OrderStatus.batal,
            isPaid: isAccepted,
          );
          print('Updated order $orderId status to ${isAccepted ? "proses" : "batal"}');
          notifyListeners();
        } else {
          print('Order $orderId not found in local state');
        }
      } catch (e) {
        print('Error updating local order state: $e');
        notifyListeners();
      }
    } else {
      // Parse error message dari JSON response
      try {
        final errorResponse = json.decode(response.body);
        final errorMessage = errorResponse['message'] ?? response.body;
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception(response.body);
      }
    }
  }

  // Submit rating & review dengan foto barang
  Future<void> submitReview(
    String orderId, 
    double rating, 
    String review, 
    List<XFile> images,
  ) async {
    if (!_isLoggedIn || _token == null) throw Exception('User not logged in');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/pesanan/$orderId/selesaikan'),
    );

    request.headers['Authorization'] = 'Bearer $_token';
    request.headers['Accept'] = 'application/json';

    request.fields['rating'] = rating.toString();
    request.fields['review'] = review;

    for (var i = 0; i < images.length; i++) {
      request.files.add(
        await http.MultipartFile.fromPath('review_images[]', images[i].path),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final orderIndex = _orders.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex] = _orders[orderIndex].copyWith(
          status: 'selesai',
          orderStatus: OrderStatus.selesai,
          rating: rating,
          review: review,
          completedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } else {
      throw Exception('Failed to submit review: $responseBody');
    }
  }

  // Helper method to convert OrderStatus to string
  String _statusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.menunggu_pembayaran:
        return 'menunggu_pembayaran';
      case OrderStatus.menunggu_konfirmasi:
        return 'menunggu_konfirmasi';
      case OrderStatus.proses:
        return 'proses';
      case OrderStatus.selesai:
        return 'selesai';
      case OrderStatus.batal:
        return 'batal';
    }
  }
}
