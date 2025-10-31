import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/mock_services.dart';
import 'models/models.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart'; // Import HomeScreen
import 'screens/producer_screen.dart';

void main() {
  runApp(SumberDapurApp());
}

class SumberDapurApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ProductService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
      ],
      child: MaterialApp(
        title: 'Sumber Dapur',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'SF Pro', // Optional: untuk font lebih modern
        ),
        home: RootRouter(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class RootRouter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    if (auth.currentUser == null) {
      return LoginScreen();
    } else {
      // Route based on user type
      if (auth.currentUser!.type == UserType.Producer) {
        return ProducerDashboard();
      } else {
        return HomeScreen(); // ✅ Ganti dari CartScreen ke HomeScreen
      }
    }
  }
}