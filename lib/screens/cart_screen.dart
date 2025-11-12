import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mock_services.dart';
import '../models/models.dart';

class CartScreen extends StatefulWidget {
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  // Definisikan warna primer
  static const Color primaryColor = Color(0xFF1ED760);

  bool _isCheckingOut = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ===================================================================
  // FUNGSI INI TELAH DIPERBAIKI
  // ===================================================================
  Future<void> _handleCheckout(
    BuildContext context,
    CartService cart,
    ProductService ps,
    AuthService auth, // AuthService sudah di-pass ke sini
    OrderService orderService,
    Map<String, List<OrderItem>> itemsByProducer,
  ) async {
    if (_isCheckingOut) return;

    // 1. Validasi token (tetap penting)
    if (!auth.isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi Anda telah habis. Silakan login ulang.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Simpan context SEBELUM await
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isCheckingOut = true;
    });

    try {
      // Create orders for each producer
      for (var entry in itemsByProducer.entries) {
        final producerId = entry.key;
        final items = entry.value;

        // 2. PANGGIL createOrder TANPA TOKEN
        //    (OrderService sudah punya token dari ProxyProvider)
        await orderService.createOrder(
          buyerId: auth.currentUser!.id,
          producerId: producerId,
          items: items,
          // token: token, <-- BARIS INI DIHAPUS
        );
      }

      // Update stock (Ini harusnya juga memanggil API, tapi kita biarkan dulu)
      for (var item in cart.items.entries) {
        await ps.updateStock(item.key, -item.value);
      }

      cart.clear();

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Pesanan berhasil dibuat!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Checkout gagal: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
        });
      }
    }
  }
  // ===================================================================
  // AKHIR DARI FUNGSI YANG DIPERBAUI
  // ===================================================================

  @override
  Widget build(BuildContext context) {
    return Consumer<CartService>(
      builder: (context, cart, child) {
        final ps = context.read<ProductService>();
        // Kita butuh 'auth' di sini untuk di-pass ke _handleCheckout
        final auth = context.read<AuthService>();
        final orderService = context.read<OrderService>();

        if (cart.items.isEmpty) {
          return Scaffold(
            // Ganti background
            backgroundColor: Colors.white,
            appBar: _buildAppBar(context, 0),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      // Ganti warna background
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Keranjang Kosong',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yuk, mulai belanja sekarang!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      // Ganti warna tombol
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.shopping_bag, color: Colors.white),
                    label: const Text(
                      'Mulai Belanja',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final List<Future<Product>> productFutures =
            cart.items.keys.map((productId) {
          return ps.findById(productId);
        }).toList();

        return FutureBuilder<List<Product>>(
          future: Future.wait(productFutures),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: Colors.white,
                appBar: _buildAppBar(context, cart.items.length),
                body: const Center(
                  child: CircularProgressIndicator(
                    // Ganti warna loading
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return Scaffold(
                backgroundColor: Colors.white,
                appBar: _buildAppBar(context, cart.items.length),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 80, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memuat keranjang',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }

            final products = snapshot.data!;
            double total = 0;
            final Map<String, List<OrderItem>> itemsByProducer = {};
            final List<Product> validProducts = [];

            for (final product in products) {
              if (!cart.items.containsKey(product.id)) continue;

              final qty = cart.items[product.id]!;
              final subtotal = product.price * qty;
              total += subtotal;
              validProducts.add(product);

              final orderItem = OrderItem(
                productId: product.id,
                name: product.name,
                qty: qty,
                subtotal: subtotal,
              );

              if (!itemsByProducer.containsKey(product.producerId)) {
                itemsByProducer[product.producerId] = [];
              }
              itemsByProducer[product.producerId]!.add(orderItem);
            }

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: _buildAppBar(context, validProducts.length),
              body: Container(
                // Ganti warna background body
                color: Colors.grey[50],
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: validProducts.length,
                        itemBuilder: (context, index) {
                          final product = validProducts[index];
                          final qty = cart.items[product.id]!;
                          final subtotal = product.price * qty;

                          return FadeTransition(
                            opacity: _animController,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.2),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _animController,
                                curve: Interval(
                                  index * 0.1,
                                  (index * 0.1) + 0.3,
                                  curve: Curves.easeOut,
                                ),
                              )),
                              child:
                                  _buildCartItem(product, qty, subtotal, cart),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildBottomSection(
                        total, cart, ps, auth, orderService, itemsByProducer),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, int itemCount) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Keranjang',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      actions: [
        if (itemCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$itemCount',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCartItem(
      Product product, int qty, double subtotal, CartService cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image/Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                // Ganti warna background
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getCategoryIcon(product.category),
                size: 40,
                // Ganti warna ikon
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${product.price.toStringAsFixed(0)}/${product.unit}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subtotal: Rp ${subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      // Ganti warna subtotal
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Quantity Controls
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    // Ganti warna ikon
                    color: primaryColor,
                    onPressed: () => cart.add(product.id),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      '$qty',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    color: Colors.red,
                    onPressed: () => cart.remove(product.id),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(
    double total,
    CartService cart,
    ProductService ps,
    AuthService auth, // auth sudah di-pass ke sini
    OrderService orderService,
    Map<String, List<OrderItem>> itemsByProducer,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary Row
            Row(
              children: [
                // Ganti warna ikon
                const Icon(Icons.receipt_long, color: primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Ringkasan Belanja',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Item:',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${cart.items.values.fold<int>(0, (sum, qty) => sum + qty)} Item',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Harga:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rp ${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    // Ganti warna total
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Checkout Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                // Ganti gradien ke warna solid
                color: primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    // Ganti warna shadow
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isCheckingOut
                      ? null
                      : () => _handleCheckout(
                            context,
                            cart,
                            ps,
                            auth, // Pastikan auth di-pass
                            orderService,
                            itemsByProducer,
                          ),
                  child: Center(
                    child: _isCheckingOut
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.shopping_bag_outlined,
                                  color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Checkout Sekarang',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sayur':
      case 'sayuran':
        return Icons.eco;
      case 'daging':
        return Icons.set_meal;
      case 'ikan':
        return Icons.phishing;
      case 'bumbu':
        return Icons.grain;
      case 'susu':
        return Icons.local_drink;
      default:
        return Icons.shopping_basket;
    }
  }
}