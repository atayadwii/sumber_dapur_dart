import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/mock_services.dart'; // Sesuaikan path jika perlu
import '../../models/models.dart'; // Pastikan ini mengimpor enum UserType

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller disesuaikan dengan field baru
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _roleController = TextEditingController(); // Untuk menampilkan role

  UserType? _selectedRole; // Mengganti _sel, dibuat nullable
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  // Fungsi untuk menampilkan modal pilih role
  void _showRoleSheet() {
    // Role yang dipilih sementara di dalam modal
    UserType? tempRole = _selectedRole;
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // StatefulBuilder diperlukan agar Radio button di dalam modal bisa di-update
        return StatefulBuilder(
          builder: (modalContext, modalSetState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle (garis abu-abu)
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Select Role',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Opsi Penjual (Producer)
                  _buildRoleOption(
                    title: 'Penjual',
                    value: UserType.Producer,
                    groupValue: tempRole,
                    onChanged: (val) {
                      modalSetState(() => tempRole = val);
                    },
                  ),
                  SizedBox(height: 10),
                  
                  // Opsi Pembeli (Buyer)
                  _buildRoleOption(
                    title: 'Pembeli',
                    value: UserType.Buyer, // Menggunakan UserType.Buyer dari kode lama Anda
                    groupValue: tempRole,
                    onChanged: (val) {
                      modalSetState(() => tempRole = val);
                    },
                  ),
                  SizedBox(height: 24),
                  
                  // Tombol Select
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        // Update state di halaman utama
                        setState(() {
                          _selectedRole = tempRole;
                          if (_selectedRole == UserType.Producer) {
                            _roleController.text = 'Penjual';
                          } else if (_selectedRole == UserType.Buyer) {
                            _roleController.text = 'Pembeli';
                          }
                        });
                        Navigator.pop(ctx); // Tutup modal
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1ED760), // Warna hijau baru
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Select',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper untuk opsi di modal
  Widget _buildRoleOption({
    required String title,
    required UserType value,
    required UserType? groupValue,
    required void Function(UserType?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        trailing: Radio<UserType>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: Color(0xFF1ED760),
        ),
        onTap: () => onChanged(value),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create account',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                
                // --- Form ---
                _buildTextField(
                  controller: _nameController,
                  hintText: 'Name',
                ),
                SizedBox(height: 20),
                
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),
                
                // Field "Select Role"
                _buildTextField(
                  controller: _roleController,
                  hintText: 'Select Role',
                  readOnly: true, // Tidak bisa diketik
                  onTap: _showRoleSheet, // Panggil modal
                  suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                ),
                SizedBox(height: 20),
                
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                SizedBox(height: 20),
                
                _buildTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm password',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                SizedBox(height: 40),

                // Tombol Create Account
                _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1ED760)),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        // ======================================================
                        // BLOK INI TELAH DIPERBAIKI (onPressed)
                        // ======================================================
                        onPressed: () async {
                          // --- Logika Registrasi ---
                          
                          // 1. Validasi field teks
                          if (_nameController.text.isEmpty ||
                              _emailController.text.isEmpty ||
                              _passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Nama, email, dan password harus diisi'),
                              backgroundColor: Colors.red,
                            ));
                            return;
                          }
                          
                          // 2. Validasi role
                          if (_selectedRole == null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Silakan pilih role Anda (Penjual/Pembeli)'),
                              backgroundColor: Colors.red,
                            ));
                            return; // Berhenti di sini jika role belum dipilih
                          }
                          
                          // 3. Validasi password
                          if (_passwordController.text != _confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Password tidak cocok'),
                              backgroundColor: Colors.red,
                            ));
                            return;
                          }
                          
                          // --- Jika semua validasi lolos ---
                          setState(() => _loading = true);
                          
                          // Panggil fungsi register dengan 5 argumen
                          bool success = await auth.register(
                            _nameController.text.trim(),     // 1. name
                            _emailController.text.trim(),    // 2. email
                            "",                              // 3. phone (placeholder)
                            _passwordController.text,        // 4. password
                            _selectedRole!,                  // 5. role
                          );
                          
                          setState(() => _loading = false);
                          
                          if (success && mounted) {
                            // Kembali ke login jika berhasil
                            Navigator.pop(context); 
                          } else {
                            // Tampilkan error jika gagal
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Registrasi gagal. Coba lagi.'),
                              backgroundColor: Colors.red,
                            ));
                          }
                        },
                        // ======================================================
                        // AKHIR DARI BLOK YANG DIPERBAIKI
                        // ======================================================
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1ED760),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Create account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                
                SizedBox(height: 30),

                // Link Sign In
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 15,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Kembali ke halaman login
                        Navigator.pop(context); 
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Sign in',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget untuk TextField (gaya baru)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.grey[100],
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}