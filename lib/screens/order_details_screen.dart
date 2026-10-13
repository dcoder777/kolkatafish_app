import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../utils/toast_helper.dart';

class OrderDetailsScreen extends StatelessWidget {
  final PlacedOrder order;

  const OrderDetailsScreen({super.key, required this.order});

  String get _siteUrl {
    if (order.serverId != null && order.orderKey.isNotEmpty) {
      return 'https://kolkatafish.com/checkout/order-received/${order.serverId}/?key=${order.orderKey}';
    }
    return 'https://kolkatafish.com';
  }

  String _receiptText() {
    final b = StringBuffer();
    final date = order.placedAt;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    b.writeln('        KOLKATAFISH - ORDER RECEIPT');
    b.writeln('        ============================');
    b.writeln('');
    b.writeln('Order ID   : ${order.displayId}');
    b.writeln('Date       : $dateStr');
    b.writeln('Status     : ${order.status.toUpperCase()}');
    b.writeln('Payment    : ${order.payment}');
    b.writeln('');
    b.writeln('ITEMS');
    b.writeln('-----');
    if (order.items.isEmpty) {
      b.writeln('(item list not available)');
    } else {
      for (final item in order.items) {
        b.writeln(item.name);
        b.writeln('  ${item.weight} x Rs.${item.price.toStringAsFixed(0)}');
        b.writeln('');
      }
    }
    b.writeln('Items total: Rs.${order.total.toStringAsFixed(0)}');
    b.writeln('(includes Rs.50 delivery charged in app)');
    b.writeln('');
    b.writeln('DELIVER TO');
    b.writeln('----------');
    if (order.customerName.isNotEmpty) b.writeln(order.customerName);
    if (order.phone.isNotEmpty) b.writeln('Phone: ${order.phone}');
    if (order.address.isNotEmpty) b.writeln(order.address);
    b.writeln('');
    b.writeln('Thank you for ordering from KolkataFish!');
    b.writeln('kolkatafish.com | +91 9830083112');
    return b.toString();
  }

  Future<void> _downloadReceipt(BuildContext context) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/KolkataFish_Receipt_${order.displayId.replaceAll('#', '')}.txt');
      await file.writeAsString(_receiptText());
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/plain')],
        subject: 'KolkataFish Receipt ${order.displayId}',
        text: 'Order receipt for ${order.displayId}',
      );
    } catch (_) {
      if (context.mounted) showErrorToast(context, 'Could not create receipt');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order.displayId,
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: order.synced ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: order.synced ? Colors.green.shade200 : Colors.orange.shade200),
                        ),
                        child: Text(
                          order.synced
                              ? order.status.toUpperCase()
                              : 'NOT SYNCED',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: order.synced
                                  ? Colors.green.shade800
                                  : Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoRow(Icons.payments_outlined, 'Payment', order.payment),
                  _infoRow(
                      Icons.calendar_today_outlined,
                      'Placed on',
                      '${order.placedAt.day}/${order.placedAt.month}/${order.placedAt.year} '
                          '${order.placedAt.hour}:${order.placedAt.minute.toString().padLeft(2, '0')}'),
                  if (order.customerName.isNotEmpty)
                    _infoRow(Icons.person_outline, 'Customer', order.customerName),
                  if (order.phone.isNotEmpty)
                    _infoRow(Icons.phone_outlined, 'Phone', order.phone),
                  if (order.address.isNotEmpty)
                    _infoRow(Icons.location_on_outlined, 'Deliver to', order.address),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!order.synced)
            Card(
              elevation: 0,
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'This order was saved in the app only and was not received by the KolkataFish store. Please contact support to confirm.',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange.shade900)),
                  ),
                ]),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Items', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (order.items.isEmpty)
                    Text('Item list not available for this order.',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey))
                  else
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: GoogleFonts.poppins(fontSize: 13)),
                                    Text(item.weight,
                                        style: GoogleFonts.poppins(
                                            fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Text('₹${item.price.toStringAsFixed(0)}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total paid', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('₹${order.total.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF55D2C))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _downloadReceipt(context),
              icon: const Icon(Icons.download_outlined),
              label: Text('Download Receipt', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF55D2C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(_siteUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new, color: Color(0xFFF55D2C)),
              label: Text('View on Website', style: GoogleFonts.poppins(color: const Color(0xFFF55D2C))),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFF55D2C)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
