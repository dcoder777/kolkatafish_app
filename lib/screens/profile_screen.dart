import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/profile_tile.dart';


class ProfileScreen extends StatefulWidget {
  final ValueChanged<bool>? onToggleTheme;

  const ProfileScreen({super.key, this.onToggleTheme});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (mounted) {
      setState(() {
        _darkMode = brightness == Brightness.dark;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF55D2C),
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: const Color(0xFFF55D2C).withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.person,
                      size: 54,
                      color: Color(0xFFF55D2C),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF55D2C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Alex Johnson',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'alex.johnson@email.com',
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem(theme, '24', 'Orders'),
              Container(height: 40, width: 1, color: Colors.grey.shade300),
              _statItem(theme, '12', 'Wishlist'),
              Container(height: 40, width: 1, color: Colors.grey.shade300),
              _statItem(theme, '4.8', 'Rating'),
            ],
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Settings',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ProfileTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            trailing: 'On',
          ),
          ProfileTile(
            icon: Icons.language_outlined,
            title: 'Language',
            trailing: 'English',
          ),
          ProfileTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            trailingWidget: Switch.adaptive(
              value: _darkMode,
              onChanged: (value) {
                setState(() => _darkMode = value);
                widget.onToggleTheme?.call(value);
              },
            ),
          ),
          ProfileTile(
            icon: Icons.location_on_outlined,
            title: 'Currency',
            trailing: 'INR (₹)',
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Account',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ProfileTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () {},
          ),
          ProfileTile(
            icon: Icons.shopping_bag_outlined,
            title: 'My Orders',
            trailing: '8',
            onTap: () {},
          ),
          ProfileTile(
            icon: Icons.favorite_outline,
            title: 'Wishlist',
            trailing: '12',
            onTap: () {},
          ),
          ProfileTile(
            icon: Icons.location_on_outlined,
            title: 'Saved Addresses',
            trailing: '2',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Support',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ProfileTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () {},
          ),
          ProfileTile(
            icon: Icons.info_outline,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          ProfileTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {},
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _statItem(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFF55D2C),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
