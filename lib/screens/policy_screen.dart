import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PolicyScreen extends StatelessWidget {
  final String title;
  final List<String> sections;

  const PolicyScreen({
    super.key,
    required this.title,
    required this.sections,
  });

  static const privacySections = [
    'We collect your name, phone number, email and delivery address only to process and deliver your orders.',
    'Payment for orders is Cash on Delivery. We do not store any card or banking details in the app.',
    'Your contact details are used only for order updates, delivery coordination and customer support. We do not sell your data to third parties.',
    'You can request deletion of your account data at any time by contacting us from the Support page.',
  ];

  static const termsSections = [
    'By placing an order on KolkataFish you agree to provide accurate delivery details and be available to receive the order.',
    'Product weights are approximate as fresh fish and meat are cleaned and cut to order. Final weight may vary slightly; you are charged for the actual delivered weight.',
    'Prices are subject to change based on daily market rates. The price shown at checkout is the price you pay.',
    'Orders can be cancelled before they are dispatched by contacting support. Delivery is typically within 2 hours inside Kolkata.',
    'Fresh products are not returnable once delivered, unless there is a quality issue, which must be reported within 1 hour of delivery.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF55D2C).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: Color(0xFFF55D2C)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Last updated: January 2026',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          ...sections.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(s,
                    style: GoogleFonts.poppins(
                        fontSize: 14, height: 1.6, color: Colors.grey.shade800)),
              )),
        ],
      ),
    );
  }
}
