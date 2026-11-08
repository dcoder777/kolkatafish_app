import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactTab extends StatelessWidget {
  final bool hideAppBar;
  const ContactTab({super.key, this.hideAppBar = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = ListView(
      physics: const BouncingScrollPhysics(),
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
            Icons.headset_mic_outlined,
            'Support',
            '+91 8348043021',
            line2: '+91 7044476224',
            phone1: '+91 8348043021',
            phone2: '+91 7044476224',
          ),
          const SizedBox(height: 12),
          _contactCard(
            theme,
            Icons.email,
            'Email Us',
            'info@kolkatafish.com',
          ),
          const SizedBox(height: 12),
          _contactCard(
            theme,
            Icons.location_on,
            'Visit Us',
            '69, Dhakuria east road, kolkata 700078',
          ),
        ],
      );

    if (hideAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contact Us',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: content,
    );
  }

  Widget _contactCard(
      ThemeData theme, IconData icon, String title, String line1,
      {String? line2, String? phone1, String? phone2}) {
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
                  phone1 != null
                      ? _phoneLink(phone1)
                      : Text(
                          line1,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                  if (phone2 != null)
                    _phoneLink(phone2)
                  else if (line2 != null && line2.isNotEmpty)
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

  Widget _phoneLink(String phone) {
    return InkWell(
      onTap: () => _dial(phone),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.call, size: 14, color: Color(0xFFF55D2C)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                phone,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF55D2C),
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFFF55D2C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dial(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;
    await launchUrl(
      Uri.parse('tel:$digits'),
      mode: LaunchMode.externalApplication,
    );
  }
}
