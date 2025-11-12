import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/mock_services.dart';
import 'models/models.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart'; 
import 'screens/producer_screen.dart';
import 'screens/splash_screen.dart'; 

void main() {
  runApp(SumberDapurApp());
}

class SumberDapurApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. AuthService tetap jadi yang utama
        ChangeNotifierProvider(create: (_) => AuthService()),
        
        // 2. ProductService sekarang "mendengarkan" AuthService
        ChangeNotifierProxyProvider<AuthService, ProductService>(
          create: (_) => ProductService(),
          update: (_, auth, previousProductService) {
            // Inject token dan status login ke ProductService
            previousProductService?.updateAuth(auth); 
            return previousProductService!;
          },
        ),
        
        ChangeNotifierProvider(create: (_) => CartService()),

        // 3. OrderService sekarang "mendengarkan" AuthService
        ChangeNotifierProxyProvider<AuthService, OrderService>(
          create: (_) => OrderService(),
          update: (_, auth, previousOrderService) {
            // Inject token dan status login ke OrderService
            previousOrderService?.updateAuth(auth); 
            return previousOrderService!;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Sumber Dapur',
        theme: ThemeData(
          primarySwatch: Colors.green, // Ganti ke green
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'SF Pro',
          scaffoldBackgroundColor: Colors.white, 
        ),
        debugShowCheckedModeBanner: false,
        
        home: Consumer<AuthService>(
          builder: (context, auth, _) {
            // Logika ini sudah benar:
            // Tampilkan SplashScreen selama mengecek auto-login
            if (auth.isLoading) {
              return SplashScreen();
            }
            // Setelah selesai, tampilkan RootRouter
            return RootRouter();
          },
        ),
      ),
    );
  }
}

// RootRouter (Consumer) sudah benar, tidak perlu diubah
class RootRouter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, child) {
        
        print('--- RootRouter Rebuild ---');
        print('User saat ini: ${auth.currentUser?.name}');

        if (auth.currentUser == null) {
          print('Hasil: Menampilkan LoginScreen');
          return LoginScreen();
        } else {
          if (auth.currentUser!.type == UserType.Producer) {
            print('Hasil: Menampilkan ProducerDashboard');
            return ProducerDashboard();
          } else {
            print('Hasil: Menampilkan HomeScreen');
            return HomeScreen();
          }
        }
      },
    );
  }
}