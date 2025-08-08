import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '오늘: 1500 / 2000 ml',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              '이번 주 평균: 1800 ml',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              '이번 달 평균: 1750 ml',
              style: TextStyle(fontSize: 18),
            ),
            // TODO: 차트 추가
          ],
        ),
      ),
    );
  }
}