import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/screens/home_screen/home_screen.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:mylifepartner/shared/widgets/custom_app_bar.dart';
import 'package:mylifepartner/shared/widgets/custom_button.dart';

class ProfileImageUploadScreen extends StatefulWidget {
  const ProfileImageUploadScreen({super.key});

  @override
  State<ProfileImageUploadScreen> createState() =>
      _ProfileImageUploadScreenState();
}

class _ProfileImageUploadScreenState extends State<ProfileImageUploadScreen> {
  final ProfileRepository _repository = ProfileRepository();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  List<dynamic> _images = [];

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final images = await _repository.getUserImages();
      setState(() {
        _images = images;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_images.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 images allowed.')),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        // Upload
        await _repository.uploadImage(image.path);

        // Refresh
        await _fetchImages();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _setPrimaryImage(int imageId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _repository.setPrimaryImage(imageId);
      await _fetchImages();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _removeImage(int imageId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _repository.removeImage(imageId);
      await _fetchImages();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _completeUpload() async {
    if (_images.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload exactly 4 images.')),
      );
      return;
    }

    final hasPrimary = _images.any((img) => img['isPrimary'] == true);
    if (!hasPrimary) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select one primary image.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.completeImageUpload();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _showImageOptions(dynamic image) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (image['isPrimary'] != true)
                ListTile(
                  leading: const Icon(Icons.star, color: AppColors.primary),
                  title: const Text('Set as Primary'),
                  onTap: () {
                    Navigator.pop(context);
                    _setPrimaryImage(image['id']);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Image',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage(image['id']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isValid =
        _images.length == 4 && _images.any((img) => img['isPrimary'] == true);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: "Profile Photos",
        leading: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading && _images.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Upload 4 recent photos of yourself.",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Tap an image to set it as primary or delete it.",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.8,
                                ),
                            itemCount: 4,
                            itemBuilder: (context, index) {
                              if (index < _images.length) {
                                final img = _images[index];
                                final isPrimary = img['isPrimary'] == true;
                                return GestureDetector(
                                  onTap: () => _showImageOptions(img),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: isPrimary
                                              ? Border.all(
                                                  color: AppColors.primary,
                                                  width: 3,
                                                )
                                              : null,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            isPrimary ? 13 : 16,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: img['imageUrl'],
                                            fit: BoxFit.cover,
                                            height: double.infinity,
                                            width: double.infinity,
                                            placeholder: (context, url) =>
                                                const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Center(
                                                      child: Icon(
                                                        Icons.error,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      ),
                                      if (isPrimary)
                                        Positioned(
                                          bottom: 8,
                                          left: 0,
                                          right: 0,
                                          child: Center(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                "Primary",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              } else {
                                return GestureDetector(
                                  onTap: _pickAndUploadImage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.divider,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.add_a_photo,
                                        size: 40,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: CustomButton(
                width: double.infinity,
                height: 50,
                onPressed: _isSaving || !isValid ? null : _completeUpload,
                isLoading: _isSaving,
                text: "Complete",
                backgroundColor: isValid
                    ? AppColors.primary
                    : AppColors.divider,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
