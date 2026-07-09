import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/services/image_access_service.dart';

class ImageAccessRequestsScreen extends StatefulWidget {
  const ImageAccessRequestsScreen({super.key});

  @override
  State<ImageAccessRequestsScreen> createState() =>
      _ImageAccessRequestsScreenState();
}

class _ImageAccessRequestsScreenState extends State<ImageAccessRequestsScreen> {
  List<dynamic> _receivedRequests = [];
  List<dynamic> _sentRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    final received = await ImageAccessService.getReceivedRequests();
    final sent = await ImageAccessService.getSentRequests();
    if (mounted) {
      setState(() {
        _receivedRequests = received;
        _sentRequests = sent;
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(int requestId) async {
    final success = await ImageAccessService.approveRequest(requestId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request approved successfully')),
      );
      _fetchRequests();
    }
  }

  Future<void> _rejectRequest(int requestId) async {
    final success = await ImageAccessService.rejectRequest(requestId);
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request rejected')));
      _fetchRequests();
    }
  }

  Future<void> _cancelRequest(int requestId) async {
    final success = await ImageAccessService.cancelRequest(requestId);
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request cancelled')));
      _fetchRequests();
    }
  }

  Future<void> _revokeRequest(int requestId) async {
    final success = await ImageAccessService.revokeRequest(requestId);
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Access revoked successfully')));
      _fetchRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
          title: const Text(
            'Image Access Requests',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : TabBarView(children: [_buildReceivedTab(), _buildSentTab()]),
      ),
    );
  }

  Widget _buildReceivedTab() {
    if (_receivedRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.lock_person_outlined,
        title: 'No Incoming Requests',
        subtitle:
            'When other users request to view your private images, they will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _receivedRequests.length,
      itemBuilder: (context, index) {
        final req = _receivedRequests[index];
        final profile = req['requesterProfile'] ?? {};
        final name = profile['name'] ?? 'Unknown User';
        final age = profile['age'];
        final avatarUrl = profile['imageUrl'];
        final status = req['status'] as String;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderColor, width: 1),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, color: Colors.grey, size: 28)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        age != null ? '$name, $age' : name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status == 'PENDING'
                            ? 'Wants to view your images'
                            : 'Status: $status',
                        style: TextStyle(
                          fontSize: 13,
                          color: status == 'PENDING'
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: status == 'PENDING'
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (status == 'PENDING') ...[
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    onPressed: () => _approveRequest(req['id']),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    onPressed: () => _rejectRequest(req['id']),
                  ),
                ] else ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (status == 'APPROVED') ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.block_flipped,
                              color: Colors.red,
                              size: 16,
                            ),
                          ),
                          onPressed: () => _revokeRequest(req['id']),
                          tooltip: 'Revoke Access',
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentTab() {
    if (_sentRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.send_to_mobile_outlined,
        title: 'No Sent Requests',
        subtitle:
            'When you request access to view other private profiles, they will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sentRequests.length,
      itemBuilder: (context, index) {
        final req = _sentRequests[index];
        final profile = req['ownerProfile'] ?? {};
        final name = profile['name'] ?? 'Unknown User';
        final age = profile['age'];
        final avatarUrl = profile['imageUrl'];
        final status = req['status'] as String;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderColor, width: 1),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, color: Colors.grey, size: 28)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        age != null ? '$name, $age' : name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            status,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (status == 'PENDING')
                  TextButton(
                    onPressed: () => _cancelRequest(req['id']),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
