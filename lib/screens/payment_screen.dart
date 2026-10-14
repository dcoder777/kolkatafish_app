import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/store_api_service.dart';
import '../utils/toast_helper.dart';
import 'order_confirmation_screen.dart';

import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  final double total;
  final String customerName;
  final String customerEmail;
  final String phone;
  final String altPhone;
  final String address1;
  final String city;
  final String pincode;
  final String deliveryDate;
  final String deliverySlot;

  const PaymentScreen({
    super.key,
    required this.total,
    required this.customerName,
    this.customerEmail = '',
    required this.phone,
    this.altPhone = '',
    required this.address1,
    required this.city,
    required this.pincode,
    required this.deliveryDate,
    required this.deliverySlot,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPayment = 'cod';
  bool _placing = false;

  String get _paymentLabel {
    switch (_selectedPayment) {
      case 'razorpay':
        return 'Online (UPI / Card / NetBanking)';
      case 'cod':
      default:
        return 'Cash on Delivery';
    }
  }

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
    String redirectUrl = '';
    String? syncError;

    // Build comprehensive customer note containing custom WooCommerce delivery slots
    final noteBuffer = StringBuffer();
    noteBuffer.writeln('Delivery Date: ${widget.deliveryDate}');
    noteBuffer.writeln('Delivery Slot: ${widget.deliverySlot}');
    if (widget.altPhone.isNotEmpty) {
      noteBuffer.writeln('Alternative Phone: ${widget.altPhone}');
    }
    noteBuffer.writeln('Delivery Charge: ₹50');
    noteBuffer.writeln('App Order Total: ₹${widget.total.toStringAsFixed(0)}');

    try {
      final session = await service.createCart();
      for (final item in cart.cartItems) {
        final productId = int.tryParse(item.id);
        if (productId == null) continue;
        await service.addToCart(session, productId);
      }
      final email = widget.customerEmail.isNotEmpty
          ? widget.customerEmail
          : (auth.userEmail.isNotEmpty
              ? auth.userEmail
              : 'customer${widget.phone}@kolkatafish.app');
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
        paymentMethod: _selectedPayment,
        customerNote: noteBuffer.toString(),
      );
      serverId = result.orderId;
      orderKey = result.orderKey;
      status = result.status.isEmpty ? 'processing' : result.status;
      redirectUrl = result.redirectUrl;
    } catch (e) {
      syncError = e is StoreApiException ? e.message : 'Could not reach the store';
    } finally {
      service.dispose();
    }

    if (!mounted) return;

    // For Razorpay online payment: if server sync failed or order could not be created on WooCommerce,
    // DO NOT pretend order succeeded. Show error toast so user can retry or choose COD.
    if (_selectedPayment == 'razorpay' && serverId == null) {
      showErrorToast(
        context,
        syncError != null
            ? 'Store checkout error: $syncError'
            : 'Could not connect to payment gateway. Please try again.',
      );
      return;
    }

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

    // If online payment (Razorpay) returned a payment/checkout redirect URL, launch it immediately
    if (redirectUrl.isNotEmpty) {
      final uri = Uri.tryParse(redirectUrl);
      if (uri != null) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }
    }

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
            _sectionHeader('Delivery Details'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on, color: Color(0xFFF55D2C)),
                      title: Text(widget.customerName,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${widget.address1}, ${widget.city} - ${widget.pincode}\nPh: ${widget.phone}${widget.altPhone.isNotEmpty ? ' | Alt: ${widget.altPhone}' : ''}',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 18, color: Color(0xFFF55D2C)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Slot: ${widget.deliveryDate} (${widget.deliverySlot})',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _sectionHeader('Choose Payment Method'),
            _paymentOption(
              'cod',
              'Cash on Delivery',
              'Pay with CASH upon delivery. We encourage cashless Transactions.',
              Icons.money,
              Colors.green,
            ),
            _paymentOption(
              'razorpay',
              'UPI / Cards / NetBanking (Razorpay)',
              'Pay securely via UPI (GPay, PhonePe, Paytm), Cards or NetBanking.',
              Icons.credit_card,
              const Color(0xFF3395FF),
            ),
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
                    Text(
                      _selectedPayment == 'razorpay' ? 'Proceed to Pay' : 'Place Order',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? const Color(0xFFF55D2C) : Colors.transparent,
          width: 1.5,
        ),
      ),
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
