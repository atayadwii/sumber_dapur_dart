import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  // 1. Hapus 'const' agar bisa dipakai di main.dart
  SplashScreen({Key? key}) : super(key: key); 
  
  // 2. HAPUS SEMUA initState, dispose, dan _navigate

  @override
  Widget build(BuildContext context) {
    // Warna hijau dari logo Anda
    const Color logoGreen = Color(0xFF1ED760);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Tampilkan Logo
            Image.asset(
              'assets/logo.png',
              width: 140,
            ),
            const SizedBox(height: 24),
            
            // 2. Tampilkan Nama Aplikasi
            const Text(
              'Sumber Dapur',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: logoGreen,
              ),
            ),
            
            // 3. Tambahkan indikator loading
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(logoGreen),
            ),
          ],
        ),
      ),
    );
  }
}