import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final double total;
  final String payment;

  const OrderConfirmationScreen({
    super.key,
    required this.total,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = 'KF${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final now = DateTime.now();
    final delivery = now.add(const Duration(hours: 2));

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Confirmed', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, size: 80, color: Color(0xFF4CAF50)),
              ),
              const SizedBox(height: 24),
              Text('Thank You!',
                  style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Your order has been placed successfully.',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _row('Order ID', orderId),
                      const SizedBox(height: 10),
                      _row('Total', '₹${total.toStringAsFixed(0)}'),
                      const SizedBox(height: 10),
                      _row('Payment', payment),
                      const SizedBox(height: 10),
                      _row('Order Date',
                          '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}'),
                      const SizedBox(height: 10),
                      _row('Est. Delivery',
                          '${delivery.hour}:${delivery.minute.toString().padLeft(2, '0')} Today'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<AuthProvider>(
                builder: (_, auth, __) => auth.isGuest
                    ? Card(
                        color: Colors.orange.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(Icons.person_add, size: 32, color: const Color(0xFFF55D2C)),
                              const SizedBox(height: 8),
                              Text('Save your order history!',
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Create an account to track all your orders.',
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFF55D2C)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text('Create Account',
                                    style: GoogleFonts.poppins(
                                        color: const Color(0xFFF55D2C), fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF55D2C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Back to Home', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
        Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
