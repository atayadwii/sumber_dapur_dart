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
  final descriptionController = TextEditingController(text: 'Produk berkualitas premium'); // Default Deskripsi
  final deliveryTimeController = TextEditingController(text: '1-2 hari'); // Input untuk "Pengiriman Cepat"
  
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

  // Helper untuk membuat input field sesuai style
  Widget _buildProductInputField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    // Style input field yang mirip dengan desain detail produk (Rounded, Clean)
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
          filled: true,
          fillColor: Colors.white, // Latar belakang putih
          prefixIcon: Icon(icon, color: AddProductPage.primaryColor), // Ikon hijau
          hintText: labelText,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), // Lebih rounded
            borderSide: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AddProductPage.primaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  // Helper untuk membuat item janji layanan (seperti di detail produk)
  Widget _buildServiceToggle({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AddProductPage.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AddProductPage.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AddProductPage.primaryColor,
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
      description: 
        '${descriptionController.text.trim()}. '
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Input Produk Baru',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ----------------------------------------------------
            // 1. Gambar & Kategori
            // ----------------------------------------------------
            const Text('Foto & Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildProductInputField(
              controller: imageUrlController,
              labelText: 'Link Gambar Produk (Opsional)',
              icon: Icons.image_outlined,
              keyboardType: TextInputType.url,
            ),
            
            // Dropdown Kategori
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Kategori',
                    prefixIcon: Icon(Icons.category, color: AddProductPage.primaryColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  items: const [
                    DropdownMenuItem(value: '1', child: Text('Sayur', style: TextStyle(fontWeight: FontWeight.w500))),
                    DropdownMenuItem(value: '2', child: Text('Daging', style: TextStyle(fontWeight: FontWeight.w500))),
                    DropdownMenuItem(value: '3', child: Text('Ikan', style: TextStyle(fontWeight: FontWeight.w500))),
                    DropdownMenuItem(value: '4', child: Text('Bumbu', style: TextStyle(fontWeight: FontWeight.w500))),
                  ],
                  onChanged: (val) => setState(() => selectedCategoryId = val!),
                ),
              ),
            ),

            // ----------------------------------------------------
            // 2. Detail Produk & Stok
            // ----------------------------------------------------
            const Text('Detail Produk & Harga', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            _buildProductInputField(
              controller: nameController,
              labelText: 'Nama Produk (Contoh: Tomat Segar)',
              icon: Icons.inventory_2,
            ),

            _buildProductInputField(
              controller: descriptionController,
              labelText: 'Deskripsi Produk (Contoh: Kualitas premium)',
              icon: Icons.description,
              maxLines: 3,
            ),
            
            Row(
              children: [
                Expanded(
                  child: _buildProductInputField(
                    controller: priceController,
                    labelText: 'Harga Jual (Rp)',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 100,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedUnit,
                      icon: const Icon(Icons.arrow_drop_down, color: AddProductPage.primaryColor),
                      items: const [
                        DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'liter', child: Text('liter')),
                        DropdownMenuItem(value: 'gram', child: Text('gram')),
                      ],
                      onChanged: (val) => setState(() => selectedUnit = val!),
                    ),
                  ),
                ),
              ],
            ),
            
            // Kotak Stok Tersedia (di-style seperti di detail produk)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                color: AddProductPage.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AddProductPage.primaryColor, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AddProductPage.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProductInputField(
                      controller: stockController,
                      labelText: 'Jumlah Stok Awal',
                      icon: Icons.inventory,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Text(selectedUnit, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // ----------------------------------------------------
            // 3. Janji Layanan (New Section)
            // ----------------------------------------------------
            const Text('Janji Layanan & Pengiriman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // Input Pengiriman Cepat
            _buildProductInputField(
              controller: deliveryTimeController,
              labelText: 'Estimasi Pengiriman (contoh: 1-2 hari)',
              icon: Icons.delivery_dining,
            ),
            
            // Toggle Kualitas Terjamin
            _buildServiceToggle(
              icon: Icons.verified_user,
              title: 'Kualitas Terjamin',
              value: isGuaranteedQuality,
              onChanged: (val) => setState(() => isGuaranteedQuality = val ?? false),
            ),

            // Toggle Layanan 24/7
            _buildServiceToggle(
              icon: Icons.headset_mic,
              title: 'Layanan 24/7 Siap Membantu',
              value: is247Service,
              onChanged: (val) => setState(() => is247Service = val ?? false),
            ),
          ],
        ),
      ),
      // Tombol Simpan Produk
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isSaving ? null : _submitProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: AddProductPage.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Simpan & Terbitkan Produk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}