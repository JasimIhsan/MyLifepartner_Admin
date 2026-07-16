import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/services/image_access_service.dart';
import 'package:life_partner_again/services/match_service.dart';
import 'package:life_partner_again/widgets/custom_button.dart';

mixin ProfileDetailControllerState<T extends StatefulWidget> on State<T> {
  int? _profileId;
  Map<String, dynamic>? _apiProfile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileId == null) {
      final str = GoRouterState.of(context).pathParameters['profileId'];
      _profileId = int.tryParse(str ?? '0') ?? 0;
      _enrichFromApi();
    }
  }

  Future<void> _enrichFromApi() async {
    try {
      final data = await MatchService.getProfileDetaile(_profileId!);
      if (mounted && data != null) {
        setState(() => _apiProfile = data);
      }
    } catch (_) {}
  }

  Map<String, dynamic> get resolvedProfile {
    return _apiProfile ?? {};
  }

  bool get hasApiData => _apiProfile != null;
}

class RequestAccessButton extends StatefulWidget {
  final int userId;
  final String? imageAccessRequestStatus;

  const RequestAccessButton({
    super.key,
    required this.userId,
    required this.imageAccessRequestStatus,
  });

  @override
  State<RequestAccessButton> createState() => _RequestAccessButtonState();
}

class _RequestAccessButtonState extends State<RequestAccessButton> {
  bool _isLoading = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _status = widget.imageAccessRequestStatus;
  }

  Future<void> _sendRequest() async {
    setState(() {
      _isLoading = true;
    });
    final success = await ImageAccessService.requestAccess(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _status = 'PENDING';
        }
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access request sent successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send access request')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status == 'PENDING') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Access Pending',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    if (_status == 'APPROVED') {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        onPressed: _isLoading ? () {} : _sendRequest,
        text: _isLoading ? 'Sending...' : 'Request Access',
        height: 40,
        borderRadius: 12,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
