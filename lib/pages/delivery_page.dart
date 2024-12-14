import 'package:flutter/material.dart';
import 'package:nissy_bakes_app/components/coming_soon.dart';

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  @override
  Widget build(BuildContext context) {
    return const ComingSoon();
  }
}