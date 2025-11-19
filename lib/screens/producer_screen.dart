import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mock_services.dart';
import '../models/models.dart';
import 'add_product_page.dart';

class ProducerDashboard extends StatefulWidget {
  @override
  _ProducerDashboardState createState() => _ProducerDashboardState();
}

class _ProducerDashboardState extends State<ProducerDashboard>
    with SingleTickerProviderStateMixin {
  // Definisikan warna primer
  static const Color primaryColor = Color(0xFF1ED760);

  int _selectedIndex = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer untuk keamanan saat logout
    return Consumer<AuthService>(builder: (context, auth, child) {
      if (auth.currentUser == null) {
        return const Scaffold(
            body: Center(
                child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        )));
      }

      return Scaffold(
        backgroundColor: Colors.white, // Latar belakang utama putih
        body: _selectedIndex == 0
            ? _buildDashboardContent(auth)
            : _selectedIndex == 1
                ? _buildProductsContent(auth)
                : _buildProfileContent(auth),
        bottomNavigationBar: _buildBottomNav(),
        floatingActionButton: _selectedIndex == 1 ? _buildAddProductFAB() : null,
      );
    });
  }

  // ===========================================================================
  // Section 1: Dashboard
  // ===========================================================================

  Widget _buildDashboardContent(AuthService auth) {
    // Panggil 'watch' di sini agar UI update saat list produk/order berubah
    final ps = context.watch<ProductService>();
    final orderService = context.watch<OrderService>();
    
    final myProducts = ps.productsByProducer(auth.currentUser!.id);
    final myOrders = orderService.orders
        .where((o) => o.producerId == auth.currentUser!.id)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[50], // Latar belakang abu-abu
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(auth), // Header di-pindah ke sini
              const SizedBox(height: 24),
              const Text(
                'Statistik Bisnis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatsCards(myProducts, myOrders),
              const SizedBox(height: 24),
              const Text(
                'Pesanan Terbaru',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildRecentOrders(myOrders),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthService auth) {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                auth.currentUser?.name.substring(0, 1).toUpperCase() ?? 'P',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: primaryColor, // Diubah ke hijau
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang! 👋',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600], // Diubah ke abu-abu
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.currentUser?.name ?? 'Produsen',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Diubah ke hitam
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(List<Product> products, List<Order> orders) {
    final totalProducts = products.length;
    final totalStock = products.fold<int>(0, (sum, p) => sum + p.stock);
    final totalRevenue = orders.fold<double>(0, (sum, o) => sum + o.total);
    final pendingOrders =
        orders.where((o) => o.status == 'Menunggu Konfirmasi').length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          icon: Icons.inventory_2,
          title: 'Total Produk',
          value: totalProducts.toString(),
        ),
        _buildStatCard(
          icon: Icons.trending_up,
          title: 'Total Stok',
          value: totalStock.toString(),
        ),
        _buildStatCard(
          icon: Icons.attach_money,
          title: 'Pendapatan',
          value: 'Rp ${(totalRevenue / 1000).toStringAsFixed(0)}K',
        ),
        _buildStatCard(
          icon: Icons.pending_actions,
          title: 'Pending',
          value: pendingOrders.toString(),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    // Style kartu diubah jadi putih
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1), // Background ikon hijau
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 24), // Ikon hijau
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(List<Order> orders) {
    if (orders.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 50, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                'Belum ada pesanan',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: orders.take(3).map((order) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1), // Ikon hijau
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_bag, color: primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.id.length > 8 ? order.id.substring(0, 8) : order.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: primaryColor, // Harga hijau
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    color: _getStatusColor(order.status),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // Section 2: Produk
  // ===========================================================================

  Widget _buildProductsContent(AuthService auth) {
    // Gunakan 'watch' agar UI di-update saat produk baru ditambahkan
    final ps = context.watch<ProductService>();
    final myProducts = ps.productsByProducer(auth.currentUser!.id);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Produk Saya',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${myProducts.length} Item',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: myProducts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada produk',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap tombol + untuk menambah produk',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: myProducts.length,
                itemBuilder: (context, index) {
                  final product = myProducts[index];
                  return _buildProductCard(product, ps);
                },
              ),
      ),
    );
  }

  Widget _buildProductCard(Product product, ProductService ps) {
    // Tentukan apakah ada gambar yang valid
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    Widget imageWidget;
    if (hasImage) {
      // Gunakan Image.network jika URL tersedia
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          product.imageUrl!,
          height: 70,
          width: 70,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildIconPlaceholder(product.category, size: 35), // Fallback jika gagal load
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(primaryColor)));
          },
        ),
      );
    } else {
      // Placeholder ikon jika tidak ada URL
      imageWidget = _buildIconPlaceholder(product.category, size: 35);
    }
    
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
            // Gambar Produk (Diperbarui)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[100], // Latar belakang gambar abu-abu
                borderRadius: BorderRadius.circular(16),
              ),
              child: imageWidget,
            ),
            const SizedBox(width: 16),
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stok: ${product.stock} ${product.unit}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: primaryColor, // Harga hijau
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () async {
                    // Gunakan context yang aman
                    final messenger = ScaffoldMessenger.of(context);
                    await ps.updateStock(product.id, 5);
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Stok ditambah 5'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () async {
                    // Gunakan context yang aman
                    final messenger = ScaffoldMessenger.of(context);
                    await ps.updateStock(product.id, -5);
                    if (mounted) {
                      // Fix: SnackBarBehavior.floating
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Stok dikurangi 5'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget baru untuk Placeholder Ikon
  Widget _buildIconPlaceholder(String category, {double size = 50}) {
    return Center(
      child: Icon(
        _getCategoryIcon(category),
        size: size,
        color: primaryColor,
      ),
    );
  }

  // ===========================================================================
  // Section 3: Profil
  // ===========================================================================

  Widget _buildProfileContent(AuthService auth) {
    final user = auth.currentUser;
    if (user == null) {
      return const Center(
          child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
      ));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor, // Ikon hijau
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildProfileMenuItem(
                    icon: Icons.person,
                    title: 'Edit Profil',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildProfileMenuItem(
                    icon: Icons.store,
                    title: 'Info Toko',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildProfileMenuItem(
                    icon: Icons.settings,
                    title: 'Pengaturan',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _buildProfileMenuItem(
                    icon: Icons.help_outline,
                    title: 'Bantuan',
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Perbaikan bug logout (anti-crash)
                      Provider.of<AuthService>(context, listen: false).logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.logout, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Keluar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1), // Ikon hijau
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // ===========================================================================
  // Section 4: FAB & Dialog (PERBAIKAN DISPOSE)
  // ===========================================================================

  Widget _buildAddProductFAB() {
  return FloatingActionButton.extended(
    onPressed: () {
      // Ganti dari _showAddProductDialog(ps) menjadi navigasi ke halaman baru
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddProductPage(),
        ),
      );
    },
    backgroundColor: primaryColor,
    icon: const Icon(Icons.add),
    label: const Text(
      'Tambah Produk',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
  );
}

  // Helper untuk text field di dialog (style baru)
  Widget _buildTextFieldDialog({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey[700]),
        filled: true,
        fillColor: Colors.grey[100],
        prefixIcon: Icon(icon, color: Colors.grey[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
    );
  }
    Widget _buildBottomNav() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Produk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      );
    }
  
    // Map product category names to icons
    IconData _getCategoryIcon(String category) {
      final key = category.toLowerCase();
      if (key.contains('sayur') || key.contains('vegetable')) {
        return Icons.eco;
      } else if (key.contains('daging') || key.contains('meat')) {
        return Icons.set_meal;
      } else if (key.contains('ikan') || key.contains('fish')) {
        return Icons.phishing;
      } else if (key.contains('bumbu') || key.contains('spice')) {
        return Icons.grain;
      } else if (key.contains('susu') || key.contains('milk')) {
        return Icons.local_drink;
      }
      return Icons.shopping_bag;
    }
  
    // Return a color for an order status (used in recent orders UI)
    Color _getStatusColor(String status) {
      final s = status.toLowerCase();
      if (s.contains('menunggu') || s.contains('pending')) {
        return Colors.orange;
      } else if (s.contains('proses') || s.contains('processing')) {
        return Colors.blue;
      } else if (s.contains('selesai') || s.contains('completed')) {
        return Colors.green;
      } else if (s.contains('batal') || s.contains('cancel')) {
        return Colors.red;
      }
        return Colors.grey;
      }
  
    }