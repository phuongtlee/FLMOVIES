import 'package:flutter/material.dart';
import 'package:movie_app/screens/account_screen.dart';
import 'package:movie_app/screens/home_screen.dart';
import 'package:movie_app/screens/search_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  _BottomNavState createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int currentPageIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    SearchScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.transparent,
        backgroundColor: Colors.white10,
        selectedIndex: currentPageIndex,
        destinations: <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home, color: Colors.blue.shade200),
            icon: Icon(Icons.home_outlined),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.search_outlined, color: Colors.blue.shade200),
            icon: Icon(Icons.search),
            label: 'Tìm kiếm',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.account_circle, color: Colors.blue.shade200),
            icon: Icon(Icons.account_circle_outlined),
            label: 'Tài khoản',
          ),
        ],
      ),
      body: SafeArea(
        child: _pages[currentPageIndex],
      ),
    );
  }
}
