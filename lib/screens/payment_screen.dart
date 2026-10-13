import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/store_api_service.dart';
import '../utils/toast_helper.dart';
import 'order_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double total;
  final String customerName;
  final String phone;
  final String address1;
  final String city;
  final String pincode;

  const PaymentScreen({
    super.key,
    required this.total,
    required this.customerName,
    required this.phone,
    required this.address1,
    required this.city,
    required this.pincode,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPayment = 'cod';
  bool _placing = false;

  String get _paymentLabel =>
      _selectedPayment == 'cod' ? 'Cash on Delivery' : _selectedPayment.toUpperCase();

  Future<void> _placeOrder() async {
    if (_placing) return;
    setState(() => _placing = true);

    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final service = StoreApiService();
    final items = cart.cartItems
        .map((p) => PlacedOrderLine(name: p.name, price: p.price, weight: p.weight))
        .toList();
    final address = '${widget.address1}, ${widget.city} - ${widget.pincode}';

    int? serverId;
    String orderKey = '';
    String status = 'processing';
    String? syncError;

    try {
      final session = await service.createCart();
      for (final item in cart.cartItems) {
        final productId = int.tryParse(item.id);
        if (productId == null) continue;
        await service.addToCart(session, productId);
      }
      final email = auth.userEmail.isNotEmpty
          ? auth.userEmail
          : 'customer${widget.phone}@kolkatafish.app';
      final result = await service.checkout(
        session: session,
        firstName: widget.customerName.split(' ').first,
        lastName: widget.customerName.split(' ').length > 1
            ? widget.customerName.split(' ').sublist(1).join(' ')
            : 'Customer',
        address1: widget.address1,
        city: widget.city,
        state: 'WB',
        postcode: widget.pincode,
        country: 'IN',
        email: email,
        phone: widget.phone,
        paymentMethod: 'cod',
        customerNote:
            'Order placed from KolkataFish app. Delivery charge ₹50 is collected separately in the app total.',
      );
      serverId = result.orderId;
      orderKey = result.orderKey;
      status = result.status.isEmpty ? 'processing' : result.status;
    } catch (e) {
      syncError = e is StoreApiException ? e.message : 'Could not reach the store';
    } finally {
      service.dispose();
    }

    if (!mounted) return;

    final order = cart.recordOrder(
      total: widget.total,
      payment: _paymentLabel,
      serverId: serverId,
      orderKey: orderKey,
      status: status,
      synced: serverId != null,
      customerName: widget.customerName,
      phone: widget.phone,
      address: address,
      items: items,
    );
    cart.clearCart();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(
          total: widget.total,
          payment: _paymentLabel,
          orderId: order.displayId,
          synced: serverId != null,
          syncError: syncError,
        ),
      ),
      (route) => route.isFirst,
    );
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
                title: Text(widget.customerName,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${widget.address1}, ${widget.city} - ${widget.pincode}\nPh: ${widget.phone}',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                isThreeLine: true,
              ),
            ),
            const SizedBox(height: 20),
            _sectionHeader('Choose Payment Method'),
            _paymentOption('cod', 'Cash on Delivery', 'Pay when you receive', Icons.money, Colors.green),
            _paymentOption('upi', 'UPI', 'Coming soon — Google Pay, PhonePe, Paytm', Icons.qr_code, Colors.purple),
            _paymentOption('card', 'Credit / Debit Card', 'Coming soon — Visa, MasterCard, RuPay', Icons.credit_card, Colors.blue),
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
          onPressed: _placing ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF55D2C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _placing
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(
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
    final comingSoon = value != 'cod';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: selected ? color : Colors.grey.shade100,
          child: Icon(icon, color: selected ? Colors.white : color, size: 22),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
        trailing: comingSoon
            ? null
            : Radio<String>(
                value: value,
                groupValue: _selectedPayment,
                onChanged: (v) => setState(() => _selectedPayment = v!),
                activeColor: const Color(0xFFF55D2C),
              ),
        onTap: comingSoon
            ? () => showInfoToast(context, '$title will be available soon')
            : () => setState(() => _selectedPayment = value),
      ),
    );
  }
}
