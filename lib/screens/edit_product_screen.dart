import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mock_services.dart';
import '../models/models.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  static const Color primaryColor = Color(0xFF1ED760);

  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  late TextEditingController imageUrlController;
  late TextEditingController descriptionController;
  late TextEditingController deliveryTimeController;

  String selectedCategoryId = '1';
  String selectedUnit = 'pcs';
  bool isSaving = false;
  bool isGuaranteedQuality = true;
  bool is247Service = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing product data
    nameController = TextEditingController(text: widget.product.name);
    priceController = TextEditingController(text: widget.product.price.toString());
    stockController = TextEditingController(text: widget.product.stock.toString());
    imageUrlController = TextEditingController(text: widget.product.imageUrl ?? '');
    selectedUnit = widget.product.unit;
    
    // Extract features from description
    _extractProductFeatures();
  }

  void _extractProductFeatures() {
    final fullDesc = widget.product.description;
    String deskripsiAwal = fullDesc;
    String pengiriman = '1-2 hari';

    // Extract delivery time
    final pengirimanMatch = RegExp(r'Pengiriman: (.*?)\.').firstMatch(fullDesc);
    if (pengirimanMatch != null && pengirimanMatch.groupCount >= 1) {
      pengiriman = pengirimanMatch.group(1)!.trim();
      deskripsiAwal = deskripsiAwal.replaceAll(pengirimanMatch.group(0)!, '').trim();
    }

    // Extract quality guarantee
    final kualitasMatch = RegExp(r'Kualitas Terjamin: (.*?)\.').firstMatch(deskripsiAwal);
    if (kualitasMatch != null && kualitasMatch.groupCount >= 1) {
      isGuaranteedQuality = kualitasMatch.group(1)!.trim() == 'Ya';
      deskripsiAwal = deskripsiAwal.replaceAll(kualitasMatch.group(0)!, '').trim();
    }

    // Extract 24/7 service
    final layananMatch = RegExp(r'Layanan 24\/7: (.*?)\.').firstMatch(deskripsiAwal);
    if (layananMatch != null && layananMatch.groupCount >= 1) {
      is247Service = layananMatch.group(1)!.trim() == 'Ya';
      deskripsiAwal = deskripsiAwal.replaceAll(layananMatch.group(0)!, '').trim();
    }

    // Clean up description
    if (deskripsiAwal.endsWith('.')) {
      deskripsiAwal = deskripsiAwal.substring(0, deskripsiAwal.length - 1).trim();
    }
    
    descriptionController = TextEditingController(text: deskripsiAwal.isNotEmpty ? deskripsiAwal : 'Produk berkualitas premium');
    deliveryTimeController = TextEditingController(text: pengiriman);
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    imageUrlController.dispose();
    descriptionController.dispose();
    deliveryTimeController.dispose();
    super.dispose();
  }

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
            color: EditProductScreen.primaryColor,
            size: 22,
          ),
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
              color: EditProductScreen.primaryColor,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

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
            ? EditProductScreen.primaryColor.withOpacity(0.08)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? EditProductScreen.primaryColor.withOpacity(0.3)
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
                  ? EditProductScreen.primaryColor.withOpacity(0.15)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: value ? EditProductScreen.primaryColor : Colors.grey[500],
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
                color: value ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: EditProductScreen.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

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
              color: EditProductScreen.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: EditProductScreen.primaryColor, size: 22),
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

  Future<void> _saveProduct() async {
    final messenger = ScaffoldMessenger.of(context);
    final ps = Provider.of<ProductService>(context, listen: false);

    setState(() => isSaving = true);

    // Validasi input
    if (nameController.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Nama produk tidak boleh kosong.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => isSaving = false);
      return;
    }

    final price = double.tryParse(priceController.text.trim()) ?? 0;
    final stock = int.tryParse(stockController.text.trim()) ?? 0;

    if (price <= 0 || stock < 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Harga harus lebih dari nol dan stok tidak boleh negatif.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => isSaving = false);
      return;
    }

    // Create updated product object
    final updatedProduct = widget.product.copyWith(
      name: nameController.text.trim(),
      description: '${descriptionController.text.trim()}. '
          'Pengiriman: ${deliveryTimeController.text.trim()}. '
          'Kualitas Terjamin: ${isGuaranteedQuality ? 'Ya' : 'Tidak'}. '
          'Layanan 24/7: ${is247Service ? 'Ya' : 'Tidak'}.',
      price: price,
      stock: stock,
      unit: selectedUnit,
      imageUrl: imageUrlController.text.trim().isNotEmpty
          ? imageUrlController.text.trim()
          : null,
    );

    // Call ProductService to update
    bool success = await ps.updateProduct(
      widget.product.id,
      updatedProduct,
      selectedCategoryId,
    );

    setState(() => isSaving = false);

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil diperbarui!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui produk. Coba lagi.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Produk',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Perbarui informasi produk Anda',
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
            // Informasi Dasar Produk
            _buildSectionHeader(
              title: 'Informasi Dasar',
              icon: Icons.inventory_2,
            ),
            _buildSectionCard(
              children: [
                _buildProductInputField(
                  controller: nameController,
                  labelText: 'Nama Produk',
                  icon: Icons.shopping_bag,
                ),
                _buildProductInputField(
                  controller: priceController,
                  labelText: 'Harga',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                _buildProductInputField(
                  controller: stockController,
                  labelText: 'Stok',
                  icon: Icons.inventory,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 4),
                // Unit Dropdown
                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  items: const [
                    DropdownMenuItem(value: 'kg', child: Text('Kilogram (kg)')),
                    DropdownMenuItem(value: 'liter', child: Text('Liter')),
                    DropdownMenuItem(value: 'pcs', child: Text('Pieces (pcs)')),
                    DropdownMenuItem(value: 'box', child: Text('Box')),
                  ],
                  onChanged: (val) => setState(() => selectedUnit = val!),
                  decoration: InputDecoration(
                    labelText: 'Satuan',
                    prefixIcon: const Icon(Icons.straighten, color: EditProductScreen.primaryColor),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ],
            ),

            // Kategori & Media
            _buildSectionHeader(
              title: 'Kategori & Media',
              icon: Icons.category,
            ),
            _buildSectionCard(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  items: const [
                    DropdownMenuItem(value: '1', child: Text('Sayuran')),
                    DropdownMenuItem(value: '2', child: Text('Buah-buahan')),
                    DropdownMenuItem(value: '3', child: Text('Daging')),
                    DropdownMenuItem(value: '4', child: Text('Ikan')),
                    DropdownMenuItem(value: '5', child: Text('Bumbu')),
                  ],
                  onChanged: (val) => setState(() => selectedCategoryId = val!),
                  decoration: InputDecoration(
                    labelText: 'Kategori Produk',
                    prefixIcon: const Icon(Icons.category, color: EditProductScreen.primaryColor),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildProductInputField(
                  controller: imageUrlController,
                  labelText: 'URL Gambar (Opsional)',
                  icon: Icons.image,
                ),
              ],
            ),

            // Deskripsi & Layanan
            _buildSectionHeader(
              title: 'Deskripsi & Layanan',
              icon: Icons.description,
            ),
            _buildSectionCard(
              children: [
                _buildProductInputField(
                  controller: descriptionController,
                  labelText: 'Deskripsi Produk',
                  icon: Icons.notes,
                  maxLines: 3,
                ),
                _buildProductInputField(
                  controller: deliveryTimeController,
                  labelText: 'Waktu Pengiriman',
                  icon: Icons.local_shipping,
                ),
                const SizedBox(height: 8),
                _buildServiceToggle(
                  icon: Icons.verified,
                  title: 'Kualitas Terjamin',
                  value: isGuaranteedQuality,
                  onChanged: (val) => setState(() => isGuaranteedQuality = val!),
                ),
                _buildServiceToggle(
                  icon: Icons.support_agent,
                  title: 'Layanan 24/7',
                  value: is247Service,
                  onChanged: (val) => setState(() => is247Service = val!),
                ),
              ],
            ),

            // Save Button
            Container(
              width: double.infinity,
              height: 54,
              margin: const EdgeInsets.only(top: 8),
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EditProductScreen.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
