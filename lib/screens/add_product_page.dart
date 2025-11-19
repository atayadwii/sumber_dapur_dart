import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mock_services.dart'; // Pastikan path ini benar!
import '../models/models.dart'; // Pastikan path ini benar!

class AddProductPage extends StatefulWidget {
  // Warna primer yang sama dengan ProducerDashboard
  static const Color primaryColor = Color(0xFF1ED760);

  // Rute nama untuk navigasi
  static const String routeName = '/add-product';

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final imageUrlController = TextEditingController();
  final descriptionController = TextEditingController(
      text: 'Produk berkualitas premium'); // Default Deskripsi
  final deliveryTimeController =
      TextEditingController(text: '1-2 hari'); // Input untuk "Pengiriman Cepat"

  String selectedCategoryId = '1';
  String selectedUnit = 'pcs';
  bool isSaving = false;

  // New fields for Service Promises (sesuai permintaan user)
  bool isGuaranteedQuality = true; // Input Kualitas Terjamin
  bool is247Service = true; // Input Layanan 24/7

  @override
  void dispose() {
    // Penting: Bersihkan controller saat widget di-dispose
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    imageUrlController.dispose();
    descriptionController.dispose();
    deliveryTimeController.dispose(); // Dispose controller baru
    super.dispose();
  }

  // Helper untuk membuat input field dengan style modern
  Widget _buildProductInputField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            icon,
            color: AddProductPage.primaryColor,
            size: 22,
          ),
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AddProductPage.primaryColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
        ),
      ),
    );
  }

  // Helper untuk membuat toggle service dengan style modern
  Widget _buildServiceToggle({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: value
            ? AddProductPage.primaryColor.withOpacity(0.08)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? AddProductPage.primaryColor.withOpacity(0.3)
              : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: value
                  ? AddProductPage.primaryColor.withOpacity(0.15)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: value ? AddProductPage.primaryColor : Colors.grey[500],
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AddProductPage.primaryColor,
              inactiveTrackColor: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi yang dipanggil saat tombol Simpan ditekan
  Future<void> _submitProduct() async {
    final messenger = ScaffoldMessenger.of(context);
    final ps = context.read<ProductService>();

    // Validasi sederhana
    if (nameController.text.isEmpty ||
        priceController.text.isEmpty ||
        stockController.text.isEmpty ||
        deliveryTimeController.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Semua field wajib diisi.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Set loading
    setState(() => isSaving = true);

    // Parsing data
    final price = double.tryParse(priceController.text) ?? 0.0;
    final stock = int.tryParse(stockController.text) ?? 0;

    if (price <= 0 || stock <= 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Harga dan Stok harus lebih dari nol.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => isSaving = false);
      return;
    }

    // Buat objek Product
    // CATATAN: Karena kita tidak punya akses ke Model Product, kita hanya bisa
    // mengirim data yang didukung oleh fungsi addProduct. Data janji layanan
    // diasumsikan akan disimpan di bagian Deskripsi atau metadata lain.
    final product = Product(
      id: '',
      producerId: '',
      name: nameController.text.trim(),
      // Kombinasikan deskripsi dengan janji layanan untuk keperluan mock
      description: '${descriptionController.text.trim()}. '
          'Pengiriman: ${deliveryTimeController.text.trim()}. '
          'Kualitas Terjamin: ${isGuaranteedQuality ? 'Ya' : 'Tidak'}. '
          'Layanan 24/7: ${is247Service ? 'Ya' : 'Tidak'}.',
      price: price,
      stock: stock,
      unit: selectedUnit,
      category: '', // Akan diisi di dalam addProduct
      imageUrl: imageUrlController.text.trim().isNotEmpty
          ? imageUrlController.text.trim()
          : null,
    );

    // Panggil ProductService
    bool success = await ps.addProduct(product, selectedCategoryId);

    setState(() => isSaving = false);

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil ditambahkan!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal menambah produk. Coba lagi.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Helper untuk membuat section header yang modern
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AddProductPage.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: AddProductPage.primaryColor, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk membuat section card dengan padding konsisten
  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambah Produk Baru',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Kelola katalog produk Anda dengan mudah',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // =====================================================
            // 1. Foto & Kategori Section
            // =====================================================
            _buildSectionHeader(
              title: 'Foto & Kategori',
              icon: Icons.image_search,
            ),
            _buildSectionCard(
              children: [
                _buildProductInputField(
                  controller: imageUrlController,
                  labelText: 'Link Gambar Produk (Opsional)',
                  icon: Icons.image_outlined,
                  keyboardType: TextInputType.url,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Kategori',
                        labelStyle: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Icon(
                          Icons.category,
                          color: AddProductPage.primaryColor,
                          size: 22,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '1',
                          child: Text(
                            'Sayur',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        DropdownMenuItem(
                          value: '2',
                          child: Text(
                            'Daging',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        DropdownMenuItem(
                          value: '3',
                          child: Text(
                            'Ikan',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        DropdownMenuItem(
                          value: '4',
                          child: Text(
                            'Bumbu',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => selectedCategoryId = val!),
                    ),
                  ),
                ),
              ],
            ),

            // =====================================================
            // 2. Detail Produk Section
            // =====================================================
            _buildSectionHeader(
              title: 'Detail Produk',
              icon: Icons.inventory_2,
            ),
            _buildSectionCard(
              children: [
                _buildProductInputField(
                  controller: nameController,
                  labelText: 'Nama Produk',
                  icon: Icons.inventory_2,
                ),
                _buildProductInputField(
                  controller: descriptionController,
                  labelText: 'Deskripsi Produk',
                  icon: Icons.description,
                  maxLines: 3,
                ),
              ],
            ),

            // =====================================================
            // 3. Harga & Stok Section
            // =====================================================
            _buildSectionHeader(
              title: 'Harga & Stok',
              icon: Icons.local_offer,
            ),
            _buildSectionCard(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildProductInputField(
                        controller: priceController,
                        labelText: 'Harga Jual',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 110,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedUnit,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AddProductPage.primaryColor,
                            size: 24,
                          ),
                          isDense: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'pcs',
                              child: Text(
                                'pcs',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'kg',
                              child: Text(
                                'kg',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'liter',
                              child: Text(
                                'liter',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'gram',
                              child: Text(
                                'gram',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => selectedUnit = val!),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AddProductPage.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AddProductPage.primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  AddProductPage.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.inventory,
                              color: AddProductPage.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Jumlah Stok Awal',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Masukkan jumlah stok',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          suffixText: selectedUnit,
                          suffixStyle: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // =====================================================
            // 4. Pengiriman & Layanan Section
            // =====================================================
            _buildSectionHeader(
              title: 'Pengiriman & Layanan',
              icon: Icons.local_shipping_outlined,
            ),
            _buildSectionCard(
              children: [
                _buildProductInputField(
                  controller: deliveryTimeController,
                  labelText: 'Estimasi Pengiriman',
                  icon: Icons.schedule,
                ),
                _buildServiceToggle(
                  icon: Icons.verified_user,
                  title: 'Kualitas Terjamin',
                  value: isGuaranteedQuality,
                  onChanged: (val) =>
                      setState(() => isGuaranteedQuality = val ?? false),
                ),
                _buildServiceToggle(
                  icon: Icons.support_agent,
                  title: 'Layanan 24/7 Siap Membantu',
                  value: is247Service,
                  onChanged: (val) =>
                      setState(() => is247Service = val ?? false),
                ),
              ],
            ),
          ],
        ),
      ),
      // Tombol Simpan di Bottom
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: isSaving ? null : _submitProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: AddProductPage.primaryColor,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.cloud_upload_outlined, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Simpan & Terbitkan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
