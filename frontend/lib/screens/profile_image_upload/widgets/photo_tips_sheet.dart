import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';

class PhotoTipsSheet extends StatelessWidget {
  const PhotoTipsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    const tips = [
      (
        Icons.face_retouching_natural,
        'Solo shots only for your main',
        'Your first photo should clearly show your face. No group photos — people should immediately know who you are.',
      ),
      (
        Icons.wb_sunny_outlined,
        'Good natural lighting',
        'Bright, natural light is your best friend. Avoid dark, blurry, or heavily shadowed photos.',
      ),
      (
        Icons.no_photography_outlined,
        'No heavy filters',
        'Light edits are fine but avoid heavy filters that alter your appearance. Authenticity matters.',
      ),
      (
        Icons.do_not_disturb_alt_outlined,
        'Skip the sunglasses',
        'Your eyes matter. Remove sunglasses and avoid anything that covers your face.',
      ),
      (
        Icons.photo_library_outlined,
        'Show variety',
        'Mix it up — a close-up portrait, a candid smile, a full-length shot. Let your personality shine.',
      ),
      (
        Icons.history_outlined,
        'Keep it recent',
        'Use photos taken within the last year. People appreciate knowing what you look like today.',
      ),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'How to pick great photos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Follow these tips for the best first impression.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  controller: ctrl,
                  itemCount: tips.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 28, color: AppColors.borderColor),
                  itemBuilder: (_, i) {
                    final (icon, title, desc) = tips[i];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon,
                              size: 20, color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                desc,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
