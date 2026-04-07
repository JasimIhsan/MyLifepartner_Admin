import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/providers/image_asset_provider.dart';
import 'package:provider/provider.dart';

class AuthLayout extends StatelessWidget {
  final Widget child;
  final bool showLogo;
  final String? title;
  final String? topImage;
  final String? dynamicSection;

  const AuthLayout({
    super.key,
    required this.child,
    this.showLogo = true,
    this.title,
    this.topImage,
    this.dynamicSection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWeb = constraints.maxWidth > 900;
          final size = MediaQuery.of(context).size;

          if (isWeb) {
            return _buildWebLayout(context, size);
          }
          return _buildMobileLayout(context, size);
        },
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context, Size size) {
    return Row(
      children: [
        // Left Side - Info
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "lifepartneragain",
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "A trusted platform for emotionally\nmature relationships.",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Side - Form
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 60.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(true),
                      const SizedBox(height: 24),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, Size size) {
    return SizedBox(
      width: double.infinity,
      height: size.height,
      child: Stack(
        children: [
          // Background Image
          if (dynamicSection != null)
             Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.55,
              child: Consumer<ImageAssetProvider>(
                builder: (context, provider, _) {
                  final state = provider.getState(dynamicSection!);
                  final asset = provider.getFeaturedAsset(dynamicSection!);

                  if (state == ImageAssetLoadState.loading) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }

                  if (asset != null) {
                    return Image.network(
                      asset.imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    );
                  }

                  // Default Fallback
                  if (topImage != null) {
                    return Image.asset(
                      topImage!,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    );
                  }
                  
                  return Container(color: Colors.grey[100]);
                },
              ),
            )
          else if (topImage != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.55,
              child: Image.asset(
                topImage!,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

          // Scrollable Content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Gap to show the image
                    if (topImage != null || dynamicSection != null) SizedBox(height: size.height * 0.45),

                    // Main Sheet
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28.0, 12.0, 28.0, 32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Grab Handle
                              Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 32),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),

                              // Optional Header
                              if (showLogo) ...[
                                Text(
                                  "Life Partner Again",
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "A trusted platform for emotionally\nmature relationships.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],

                              // Form / Content
                              child,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Back Button if needed (Optional, usually handled by Scaffold)
          if (Navigator.canPop(context))
             Positioned(
               top: MediaQuery.of(context).padding.top + 10,
               left: 16,
               child: CircleAvatar(
                 backgroundColor: Colors.white.withValues(alpha: 0.8),
                 child: IconButton(
                   icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
                   onPressed: () => Navigator.pop(context),
                 ),
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isWeb) {
    if (!isWeb) return const SizedBox.shrink(); // Only for Web now
    return Column(
      children: [
        Text(
          "Life Partner Again",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            "A trusted platform for emotionally\nmature relationships.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
