import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameCtrl = TextEditingController(text: 'Alex Johnson');
  final _phoneCtrl = TextEditingController(text: '+91 9830083112');
  final _addressCtrl = TextEditingController(text: '86, Thakurpukur Road');
  final _cityCtrl = TextEditingController(text: 'Kolkata');
  final _pincodeCtrl = TextEditingController(text: '700063');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final deliveryFee = 50.0;
    final total = cart.cartTotal + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Delivery Address'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _input('Full Name', _nameCtrl, Icons.person_outlined),
                  const SizedBox(height: 10),
                  _input('Phone Number', _phoneCtrl, Icons.phone_outlined, type: TextInputType.phone),
                  const SizedBox(height: 10),
                  _input('Address', _addressCtrl, Icons.home_outlined, maxLines: 2),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _input('City', _cityCtrl, Icons.location_city_outlined)),
                      const SizedBox(width: 10),
                      Expanded(child: _input('Pincode', _pincodeCtrl, Icons.pin_outlined, type: TextInputType.number)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionHeader('Order Summary'),
            ...cart.cartItems.map((item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item.name,
                        style: GoogleFonts.poppins(fontSize: 13)),
                  ),
                  Text('${item.weight} × ${item.formattedPrice}',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            )),
            const SizedBox(height: 8),
            Divider(indent: 16, endIndent: 16, color: Colors.grey.shade300),
            _priceRow('Subtotal', '₹${cart.cartTotal.toStringAsFixed(0)}'),
            _priceRow('Delivery', '₹$deliveryFee'),
            Divider(indent: 16, endIndent: 16, color: Colors.grey.shade300),
            _priceRow('Total', '₹${total.toStringAsFixed(0)}', bold: true),
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
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => PaymentScreen(
                total: total,
                address: '${_addressCtrl.text}, ${_cityCtrl.text} - ${_pincodeCtrl.text}',
              ),
            ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF55D2C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('₹${total.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('Continue to Payment',
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

  Widget _input(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? type, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(fontSize: 14,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          Text(value,
              style: GoogleFonts.poppins(fontSize: 14,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: bold ? const Color(0xFFF55D2C) : null)),
        ],
      ),
    );
  }
}
