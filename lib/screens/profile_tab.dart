import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../services/store_api_service.dart';
import '../utils/toast_helper.dart';
import 'contact_tab.dart';
import 'forgot_password_screen.dart';
import 'order_details_screen.dart';
import 'policy_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return _buildLoggedOut(context);
    return _buildLoggedIn(context);
  }

  void _doLogout(BuildContext context) {
    context.read<AuthProvider>().logout();
  }

  void _showLoginDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(Icons.set_meal, color: Color(0xFFF55D2C)),
              const SizedBox(width: 8),
              Text('Login', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter your KolkataFish WooCommerce email and password.',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: GoogleFonts.poppins(color: Colors.red.shade800, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final typedEmail = emailCtrl.text.trim();
                            Navigator.pop(ctx);
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ForgotPasswordScreen(initialEmail: typedEmail),
                              ),
                            );
                            if (updated == true && context.mounted) {
                              _showLoginDialog(context);
                            }
                          },
                    child: Text('Forgot Password?',
                        style: GoogleFonts.poppins(color: const Color(0xFFF55D2C), fontSize: 12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final email = emailCtrl.text.trim();
                        final pass = passCtrl.text;
                        if (email.isEmpty || !email.contains('@')) {
                          setDialogState(() => errorMessage = 'Please enter a valid email address');
                          return;
                        }
                        if (pass.isEmpty) {
                          setDialogState(() => errorMessage = 'Please enter your password');
                          return;
                        }

                        setDialogState(() {
                          isLoading = true;
                          errorMessage = null;
                        });

                        final auth = context.read<AuthProvider>();
                        final result = await auth.loginWithCredentials(
                          email: email,
                          password: pass,
                        );

                        if (!dialogCtx.mounted) return;

                        if (result.success) {
                          Navigator.pop(ctx);
                          showSuccessToast(context, 'Logged in as ${auth.userName}');
                        } else {
                          setDialogState(() {
                            isLoading = false;
                            errorMessage = result.message;
                          });
                          showErrorToast(context, result.message);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF55D2C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Login', style: GoogleFonts.poppins()),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRegisterDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
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
                  Text(
                    'Create a real account on kolkatafish.com.',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Full Name', prefixIcon: const Icon(Icons.person_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl, keyboardType: TextInputType.phone,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Phone Number', prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl, obscureText: true,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Password (min 8 characters)',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtrl, obscureText: true,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password', prefixIcon: const Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: GoogleFonts.poppins(color: Colors.red.shade800, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        if (name.isEmpty) {
                          setDialogState(() => errorMessage = 'Please enter your full name');
                          return;
                        }
                        if (email.isEmpty || !email.contains('@')) {
                          setDialogState(() => errorMessage = 'Please enter a valid email');
                          return;
                        }
                        if (phone.isEmpty) {
                          setDialogState(() => errorMessage = 'Please enter your phone number');
                          return;
                        }
                        if (passCtrl.text.length < 8) {
                          setDialogState(() => errorMessage = 'Password must be at least 8 characters');
                          return;
                        }
                        if (passCtrl.text != confirmCtrl.text) {
                          setDialogState(() => errorMessage = 'Passwords do not match');
                          return;
                        }

                        setDialogState(() {
                          isLoading = true;
                          errorMessage = null;
                        });

                        final auth = context.read<AuthProvider>();
                        final result = await auth.register(
                          name: name,
                          email: email,
                          phone: phone,
                          password: passCtrl.text,
                        );

                        if (!dialogCtx.mounted) return;

                        if (result.success) {
                          Navigator.pop(ctx);
                          showSuccessToast(context, 'Welcome, ${auth.userName}! Account created.');
                        } else {
                          setDialogState(() {
                            isLoading = false;
                            errorMessage = result.message;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF55D2C), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Register', style: GoogleFonts.poppins()),
              ),
            ],
          );
        },
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
                            child: const Icon(Icons.set_meal, color: Color(0xFFF55D2C)),
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

  void _showEditProfileDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final nameCtrl = TextEditingController(text: auth.userName);
    final phoneCtrl = TextEditingController(text: auth.userPhone);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.edit_outlined, color: Color(0xFFF55D2C)),
            const SizedBox(width: 8),
            Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: 'Full Name', prefixIcon: const Icon(Icons.person_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl, keyboardType: TextInputType.phone,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: 'Phone Number', prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        showErrorToast(context, 'Name cannot be empty');
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      final result = await auth.updateProfileOnServer(
                        name: name,
                        phone: phoneCtrl.text.trim(),
                      );
                      if (!dialogCtx.mounted) return;
                      Navigator.pop(ctx);
                      if (result.success) {
                        showSuccessToast(context, 'Profile updated');
                      } else {
                        showErrorToast(context, result.message);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF55D2C), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Save', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  /// Pull the live status for every order the store can identify
  /// (needs serverId + orderKey + billingEmail).
  Future<void> _refreshOrderStatuses(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final service = StoreApiService();
    final updatable = cart.orders
        .where((o) =>
            o.serverId != null && o.orderKey.isNotEmpty && o.billingEmail.isNotEmpty)
        .toList();

    if (updatable.isEmpty) {
      showInfoToast(context, 'No orders can be refreshed from the store yet.');
      return;
    }

    int updated = 0;
    for (final order in updatable) {
      try {
        final status = await service.fetchOrderStatus(
          orderId: order.serverId!,
          orderKey: order.orderKey,
          billingEmail: order.billingEmail,
        );
        if (status.status.isNotEmpty && status.status != order.status) {
          cart.updateOrderStatus(order.id, status: status.status);
          updated++;
        }
      } catch (_) {
        // Keep going; other orders may still refresh.
      }
    }

    if (!context.mounted) return;
    if (updated > 0) {
      showSuccessToast(context, '$updated order${updated == 1 ? '' : 's'} updated');
    } else {
      showInfoToast(context, 'All orders are already up to date.');
    }
  }

  void _showOrdersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final orders = context.watch<CartProvider>().orders;
        return SizedBox(
          height: 420,
          child: orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No orders yet',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Orders you place will appear here',
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                )
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('My Orders (${orders.length})',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _refreshOrderStatuses(context),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: orders.length,
                        itemBuilder: (_, i) {
                          final order = orders[i];
                          final awaiting = order.isAwaitingPayment;
                          final failed = order.status == 'failed' ||
                              order.status == 'cancelled' ||
                              order.status == 'refunded';
                          return ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => OrderDetailsScreen(order: order)));
                            },
                            leading: Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: awaiting || failed || !order.synced
                                    ? Colors.orange.shade50
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                  awaiting
                                      ? Icons.hourglass_top_outlined
                                      : failed
                                          ? Icons.error_outline
                                          : order.synced
                                              ? Icons.check_circle_outline
                                              : Icons.cloud_off_outlined,
                                  color: awaiting || failed || !order.synced
                                      ? Colors.orange.shade800
                                      : Colors.green.shade600),
                            ),
                            title: Text(order.displayId,
                                style: GoogleFonts.poppins(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${order.payment} • ${order.placedAt.day}/${order.placedAt.month}/${order.placedAt.year}'
                                '${awaiting ? ' • awaiting payment' : ''}'
                                '${order.synced || awaiting ? '' : ' • not synced'}',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey.shade600)),
                            trailing: Text('₹${order.total.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFF55D2C))),
                          );
                        },
                      ),
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
    final cart = context.watch<CartProvider>();
    final displayName = auth.userName.isNotEmpty ? auth.userName : 'My Account';
    final displayEmail = auth.userEmail.isNotEmpty ? auth.userEmail : (auth.userPhone.isNotEmpty ? auth.userPhone : '—');

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
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 5),
              Text(displayEmail,
                  style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
        ),
        if (auth.userPhone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 5),
                Text(auth.userPhone,
                    style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statItem('${cart.orderCount}', 'Orders'),
            Container(height: 40, width: 1, color: Colors.grey.shade300),
            _statItem('${cart.wishlistCount}', 'Wishlist'),
            Container(height: 40, width: 1, color: Colors.grey.shade300),
            _statItem('${cart.cartCount}', 'In Cart'),
          ],
        ),
        const SizedBox(height: 32),
        _sectionTitle('Account'),
        const SizedBox(height: 12),
        _tile(Icons.person_outline, 'Edit Profile',
            onTap: () => _showEditProfileDialog(context)),
        _tile(Icons.favorite_outline, 'Wishlist', trailing: '${cart.wishlistCount}',
            onTap: () => _showWishlistSheet(context)),
        _tile(Icons.shopping_bag_outlined, 'My Orders', trailing: '${cart.orderCount}',
            onTap: () => _showOrdersSheet(context)),
        const SizedBox(height: 16),
        _sectionTitle('Support'),
        const SizedBox(height: 12),
        _tile(Icons.help_outline, 'Help Center',
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ContactTab()))),
        _tile(Icons.info_outline, 'Privacy Policy',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PolicyScreen(
                        title: 'Privacy Policy',
                        sections: PolicyScreen.privacySections)))),
        _tile(Icons.description_outlined, 'Terms of Service',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PolicyScreen(
                        title: 'Terms of Service',
                        sections: PolicyScreen.termsSections)))),
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
