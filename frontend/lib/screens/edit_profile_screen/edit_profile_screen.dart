import 'package:flutter/material.dart';
import 'package:life_partner_again/core/responsive/adaptive_screen.dart';
import 'package:life_partner_again/models/auth_response.dart';
import 'package:life_partner_again/services/user_repository.dart';

import 'mobile/mobile_edit_profile_screen.dart';
import 'web/web_edit_profile_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final User? user;

  const EditProfileScreen({super.key, this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  User? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    if (_user == null) {
      _fetchUser();
    }
  }

  Future<void> _fetchUser() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userRepository = UserRepository();
      final fetchedUser = await userRepository.getUser();
      setState(() {
        _user = fetchedUser;
      });
    } catch (e) {
      debugPrint("Error fetching user in EditProfileScreen: $e");
      // Handle error state appropriately
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AdaptiveScreen(
      mobile: MobileEditProfileScreen(user: _user!),
      web: WebEditProfileScreen(user: _user!),
    );
  }
}
