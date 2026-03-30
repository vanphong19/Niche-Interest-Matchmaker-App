import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Niche Interest Matchmaker')),
      body: const Center(
        child: Text('Khung sườn đã sẵn sàng!\nBạn có thể code tính năng mới ở thư mục features/'),
      ),
    );
  }
}
