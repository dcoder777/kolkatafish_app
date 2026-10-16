import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/toast_helper.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _altPhoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _initDefaults();
  }

  void _initDefaults() {
    // If current time in IST is after 8 PM (20:00), earliest delivery is tomorrow
    final now = DateTime.now();
    if (now.hour >= 20) {
      _selectedDate = now.add(const Duration(days: 1));
    } else {
      _selectedDate = now;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.userName.isNotEmpty && _nameCtrl.text.isEmpty) {
        _nameCtrl.text = auth.userName;
      }
      if (auth.userEmail.isNotEmpty && _emailCtrl.text.isEmpty) {
        _emailCtrl.text = auth.userEmail;
      }
      if (auth.userPhone.isNotEmpty && _phoneCtrl.text.isEmpty) {
        _phoneCtrl.text = auth.userPhone;
      }
      if (_cityCtrl.text.isEmpty) _cityCtrl.text = 'Kolkata';
      if (_pincodeCtrl.text.isEmpty) _pincodeCtrl.text = '700063';
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _altPhoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year';
  }

  List<String> _getAvailableSlots(DateTime date) {
    final now = DateTime.now();
    final isToday = (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day);
    final hour = now.hour;

    final allSlots = <String>[
      '9:00am - 12:00pm',
      '12:00pm - 4:00pm',
      '5:00pm - 8:00pm',
    ];

    if (!isToday) {
      return allSlots;
    }

    // For today:
    if (hour < 9) {
      return allSlots;
    } else if (hour < 12) {
      return ['12:00pm - 4:00pm', '5:00pm - 8:00pm'];
    } else if (hour < 17) {
      return ['5:00pm - 8:00pm'];
    } else {
      return [];
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = now.hour >= 20 ? now.add(const Duration(days: 1)) : now;
    final lastDate = firstDate.add(const Duration(days: 3));

    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate.isBefore(firstDate) ? firstDate : _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF55D2C),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        final available = _getAvailableSlots(picked);
        if (_selectedSlot == null || !available.contains(_selectedSlot)) {
          _selectedSlot = available.isNotEmpty ? available.first : null;
        }
      });
    }
  }

  void _onContinueToPayment() {
    if (!_formKey.currentState!.validate()) {
      showErrorToast(context, 'Please complete all required fields.');
      return;
    }

    final cart = context.read<CartProvider>();
    if (cart.hasFallbackItems) {
      showErrorToast(
        context,
        'Some items were loaded offline and cannot be ordered. '
        'Please remove them or reconnect and try again.',
      );
      return;
    }

    final slots = _getAvailableSlots(_selectedDate);
    if (slots.isEmpty) {
      showErrorToast(context,
          'No delivery slots available for today. Please select tomorrow.');
      return;
    }

    if (_selectedSlot == null || _selectedSlot!.isEmpty) {
      showErrorToast(context, 'Please select a delivery slot.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          customerName: _nameCtrl.text.trim(),
          customerEmail: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          altPhone: _altPhoneCtrl.text.trim(),
          address1: _addressCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          pincode: _pincodeCtrl.text.trim(),
          deliveryDate: _formatDate(_selectedDate),
          deliverySlot: _selectedSlot!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final subtotal = cart.cartTotal;
    final availableSlots = _getAvailableSlots(_selectedDate);

    // Auto-select first slot if none selected or invalid
    if (_selectedSlot == null && availableSlots.isNotEmpty) {
      _selectedSlot = availableSlots.first;
    } else if (_selectedSlot != null &&
        !availableSlots.contains(_selectedSlot)) {
      _selectedSlot = availableSlots.isNotEmpty ? availableSlots.first : null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<AuthProvider>(
                builder: (_, auth, __) => auth.isGuest
                    ? Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFF55D2C)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline,
                                color: Color(0xFFF55D2C)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Guest Checkout',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text('${auth.userName} • ${auth.userPhone}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey.shade700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              _sectionHeader('Delivery Schedule'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF55D2C).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Your chosen date and slot are sent to the store as a request. '
                        'The store confirms the final delivery time by phone.',
                        style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: Colors.grey.shade700,
                            height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Delivery Date Picker Card
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: Color(0xFFF55D2C)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivery Date *',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(_selectedDate),
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down,
                                color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Delivery Slot Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSlot,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Delivery Slot *',
                        prefixIcon: const Icon(Icons.access_time_outlined,
                            color: Color(0xFFF55D2C)),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                      ),
                      items: availableSlots.isNotEmpty
                          ? availableSlots
                              .map((slot) => DropdownMenuItem(
                                    value: slot,
                                    child: Text(slot,
                                        style:
                                            GoogleFonts.poppins(fontSize: 14)),
                                  ))
                              .toList()
                          : [
                              DropdownMenuItem(
                                value: null,
                                enabled: false,
                                child: Text(
                                    'No slots available today (Select tomorrow)',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12, color: Colors.red)),
                              ),
                            ],
                      onChanged: availableSlots.isNotEmpty
                          ? (val) => setState(() => _selectedSlot = val)
                          : null,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please select a delivery slot';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionHeader('Delivery Address'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _validatedInput(
                      label: 'Full Name *',
                      ctrl: _nameCtrl,
                      icon: Icons.person_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter full name';
                        }
                        if (v.trim().length < 2) return 'Enter a valid name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _validatedInput(
                      label: 'Email Address *',
                      ctrl: _emailCtrl,
                      icon: Icons.email_outlined,
                      type: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter email address';
                        }
                        final emailRegex =
                            RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _validatedInput(
                      label: 'Phone Number (10 digits) *',
                      ctrl: _phoneCtrl,
                      icon: Icons.phone_outlined,
                      type: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter phone number';
                        }
                        final clean = v.replaceAll(RegExp(r'\D'), '');
                        if (clean.length < 10) {
                          return 'Enter valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _validatedInput(
                      label: 'Alternative Phone (Optional)',
                      ctrl: _altPhoneCtrl,
                      icon: Icons.phone_iphone_outlined,
                      type: TextInputType.phone,
                      isRequired: false,
                    ),
                    const SizedBox(height: 10),
                    _validatedInput(
                      label: 'Address (House/Flat, Street, Landmark) *',
                      ctrl: _addressCtrl,
                      icon: Icons.home_outlined,
                      maxLines: 2,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter delivery address';
                        }
                        if (v.trim().length < 5) return 'Address too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _validatedInput(
                            label: 'City *',
                            ctrl: _cityCtrl,
                            icon: Icons.location_city_outlined,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter city'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _validatedInput(
                            label: 'Pincode (6 digits) *',
                            ctrl: _pincodeCtrl,
                            icon: Icons.pin_outlined,
                            type: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter pincode';
                              }
                              final clean = v.replaceAll(RegExp(r'\D'), '');
                              if (clean.length != 6) {
                                return 'Enter 6-digit pincode';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionHeader('Order Summary'),
              ...cart.cartItems.map((item) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(item.name,
                              style: GoogleFonts.poppins(fontSize: 13)),
                        ),
                        Text('${item.weight} × ${item.formattedPrice}',
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              Divider(indent: 16, endIndent: 16, color: Colors.grey.shade300),
              _priceRow('Subtotal', '₹${subtotal.toStringAsFixed(0)}'),
              _priceRow('Delivery & handling', 'Calculated at payment'),
              Divider(indent: 16, endIndent: 16, color: Colors.grey.shade300),
              _priceRow('Subtotal payable', '₹${subtotal.toStringAsFixed(0)}',
                  bold: true),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Delivery charge and any handling fees are added by the '
                  'kolkatafish.com store based on your address and shown on '
                  'the next screen before you pay.',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
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
          onPressed: _onContinueToPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF55D2C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Continue to Payment',
                  style: GoogleFonts.poppins(fontSize: 16)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(title,
          style:
              GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _validatedInput({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    TextInputType? type,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: bold ? const Color(0xFFF55D2C) : null)),
        ],
      ),
    );
  }
}
