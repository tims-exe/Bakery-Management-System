import 'package:flutter/material.dart';

class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Coming Soon !!'),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/homepage');
              },
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
