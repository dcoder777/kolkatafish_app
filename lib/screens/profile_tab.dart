import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/toast_helper.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return _buildLoggedOut(context);
    return _buildLoggedIn(context);
  }

  void _doLogin(BuildContext context, String name, String email) {
    context.read<AuthProvider>().login(name, email);
  }

  void _doLogout(BuildContext context) {
    context.read<AuthProvider>().logout();
  }

  void _showLoginDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.set_meal, color: Color(0xFFF55D2C)),
          const SizedBox(width: 8),
          Text('Login', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(
                labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl, obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password', prefixIcon: const Icon(Icons.lock_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showForgotPasswordDialog(context);
                },
                child: Text('Forgot Password?',
                    style: GoogleFonts.poppins(color: const Color(0xFFF55D2C), fontSize: 12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _doLogin(context, 'Alex Johnson', emailCtrl.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF55D2C), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Login', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.lock_reset, color: Color(0xFFF55D2C)),
          const SizedBox(width: 8),
          Text('Reset Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email and we\'ll send you a reset link.',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(
                labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              showSuccessToast(context, 'Password reset link sent to ${emailCtrl.text}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF55D2C), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Send Link', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showRegisterDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.person_add, color: Color(0xFFF55D2C)),
          const SizedBox(width: 8),
          Text('Register', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name', prefixIcon: const Icon(Icons.person_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl, keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number', prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl, obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password', prefixIcon: const Icon(Icons.lock_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl, obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password', prefixIcon: const Icon(Icons.lock_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _doLogin(context, nameCtrl.text, emailCtrl.text);
              showSuccessToast(context, 'Welcome, ${nameCtrl.text}! Account created.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF55D2C), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Register', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showWishlistSheet(BuildContext context) {
    final cart = context.read<CartProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final wishlist = context.watch<CartProvider>().wishlistItems;
        return SizedBox(
          height: 400,
          child: wishlist.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No items in wishlist',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('My Wishlist (${wishlist.length} items)',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: wishlist.length,
                      itemBuilder: (_, i) {
                        final item = wishlist[i];
                        return ListTile(
                          leading: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.set_meal, color: const Color(0xFFF55D2C)),
                          ),
                          title: Text(item.name,
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text(item.formattedPrice,
                              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFF55D2C))),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => cart.toggleWishlist(item),
                          ),
                        );
                      },
                    ),
                  ),
                ]),
        );
      },
    );
  }

  Widget _buildLoggedOut(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF55D2C).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, size: 64, color: Color(0xFFF55D2C)),
            ),
            const SizedBox(height: 24),
            Text('Welcome to KolkataFish',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Login to view your account, orders, and wishlist',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLoginDialog(context),
                icon: const Icon(Icons.login),
                label: Text('Login',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF55D2C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _showRegisterDialog(context),
              child: Text("Don't have an account? Register",
                  style: GoogleFonts.poppins(color: const Color(0xFFF55D2C))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedIn(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayName = auth.userName.isNotEmpty ? auth.userName : 'Alex Johnson';
    final displayEmail = auth.userEmail.isNotEmpty ? auth.userEmail : 'alex.johnson@email.com';

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 20),
        Center(
          child: Stack(children: [
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
              bottom: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFFF55D2C), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Center(child: Text(displayName,
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold))),
        const SizedBox(height: 4),
        Center(child: Text(displayEmail,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14))),
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
        _tile(Icons.location_on_outlined, 'Currency', trailing: 'INR (₹)'),
        const SizedBox(height: 16),
        _sectionTitle('Account'),
        const SizedBox(height: 12),
        _tile(Icons.person_outline, 'Edit Profile'),
        _tile(Icons.favorite_outline, 'Wishlist', trailing: '12',
            onTap: () => _showWishlistSheet(context)),
        _tile(Icons.shopping_bag_outlined, 'My Orders', trailing: '8'),
        const SizedBox(height: 16),
        _sectionTitle('Support'),
        const SizedBox(height: 12),
        _tile(Icons.help_outline, 'Help Center'),
        _tile(Icons.info_outline, 'Privacy Policy'),
        _tile(Icons.description_outlined, 'Terms of Service'),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: OutlinedButton.icon(
            onPressed: () => _doLogout(context),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: Text('Logout',
                style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _statItem(String value, String label) {
    return Column(children: [
      Text(value,
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFFF55D2C))),
      Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
    ]);
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _tile(IconData icon, String title,
      {String? trailing, Widget? trailingWidget, VoidCallback? onTap}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
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
