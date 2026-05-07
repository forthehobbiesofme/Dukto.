import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nearby_service_app/providers/auth_provider.dart';
import 'package:nearby_service_app/views/home_screen.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  int _step = 0; // 0: Main Info, 1: Driver Extras
  bool _isDriver = true; // Default to Driver as per image right side

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _klController = TextEditingController();
  final TextEditingController _autoNameController = TextEditingController();
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Colors based on the provided image
  static const Color colorVibrantOrange = Color(0xFFF58E3C);
  static const Color colorLightPeach = Color(0xFFFFD1B2);
  static const Color colorBorderOrange = Color(0xFFE89E5B);
  static const Color colorGreyText = Color(0xFF9E9E9E);
  static const Color colorPlaceholderGrey = Color(0xFFBDBDBD);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _klController.dispose();
    _autoNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _onNext() async {
    if (_step == 0) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name')),
        );
        return;
      }
      if (_isDriver && _klController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your KL plate number')),
        );
        return;
      }
      if (_phoneController.text.trim().length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your phone number correctly (10 digits)')),
        );
        return;
      }

      if (_isDriver) {
        setState(() => _step = 1);
      } else {
        _completeRegistration();
      }
    } else {
      _completeRegistration();
    }
  }

  void _completeRegistration() async {
    await ref.read(authProvider.notifier).saveSession(
      role: _isDriver ? 'driver' : 'user',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      numberPlate: _isDriver ? _klController.text.trim() : null,
      autoName: _isDriver ? _autoNameController.text.trim() : null,
      profileImageUrl: _imageFile?.path,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 50),
              // Profile Circle
              GestureDetector(
                onTap: _step == 1 ? _pickImage : null,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    color: colorPlaceholderGrey,
                    shape: BoxShape.circle,
                  ),
                  child: _imageFile != null
                      ? ClipOval(child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : (_step == 1 ? const Icon(Icons.camera_alt, size: 40, color: Colors.white) : null),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Enter your details here',
                style: GoogleFonts.montserrat(
                  fontSize: 18, 
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              
              if (_step == 0) _buildStep0() else _buildStep1(),

              const SizedBox(height: 50),
              // Next Button
              Align(
                alignment: Alignment.centerRight,
                child: Semantics(
                  button: true,
                  label: 'Proceed to next step',
                  child: GestureDetector(
                    onTap: _onNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorLightPeach,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEAA297), width: 1.5),
                      ),
                      child: Text(
                        'Next',
                        style: GoogleFonts.montserrat(
                          fontSize: 20, 
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      children: [
        // Role Toggle
        Container(
          height: 65,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorLightPeach,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorBorderOrange, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Select Driver Role',
                  selected: _isDriver,
                  child: GestureDetector(
                    onTap: () => setState(() => _isDriver = true),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isDriver ? colorVibrantOrange : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Driver',
                        style: GoogleFonts.montserrat(
                          fontSize: 22, 
                          fontWeight: _isDriver ? FontWeight.w500 : FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Select User Role',
                  selected: !_isDriver,
                  child: GestureDetector(
                    onTap: () => setState(() => _isDriver = false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: !_isDriver ? colorVibrantOrange : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'user',
                        style: GoogleFonts.montserrat(
                          fontSize: 22, 
                          fontWeight: !_isDriver ? FontWeight.w500 : FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 50),
        // Name Input
        _buildTextField(_nameController, 'Enter your name'),
        const SizedBox(height: 35),
        // KL Input (Driver only)
        if (_isDriver) ...[
          _buildKLField(),
          const SizedBox(height: 35),
        ],
        // Phone Input
        _buildPhoneField(),
        const SizedBox(height: 40),
        // Location Text
        Column(
          children: [
            Text(
              'Turn on your location for',
              style: GoogleFonts.montserrat(fontSize: 15, color: colorGreyText),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'acutare service ',
                  style: GoogleFonts.montserrat(fontSize: 15, color: colorGreyText),
                ),
                Image.asset('Icons and assets/icons8-location-48.png', width: 16, height: 16, color: Colors.black),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildTextField(_autoNameController, 'Enter Auto Name (Optional)'),
        const SizedBox(height: 40),
        Text(
          'Upload a picture of your auto\nor yourself (Optional)',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(fontSize: 15, color: colorGreyText, height: 1.5),
        ),
        const SizedBox(height: 30),
        TextButton(
          onPressed: _completeRegistration,
          child: Text(
            'Skip for now', 
            style: GoogleFonts.montserrat(color: colorVibrantOrange, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: colorBorderOrange, width: 2)),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.montserrat(color: Colors.black, fontSize: 18),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(color: colorPlaceholderGrey, fontSize: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildKLField() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: colorBorderOrange, width: 2)),
      ),
      child: Row(
        children: [
          Text(
            'KL',
            style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(width: 25),
          Text(
            '12',
            style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(width: 25),
          Expanded(
            child: TextField(
              controller: _klController,
              style: GoogleFonts.montserrat(color: Colors.black, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'XX   XXXX',
                hintStyle: GoogleFonts.montserrat(color: colorPlaceholderGrey, fontSize: 18, letterSpacing: 2),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: colorBorderOrange, width: 2)),
      ),
      child: Row(
        children: [
          Image.asset('Icons and assets/icons8-india-48.png', width: 24, height: 24),
          const SizedBox(width: 8),
          Text(
            '+91',
            style: GoogleFonts.montserrat(fontSize: 18, color: colorPlaceholderGrey),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.montserrat(color: Colors.black, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Enter your number',
                hintStyle: GoogleFonts.montserrat(color: colorPlaceholderGrey, fontSize: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
