import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phone_form_field/phone_form_field.dart';

import 'otp_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  PhoneNumber _phoneNumber = const PhoneNumber(
    isoCode: IsoCode.IN,
    nsn: "9876543210",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWeb = constraints.maxWidth > 900;
            final size = MediaQuery.of(context).size;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 80.0 : 24.0,
                        vertical: 24.0,
                      ),
                      child: isWeb
                          ? _buildWebLayout(size)
                          : _buildMobileLayout(size),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWebLayout(Size size) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: FadeInLeft(
            duration: const Duration(milliseconds: 1000),
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_person_rounded,
                    size: 150,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "Secure Login",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Your privacy is our priority. Login safely to find your perfect match.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 80),
        Expanded(flex: 1, child: _buildLoginForm(true)),
      ],
    );
  }

  Widget _buildMobileLayout(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLoginHeader(),
        const SizedBox(height: 48),
        _buildLoginForm(false),
      ],
    );
  }

  Widget _buildLoginHeader() {
    return FadeInDown(
      duration: const Duration(milliseconds: 800),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome Back",
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your mobile number to continue.",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(bool isWeb) {
    return FadeInUp(
      duration: const Duration(milliseconds: 1000),
      delay: const Duration(milliseconds: 200),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: isWeb
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            if (isWeb) ...[
              Text(
                "Welcome Back",
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Enter your mobile number to continue.",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
            ],
            // TextFormField(
            //   keyboardType: TextInputType.phone,
            //   style: GoogleFonts.poppins(fontSize: 16),
            //   decoration: InputDecoration(
            //     hintText: "Mobile Number",
            //     prefixIcon: const Icon(Icons.phone_android_rounded),
            //     filled: true,
            //     fillColor: Colors.grey[50],
            //     border: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(16),
            //       borderSide: BorderSide.none,
            //     ),
            //     contentPadding: const EdgeInsets.symmetric(
            //       horizontal: 20,
            //       vertical: 18,
            //     ),
            //   ),
            //   validator: (value) {
            //     if (value == null || value.isEmpty) {
            //       return 'Please enter your mobile number';
            //     }
            //     if (value.length < 10) {
            //       return 'Please enter a valid 10-digit number';
            //     }
            //     return null;
            //   },
            //   onChanged: (value) {
            //     setState(() {
            //       phoneNumber = value;
            //     });
            //   },
            // ),
            PhoneFormField(
              initialValue: _phoneNumber,
              validator: PhoneValidator.compose([
                PhoneValidator.required(
                  context,
                  errorText: 'Please enter your mobile number',
                ),
                PhoneValidator.validMobile(
                  context,
                  errorText: 'Please enter a valid mobile number',
                ),
              ]),
              countrySelectorNavigator: isWeb
                  ? const CountrySelectorNavigator.dialog()
                  : const CountrySelectorNavigator.draggableBottomSheet(),
              onChanged: (value) {
                setState(() {
                  _phoneNumber = value;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OtpPage(phoneNumber: _phoneNumber.international),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  "Send OTP",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "Sign Up",
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
