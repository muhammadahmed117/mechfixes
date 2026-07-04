import 'package:flutter/material.dart';

class AddMechanicDialog extends StatefulWidget {
  const AddMechanicDialog({super.key});

  @override
  State<AddMechanicDialog> createState() => _AddMechanicDialogState();
}

class _AddMechanicDialogState extends State<AddMechanicDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController specialtyController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  @override
  void dispose() {
    businessNameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    specialtyController.dispose();
    locationController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF98A2B3),
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD0D5DD),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF1F3FAF),
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.2,
        ),
      ),
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 12,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _inputDecoration(hint),
      validator: validator,
    );
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone is required';
    }

    final cleaned = value.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (cleaned.length < 7 || !RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  String? _coordinatesValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Location coordinates are required';
    }

    final text = value.trim();
    final regex = RegExp(
      r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$',
    );

    if (!regex.hasMatch(text)) {
      return 'Enter valid coordinates like 37.7749, -122.4194';
    }

    final parts = text.split(',');
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());

    if (lat == null || lng == null) {
      return 'Enter valid coordinates';
    }

    if (lat < -90 || lat > 90) {
      return 'Latitude must be between -90 and 90';
    }

    if (lng < -180 || lng > 180) {
      return 'Longitude must be between -180 and 180';
    }

    return null;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final businessName = businessNameController.text.trim();
      final address = addressController.text.trim();
      final phone = phoneController.text.trim();
      final specialty = specialtyController.text.trim();
      final location = locationController.text.trim();

      debugPrint('Business Name: $businessName');
      debugPrint('Address: $address');
      debugPrint('Phone: $phone');
      debugPrint('Specialty: $specialty');
      debugPrint('Location: $location');

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mechanic added successfully'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 380,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Add New Mechanic",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                _buildLabel("Business Name"),
                _buildTextField(
                  controller: businessNameController,
                  hint: "Enter business name",
                  validator: (value) =>
                      _requiredValidator(value, 'Business name'),
                ),
                const SizedBox(height: 18),

                _buildLabel("Address"),
                _buildTextField(
                  controller: addressController,
                  hint: "Enter address",
                  validator: (value) => _requiredValidator(value, 'Address'),
                ),
                const SizedBox(height: 18),

                _buildLabel("Phone"),
                _buildTextField(
                  controller: phoneController,
                  hint: "Enter phone number",
                  keyboardType: TextInputType.phone,
                  validator: _phoneValidator,
                ),
                const SizedBox(height: 18),

                _buildLabel("Specialty"),
                _buildTextField(
                  controller: specialtyController,
                  hint: "Enter specialty",
                  validator: (value) => _requiredValidator(value, 'Specialty'),
                ),
                const SizedBox(height: 18),

                _buildLabel("Location Coordinates"),
                _buildTextField(
                  controller: locationController,
                  hint: "e.g. 37.7749, -122.4194",
                  keyboardType: TextInputType.number,
                  validator: _coordinatesValidator,
                ),
                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: Color(0xFFD0D5DD)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Color(0xFF344054),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F3FAF),
                          minimumSize: const Size.fromHeight(50),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Add Mechanic",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}