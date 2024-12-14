import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nissy_bakes_app/pages/delivery_page.dart';
import 'package:nissy_bakes_app/pages/home_page.dart';
import 'package:flutter/services.dart';
import 'package:nissy_bakes_app/pages/items_page.dart';
import 'package:nissy_bakes_app/pages/production_page.dart';
import 'package:nissy_bakes_app/pages/splash_screen.dart';

import 'database/dbhelper.dart';
import 'pages/customers_page.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());

  await DbHelper().initDb();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom]);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nissy Bakes',
      theme: ThemeData(primaryColor: const Color.fromRGBO(255, 168, 120, 1)
          ),
      home: const SplashScreen(),
      routes: {
        '/homepage': (context) => const HomePage(),
        '/itemspage': (context) => const ItemsPage(),
        '/productionpage': (context) => const ProductionPage(),
        '/customers' : (context) => const CustomersPage(),
        '/deliverypage': (context) => const DeliveryPage(),
      },
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int currentPage = 0;

  List<Widget> pages = [
    const HomePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentPage],
    );
  }
}
