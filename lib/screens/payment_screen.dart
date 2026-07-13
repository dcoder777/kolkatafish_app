import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'order_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double total;
  final String address;

  const PaymentScreen({super.key, required this.total, required this.address});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPayment = 'cod';

  void _placeOrder() {
    final cart = context.read<CartProvider>();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(
          total: widget.total,
          payment: _selectedPayment == 'cod' ? 'Cash on Delivery' : _selectedPayment.toUpperCase(),
        ),
      ),
      (route) => route.isFirst,
    );
    cart.clearCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Delivery To'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Color(0xFFF55D2C)),
                title: Text(widget.address, style: GoogleFonts.poppins(fontSize: 14)),
                subtitle: Text('Ph: 9830083112', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 20),
            _sectionHeader('Choose Payment Method'),
            _paymentOption('cod', 'Cash on Delivery', 'Pay when you receive', Icons.money, Colors.green),
            _paymentOption('upi', 'UPI', 'Google Pay, PhonePe, Paytm', Icons.qr_code, Colors.purple),
            _paymentOption('card', 'Credit / Debit Card', 'Visa, MasterCard, RuPay', Icons.credit_card, Colors.blue),
            if (_selectedPayment == 'card') ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Card Number',
                        prefixIcon: const Icon(Icons.credit_card),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'MM/YY',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'CVV',
                              prefixIcon: const Icon(Icons.lock),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            obscureText: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: ElevatedButton(
          onPressed: _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF55D2C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Place Order',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('₹${widget.total.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _paymentOption(String value, String title, String subtitle, IconData icon, Color color) {
    final selected = _selectedPayment == value;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: selected ? color : Colors.grey.shade100,
          child: Icon(icon, color: selected ? Colors.white : color, size: 22),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
        trailing: Radio<String>(
          value: value,
          groupValue: _selectedPayment,
          onChanged: (v) => setState(() => _selectedPayment = v!),
          activeColor: const Color(0xFFF55D2C),
        ),
        onTap: () => setState(() => _selectedPayment = value),
      ),
    );
  }
}
