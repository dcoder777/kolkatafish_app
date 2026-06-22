import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactTab extends StatelessWidget {
  const ContactTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contact Us',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF55D2C).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.set_meal,
                size: 64,
                color: Color(0xFFF55D2C),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Get in Touch',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Have questions? We\'d love to hear from you.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _contactCard(
            theme,
            Icons.phone,
            'Call Us',
            '+91 9830083112',
            '+91 8017404851',
          ),
          const SizedBox(height: 12),
          _contactCard(
            theme,
            Icons.email,
            'Email Us',
            'kolkatfish72@gmail.com',
            'kolkatfish83@gmail.com',
          ),
          const SizedBox(height: 12),
          _contactCard(
            theme,
            Icons.location_on,
            'Visit Us',
            '86, Thakurpukur Road, Kolkata\nNear KMC School',
            'Open: 7 AM - 9 PM',
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Hours',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _hoursRow('Monday - Saturday', '7:00 AM - 9:00 PM'),
                  _hoursRow('Sunday', '8:00 AM - 6:00 PM'),
                  _hoursRow('Public Holidays', 'Closed'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(ThemeData theme, IconData icon, String title, String line1, String line2) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF55D2C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFF55D2C)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    line1,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    line2,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hoursRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          Text(
            hours,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
