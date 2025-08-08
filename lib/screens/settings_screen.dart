import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _dailyGoal = 2000;
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('일일 목표량'),
            subtitle: Text('$_dailyGoal ml'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: 목표량 설정 다이얼로그
            },
          ),
          SwitchListTile(
            title: const Text('다크 모드'),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
            },
          ),
          ListTile(
            title: const Text('알림 설정'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: 알림 설정 화면
            },
          ),
        ],
      ),
    );
  }
}