import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_logo.dart';
import 'home_tab.dart';
import 'shop_tab.dart';
import 'about_screen.dart';
import 'contact_tab.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<bool>? onToggleTheme;

  const HomeScreen({super.key, this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const HomeTab(),
    const ShopTab(),
    const AboutScreen(),
    const ContactTab(),
    ProfileScreen(onToggleTheme: widget.onToggleTheme),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex != 3
          ? AppBar(
              title: const AppLogo(),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone, size: 16),
                    label: Text(
                      'Call us',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
              ],
            )
          : null,
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        animationDuration: const Duration(milliseconds: 400),
        backgroundColor: Colors.white,
        elevation: 8,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag_rounded),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info_rounded),
            label: 'About',
          ),
          NavigationDestination(
            icon: Icon(Icons.mail_outline),
            selectedIcon: Icon(Icons.mail_rounded),
            label: 'Contact',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
