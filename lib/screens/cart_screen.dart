import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mock_services.dart'; 
import '../models/models.dart'; 

class CartScreen extends StatefulWidget {
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
  bool _isCheckingOut = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckout(
    BuildContext context,
    CartService cart,
    ProductService ps,
    AuthService auth,
    OrderService orderService,
    Map<String, List<OrderItem>> itemsByProducer,
  ) async {
    if (_isCheckingOut) return;

    setState(() {
      _isCheckingOut = true;
    });

    try {
      // Create orders for each producer
      for (var entry in itemsByProducer.entries) {
        final producerId = entry.key;
        final items = entry.value;

        await orderService.createOrder(
          buyerId: auth.currentUser!.id,
          producerId: producerId,
          items: items,
        );
      }

      // Update stock
      for (var item in cart.items.entries) {
        await ps.updateStock(item.key, -item.value);
      }
      
      cart.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Pesanan berhasil dibuat!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Checkout gagal: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<CartService>(
      builder: (context, cart, child) {
        final ps = context.read<ProductService>();
        final auth = context.read<AuthService>();
        final orderService = context.read<OrderService>();

        if (cart.items.isEmpty) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF667eea), Colors.white],
                  stops: [0.0, 0.3],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context, 0),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Keranjang Kosong',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Yuk, mulai belanja sekarang!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF667eea),
                                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: Icon(Icons.shopping_bag, color: Colors.white),
                              label: Text(
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
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final List<Future<Product>> productFutures = cart.items.keys.map((productId) {
          return ps.findById(productId);
        }).toList();

        return FutureBuilder<List<Product>>(
          future: Future.wait(productFutures),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF667eea), Colors.white],
                      stops: [0.0, 0.3],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        _buildAppBar(context, cart.items.length),
                        Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return Scaffold(
                body: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF667eea), Colors.white],
                      stops: [0.0, 0.3],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        _buildAppBar(context, cart.items.length),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                                SizedBox(height: 16),
                                Text(
                                  'Gagal memuat keranjang',
                                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF667eea), Colors.white],
                    stops: [0.0, 0.3],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildAppBar(context, validProducts.length),
                      SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.all(20),
                                  itemCount: validProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = validProducts[index];
                                    final qty = cart.items[product.id]!;
                                    final subtotal = product.price * qty;
                                    
                                    return FadeTransition(
                                      opacity: _animController,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: Offset(0, 0.2),
                                          end: Offset.zero,
                                        ).animate(CurvedAnimation(
                                          parent: _animController,
                                          curve: Interval(
                                            index * 0.1,
                                            (index * 0.1) + 0.3,
                                            curve: Curves.easeOut,
                                          ),
                                        )),
                                        child: _buildCartItem(product, qty, subtotal, cart),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              _buildBottomSection(total, cart, ps, auth, orderService, itemsByProducer),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, int itemCount) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keranjang Belanja',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (itemCount > 0)
                  Text(
                    '$itemCount Item',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
              ],
            ),
          ),
          if (itemCount > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$itemCount',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Product product, int qty, double subtotal, CartService cart) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image/Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getCategoryIcon(product.category),
                size: 40,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Rp ${product.price.toStringAsFixed(0)}/${product.unit}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Subtotal: Rp ${subtotal.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF667eea),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            // Quantity Controls
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.add, size: 20),
                    color: Color(0xFF667eea),
                    onPressed: () => cart.add(product.id),
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      '$qty',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove, size: 20),
                    color: Colors.red,
                    onPressed: () => cart.remove(product.id),
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(),
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
    AuthService auth,
    OrderService orderService,
    Map<String, List<OrderItem>> itemsByProducer,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary Row
            Row(
              children: [
                Icon(Icons.receipt_long, color: Color(0xFF667eea)),
                SizedBox(width: 12),
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
            SizedBox(height: 16),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Harga:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rp ${total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667eea),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Checkout Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF667eea).withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 6),
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
                            auth,
                            orderService,
                            itemsByProducer,
                          ),
                  child: Center(
                    child: _isCheckingOut
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_bag_outlined, color: Colors.white),
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