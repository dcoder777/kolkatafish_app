import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/store_api_service.dart';
import '../utils/toast_helper.dart';

/// Shown after checkout. For COD the order is already accepted by the store;
/// for online payments it starts in an "awaiting payment" state and polls the
/// real order status until the gateway result is known.
class OrderConfirmationScreen extends StatefulWidget {
  final PlacedOrder order;
  final bool awaitingPayment;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
    this.awaitingPayment = false,
  });

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  late PlacedOrder _order;
  late bool _awaitingPayment;
  bool _checking = false;
  String? _statusError;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _awaitingPayment = widget.awaitingPayment;
    if (_awaitingPayment) {
      // Check once automatically in case the customer already paid in the
      // gateway page before returning to the app.
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _checkPaymentStatus();
      });
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_checking) return;
    final serverId = _order.serverId;
    if (serverId == null || _order.orderKey.isEmpty || _order.billingEmail.isEmpty) {
      setState(() => _statusError = 'Missing order details to verify payment.');
      return;
    }

    setState(() {
      _checking = true;
      _statusError = null;
    });

    final service = StoreApiService();
    try {
      final status = await service.fetchOrderStatus(
        orderId: serverId,
        orderKey: _order.orderKey,
        billingEmail: _order.billingEmail,
      );
      if (!mounted) return;

      if (status.isPaid) {
        setState(() {
          _awaitingPayment = false;
          _order = _withStatus(_order, status.status.isEmpty ? 'processing' : status.status);
        });
        context.read<CartProvider>().updateOrderStatus(_order.id, status: _order.status);
        showSuccessToast(context, 'Payment received. Thank you!');
      } else if (status.isFailed) {
        setState(() {
          _order = _withStatus(_order, status.status);
          _awaitingPayment = false;
        });
        context.read<CartProvider>().updateOrderStatus(_order.id, status: status.status);
      } else {
        setState(() => _statusError = 'Payment still pending. Please complete the payment on the gateway page.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusError = 'Could not verify payment right now. Please try again.');
    } finally {
      service.dispose();
      if (mounted) setState(() => _checking = false);
    }
  }

  PlacedOrder _withStatus(PlacedOrder o, String status) {
    return PlacedOrder(
      id: o.id,
      serverId: o.serverId,
      orderKey: o.orderKey,
      status: status,
      synced: o.synced,
      total: o.total,
      payment: o.payment,
      placedAt: o.placedAt,
      customerName: o.customerName,
      phone: o.phone,
      address: o.address,
      items: o.items,
      billingEmail: o.billingEmail,
      deliveryDate: o.deliveryDate,
      deliverySlot: o.deliverySlot,
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentFailed = !_awaitingPayment && (_order.status == 'failed' || _order.status == 'cancelled' || _order.status == 'refunded');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          paymentFailed ? 'Payment Failed' : (_awaitingPayment ? 'Complete Your Payment' : 'Order Confirmed'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statusIcon(paymentFailed),
              const SizedBox(height: 24),
              Text(
                paymentFailed ? 'Payment Not Completed' : (_awaitingPayment ? 'Awaiting Payment' : 'Thank You!'),
                style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                paymentFailed
                    ? 'The payment for this order did not go through. You have not been charged.'
                    : (_awaitingPayment
                        ? 'Your order is saved. Complete the payment on the page that opened, then tap "Check Payment Status".'
                        : 'Your order has been received by the KolkataFish store.'),
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _row('Order ID', _order.displayId),
                      const SizedBox(height: 10),
                      _row('Total', '₹${_order.total.toStringAsFixed(0)}'),
                      const SizedBox(height: 10),
                      _row('Payment', _order.payment),
                      const SizedBox(height: 10),
                      _row(
                        'Order Date',
                        '${_order.placedAt.day}/${_order.placedAt.month}/${_order.placedAt.year} '
                        '${_order.placedAt.hour}:${_order.placedAt.minute.toString().padLeft(2, '0')}',
                      ),
                      if (_order.deliveryDate.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _row('Delivery', '${_order.deliveryDate} (${_order.deliverySlot})'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (paymentFailed)
                _banner(
                  Icons.cancel_outlined,
                  Colors.red.shade50,
                  Colors.red.shade200,
                  Colors.red.shade800,
                  'Status: ${_order.status}. You can return to the cart and try again.',
                )
              else if (_awaitingPayment)
                _banner(
                  Icons.hourglass_top_outlined,
                  Colors.orange.shade50,
                  Colors.orange.shade200,
                  Colors.orange.shade900,
                  _statusError ?? 'Waiting for payment confirmation from the gateway.',
                )
              else
                _banner(
                  Icons.cloud_done_outlined,
                  Colors.green.shade50,
                  Colors.green.shade200,
                  Colors.green.shade800,
                  'Order received by KolkataFish store.',
                ),
              if (_awaitingPayment) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _checking ? null : _checkPaymentStatus,
                    icon: _checking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_checking ? 'Checking...' : 'Check Payment Status',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF55D2C),
                      side: const BorderSide(color: Color(0xFFF55D2C)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              Consumer<AuthProvider>(
                builder: (_, auth, __) => auth.isGuest
                    ? Card(
                        color: Colors.orange.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.person_add, size: 32, color: Color(0xFFF55D2C)),
                              const SizedBox(height: 8),
                              Text('Save your order history!',
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Create an account to track all your orders.',
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                                  textAlign: TextAlign.center),
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

  Widget _statusIcon(bool paymentFailed) {
    if (paymentFailed) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.cancel_rounded, size: 80, color: Colors.red.shade400),
      );
    }
    if (_awaitingPayment) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.hourglass_top_rounded, size: 80, color: Color(0xFFF55D2C)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_circle_rounded, size: 80, color: Color(0xFF4CAF50)),
    );
  }

  Widget _banner(IconData icon, Color bg, Color border, Color fg, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(children: [
        Icon(icon, color: fg, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: GoogleFonts.poppins(fontSize: 12, color: fg)),
        ),
      ]),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
