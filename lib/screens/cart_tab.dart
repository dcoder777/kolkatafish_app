import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/toast_helper.dart';
import 'product_detail_screen.dart';
import 'checkout_screen.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.cartCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Your cart is empty', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Browse our fresh products and add items to your cart',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: cart.cartItems.length,
            itemBuilder: (context, index) {
              final item = cart.cartItems[index];
              final colors = [
                Colors.blue.shade200, Colors.orange.shade200,
                Colors.green.shade200, Colors.pink.shade200, Colors.teal.shade200,
              ];
              final color = colors[item.id.hashCode.abs() % colors.length];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.set_meal, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  title: Text(item.name,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.weight, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                      Text(item.formattedPrice,
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold,
                              color: const Color(0xFFF55D2C))),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => cart.removeFromCart(item),
                  ),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: item))),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${cart.cartCount} items', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                        Text('Total: ₹${cart.cartTotal.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => cart.clearCart(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Clear', style: GoogleFonts.poppins()),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _proceedToCheckout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF55D2C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Proceed to Checkout',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _proceedToCheckout(BuildContext context) {
  final auth = context.read<AuthProvider>();
  if (auth.isLoggedIn) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const CheckoutScreen()));
  } else {
    _showAuthRequiredDialog(context);
  }
}

void _showAuthRequiredDialog(BuildContext context) {
  final auth = context.read<AuthProvider>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLoginTab = true;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (_, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  Icon(Icons.lock_outlined, size: 48, color: const Color(0xFFF55D2C)),
                  const SizedBox(height: 8),
                  Text(
                    isLoginTab ? 'Login to Continue' : 'Create an Account',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoginTab
                        ? 'Login to place your order and track deliveries'
                        : 'Register to enjoy faster checkout',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (!isLoginTab)
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  if (!isLoginTab) const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = isLoginTab ? 'Alex Johnson' : nameCtrl.text;
                        final email = emailCtrl.text;
                        auth.login(name, email);
                        Navigator.pop(ctx);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF55D2C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        isLoginTab ? 'Login' : 'Register',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setSheetState(() => isLoginTab = !isLoginTab),
                    child: Text(
                      isLoginTab
                          ? "Don't have an account? Register"
                          : 'Already have an account? Login',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 4),
                  Text(
                    '— or —',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showGuestCheckoutDialog(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFF55D2C)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline, size: 18, color: const Color(0xFFF55D2C)),
                          const SizedBox(width: 8),
                          Text('Continue as Guest',
                              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFF55D2C))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Quick checkout — no password needed',
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void _showGuestCheckoutDialog(BuildContext context) {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Icon(Icons.person_outline, color: const Color(0xFFF55D2C)),
        const SizedBox(width: 8),
        Text('Guest Checkout', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enter your details to place the order.\nWe\'ll use these for delivery and tracking.',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              prefixIcon: const Icon(Icons.person_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
            if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
              showWarningToast(ctx, 'Please fill all fields');
              return;
            }
            context.read<AuthProvider>().loginAsGuest(nameCtrl.text, phoneCtrl.text);
            Navigator.pop(ctx);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CheckoutScreen()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF55D2C),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Continue', style: GoogleFonts.poppins()),
        ),
      ],
    ),
  );
}

