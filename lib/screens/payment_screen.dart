import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/store_api_service.dart';
import '../utils/toast_helper.dart';
import 'order_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
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

  final StoreApiService _service = StoreApiService();
  StoreCartSession? _session;
  StoreCartTotals? _totals;
  bool _preparing = true;
  String? _prepareError;

  @override
  void initState() {
    super.initState();
    _prepareCart();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  String get _billingEmail {
    if (widget.customerEmail.trim().isNotEmpty) {
      return widget.customerEmail.trim();
    }
    return context.read<AuthProvider>().userEmail.trim();
  }

  (String, String) get _nameParts {
    final parts = widget.customerName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return ('Customer', 'Guest');
    return (
      parts.first,
      parts.length > 1 ? parts.sublist(1).join(' ') : 'Customer',
    );
  }

  /// Build the real server-side cart for this address so the totals shown to
  /// the customer are exactly what WooCommerce will charge (items + handling
  /// fee + shipping zone rate).
  Future<void> _prepareCart() async {
    setState(() {
      _preparing = true;
      _prepareError = null;
    });

    final cart = context.read<CartProvider>();

    // Never post bundled/offline product ids to the live store.
    if (cart.hasFallbackItems) {
      setState(() {
        _preparing = false;
        _prepareError =
            'Some items in your cart were loaded offline and their live prices '
            'could not be verified. Please remove them and try again.';
      });
      return;
    }

    if (cart.cartItems.isEmpty) {
      setState(() {
        _preparing = false;
        _prepareError = 'Your cart is empty.';
      });
      return;
    }

    final email = _billingEmail;
    if (email.isEmpty) {
      setState(() {
        _preparing = false;
        _prepareError =
            'An email address is required to place an order. Please go back and fill it in.';
      });
      return;
    }

    try {
      final session = await _service.createCart();
      for (final item in cart.cartItems) {
        final productId = int.tryParse(item.id);
        if (productId == null) {
          throw StoreApiException('"${item.name}" is not available in the live store.');
        }
        await _service.addToCart(session, productId);
      }

      final (firstName, lastName) = _nameParts;
      final totals = await _service.updateCustomer(
        session,
        firstName: firstName,
        lastName: lastName,
        address1: widget.address1,
        city: widget.city,
        state: 'WB',
        postcode: widget.pincode,
        country: 'IN',
        email: email,
        phone: widget.phone,
      );

      if (!mounted) return;
      setState(() {
        _session = session;
        _totals = totals;
        _preparing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _preparing = false;
        _prepareError = e is StoreApiException
            ? e.message
            : 'Could not reach the store. Please check your connection and try again.';
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_placing) return;

    final session = _session;
    final totals = _totals;
    if (session == null || totals == null) {
      await _prepareCart();
      return;
    }

    setState(() => _placing = true);

    final cart = context.read<CartProvider>();
    final items = cart.cartItems
        .map((p) => PlacedOrderLine(name: p.name, price: p.price, weight: p.weight))
        .toList();
    final address = '${widget.address1}, ${widget.city} - ${widget.pincode}';
    final (firstName, lastName) = _nameParts;

    // Delivery date/slot are passed to the store as a structured note —
    // the only channel the standard Store API offers without custom code.
    final noteBuffer = StringBuffer()
      ..writeln('Delivery Date: ${widget.deliveryDate}')
      ..writeln('Delivery Slot: ${widget.deliverySlot}');
    if (widget.altPhone.trim().isNotEmpty) {
      noteBuffer.writeln('Alternative Phone: ${widget.altPhone.trim()}');
    }

    StoreCheckoutResult? result;
    String? syncError;
    try {
      result = await _service.checkout(
        session: session,
        firstName: firstName,
        lastName: lastName,
        address1: widget.address1,
        city: widget.city,
        state: 'WB',
        postcode: widget.pincode,
        country: 'IN',
        email: _billingEmail,
        phone: widget.phone,
        paymentMethod: _selectedPayment,
        customerNote: noteBuffer.toString(),
      );
    } catch (e) {
      syncError = e is StoreApiException ? e.message : 'Could not reach the store';
    }

    if (!mounted) return;

    // The store did not create an order. Do NOT pretend it succeeded —
    // keep the cart intact so the customer can retry or change method.
    if (result == null || result.orderId == 0) {
      setState(() => _placing = false);
      showErrorToast(
        context,
        syncError != null ? 'Order not placed: $syncError' : 'Order could not be placed. Please try again.',
      );
      return;
    }

    final isOnline = _selectedPayment != 'cod';
    final order = cart.recordOrder(
      total: totals.totalPrice,
      payment: _selectedPayment == 'cod' ? 'Cash on Delivery' : 'Online (UPI / Card / NetBanking)',
      serverId: result.orderId,
      orderKey: result.orderKey,
      status: isOnline ? 'awaiting_payment' : (result.status.isEmpty ? 'processing' : result.status),
      synced: true,
      customerName: widget.customerName,
      phone: widget.phone,
      address: address,
      items: items,
      billingEmail: _billingEmail,
      deliveryDate: widget.deliveryDate,
      deliverySlot: widget.deliverySlot,
    );
    cart.clearCart();

    // Online payment: hand the customer to the gateway page returned by the
    // store; the confirmation screen will verify the real payment status.
    if (isOnline && result.redirectUrl.isNotEmpty) {
      final uri = Uri.tryParse(result.redirectUrl);
      if (uri != null) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(
          order: order,
          awaitingPayment: isOnline,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  String _fmt(double v) => '₹${v.toStringAsFixed(0)}';

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
            const SizedBox(height: 12),
            _sectionHeader('Order Total'),
            _buildTotalsCard(),
            const SizedBox(height: 12),
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
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTotalsCard() {
    if (_preparing) {
      return const Card(
        margin: EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Calculating delivery charge for your address...'),
            ],
          ),
        ),
      );
    }

    if (_prepareError != null) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _prepareError!,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _prepareCart,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text('Retry', style: GoogleFonts.poppins(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF55D2C),
                  side: const BorderSide(color: Color(0xFFF55D2C)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totals = _totals!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _priceRow('Items total', _fmt(totals.totalItems)),
            for (final fee in totals.fees)
              _priceRow(fee.name, _fmt(fee.amount)),
            _priceRow('Delivery', _fmt(totals.shipping)),
            const Divider(height: 16),
            _priceRow('Total', _fmt(totals.totalPrice), bold: true),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Charged by kolkatafish.com',
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final canOrder = !_preparing && _prepareError == null && !_placing;
    final totalLabel = _totals != null ? _fmt(_totals!.totalPrice) : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: canOrder ? _placeOrder : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF55D2C),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFF55D2C).withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _placing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedPayment == 'razorpay' ? 'Proceed to Pay' : 'Place Order',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (totalLabel.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(totalLabel, style: GoogleFonts.poppins(fontSize: 16)),
                  ],
                ],
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

  Widget _priceRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  color: bold ? Colors.black87 : Colors.grey.shade700)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: bold ? const Color(0xFFF55D2C) : null)),
        ],
      ),
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
