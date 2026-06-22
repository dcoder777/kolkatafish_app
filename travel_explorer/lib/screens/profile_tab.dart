import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileTab extends StatefulWidget {
  final ValueChanged<bool>? onToggleTheme;

  const ProfileTab({super.key, this.onToggleTheme});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
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
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 20),
        Center(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF55D2C), width: 3),
                ),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: const Color(0xFFF55D2C).withValues(alpha: 0.1),
                  child: const Icon(Icons.person, size: 54, color: Color(0xFFF55D2C)),
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
                  child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Alex Johnson',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'alex.johnson@email.com',
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statItem('24', 'Orders'),
            Container(height: 40, width: 1, color: Colors.grey.shade300),
            _statItem('12', 'Wishlist'),
            Container(height: 40, width: 1, color: Colors.grey.shade300),
            _statItem('4.8', 'Rating'),
          ],
        ),
        const SizedBox(height: 32),
        _sectionTitle('Settings'),
        const SizedBox(height: 12),
        _tile(Icons.notifications_outlined, 'Notifications', trailing: 'On'),
        _tile(Icons.language_outlined, 'Language', trailing: 'English'),
        _tile(Icons.dark_mode_outlined, 'Dark Mode',
            trailingWidget: Switch.adaptive(
              value: _darkMode,
              onChanged: (value) {
                setState(() => _darkMode = value);
                widget.onToggleTheme?.call(value);
              },
            )),
        _tile(Icons.location_on_outlined, 'Currency', trailing: 'INR (₹)'),
        const SizedBox(height: 16),
        _sectionTitle('Account'),
        const SizedBox(height: 12),
        _tile(Icons.person_outline, 'Edit Profile'),
        _tile(Icons.shopping_bag_outlined, 'My Orders', trailing: '8'),
        _tile(Icons.favorite_outline, 'Wishlist', trailing: '12'),
        _tile(Icons.location_on_outlined, 'Saved Addresses', trailing: '2'),
        const SizedBox(height: 16),
        _sectionTitle('Support'),
        const SizedBox(height: 12),
        _tile(Icons.help_outline, 'Help Center'),
        _tile(Icons.info_outline, 'Privacy Policy'),
        _tile(Icons.description_outlined, 'Terms of Service'),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _statItem(String value, String label) {
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
        Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _tile(IconData icon, String title, {String? trailing, Widget? trailingWidget}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF55D2C).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFF55D2C), size: 22),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        trailing: trailingWidget ??
            (trailing != null
                ? Text(trailing, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey))
                : const Icon(Icons.chevron_right, color: Colors.grey)),
      ),
    );
  }
}
