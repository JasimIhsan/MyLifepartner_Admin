import 'dart:developer';

import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import 'login_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _isLoading = false;
  String? _apiResponse;
  String? _error;

  // Function to test API using Dio package
  Future<void> _fetchUserDio() async {
    setState(() {
      _isLoading = true;
      _apiResponse = null;
      _error = null;
    });

    try {
      // Use the singleton ApiService
      // Note: The base URL is already configured in ApiService, so we only need the path
      final response = await ApiService.client.get('/health');

      // Optional delay (for demo only)
      await Future.delayed(const Duration(seconds: 3));

      final data = response.data;

      setState(() {
        _apiResponse = data is Map && data['message'] != null
            ? "Success: ${data['message']}"
            : "Success: $data";
      });

      log("Dio Success: $data");
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?.toString() ?? "Network error";
      });
      log("Dio Error: ${e.message}");
    } catch (e) {
      setState(() {
        _error = "Unexpected error: $e";
      });
      log("Unknown Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine if we are on a "web" (wide) screen or mobile
            final bool isWeb = constraints.maxWidth > 900;
            final size = MediaQuery.of(context).size;

            debugPrint("Size: $size");
            debugPrint("Constraints: $constraints");

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 80.0 : 24.0,
                    vertical: 30.0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: isWeb
                          ? _buildWebLayout(size)
                          : _buildMobileLayout(size, constraints),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 5, child: _buildHeroSection(size, true)),
        const SizedBox(width: 80),
        Expanded(flex: 4, child: _buildContentSection(true)),
      ],
    );
  }

  Widget _buildMobileLayout(Size size, BoxConstraints constraints) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildHeroSection(size, false),
        const SizedBox(height: 30),
        _buildContentSection(false),
      ],
    );
  }

  Widget _buildHeroSection(Size size, bool isWeb) {
    return FadeInDown(
      duration: const Duration(milliseconds: 1200),
      child: Container(
        height: isWeb ? size.height * 0.7 : size.height * 0.45,
        constraints: isWeb ? const BoxConstraints(minHeight: 500) : null,
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Icon(
            Icons.diversity_1_rounded,
            size: isWeb ? 200 : 120,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection(bool isWeb) {
    return FadeInUp(
      duration: const Duration(milliseconds: 1200),
      delay: const Duration(milliseconds: 200),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: isWeb
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_apiResponse != null)
            Align(
              alignment: isWeb ? Alignment.centerLeft : Alignment.center,
              child: Text(
                _apiResponse!,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (_error != null)
            Align(
              alignment: isWeb ? Alignment.centerLeft : Alignment.center,
              child: Text(
                _error!,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          if (!_isLoading)
            Align(
              alignment: isWeb ? Alignment.centerLeft : Alignment.center,
              child: ElevatedButton(
                onPressed: () async {
                  await _fetchUserDio();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  "Test API",
                  style: GoogleFonts.poppins(
                    color: const Color.fromRGBO(255, 255, 255, 1),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            "Connect with people\nwho share your values",
            textAlign: isWeb ? TextAlign.left : TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isWeb ? 42 : 26,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Join the community of millions of people who have found their life partner.",
            textAlign: isWeb ? TextAlign.left : TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isWeb ? 18 : 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: isWeb ? 300 : double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: Text(
                "Get Started",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
