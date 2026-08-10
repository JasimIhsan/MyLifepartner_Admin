import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:life_partner_again/services/block_service.dart';
import 'package:life_partner_again/widgets/bottomsheet/block_confirmation_bottom_sheet.dart';
import 'package:life_partner_again/widgets/custom_button.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final BlockService _blockService = BlockService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<dynamic> _blockedUsers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchBlockedUsers();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBlockedUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final users = await _blockService.getBlockedUsers();
      if (mounted) {
        setState(() {
          _blockedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  List<dynamic> get _filteredUsers {
    if (_searchQuery.isEmpty) return _blockedUsers;
    return _blockedUsers.where((user) {
      final targetUser = user['targetUser'];
      final name = (targetUser['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color ?? Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Blocked Users',
          style: TextStyle(
            color:
                Theme.of(context).textTheme.titleLarge?.color ?? Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search blocked users',
                    hintStyle: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.grey,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).iconTheme.color ?? Colors.grey,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),

            // Header Text
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Text(
                  '${_blockedUsers.length} Blocked Users',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                  ? Center(
                      child: Text(
                        'No blocked users found',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final targetUser = user['targetUser'];
                        final name = targetUser['name'] ?? 'Unknown User';

                        // Try to get profile picture
                        final profile = targetUser['profile'];
                        final avatarUrl = profile != null
                            ? profile['selfieUrl']
                            : null;

                        // Date formatting
                        final createdAt = user['createdAt'];
                        String dateStr = '';
                        if (createdAt != null) {
                          try {
                            final date = DateTime.parse(createdAt).toLocal();
                            dateStr = DateFormat('dd MMM yyyy').format(date);
                          } catch (e) {
                            // Ignore parse error
                          }
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          leading: ClipOval(
                            child:
                                avatarUrl != null &&
                                    avatarUrl.toString().isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: avatarUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Theme.of(
                                        context,
                                      ).dividerColor.withValues(alpha: 0.1),
                                      width: 50,
                                      height: 50,
                                      child: Icon(
                                        Icons.person,
                                        color:
                                            Theme.of(context).iconTheme.color ??
                                            Colors.grey,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          color: Theme.of(
                                            context,
                                          ).dividerColor.withValues(alpha: 0.1),
                                          width: 50,
                                          height: 50,
                                          child: Icon(
                                            Icons.person,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).iconTheme.color ??
                                                Colors.grey,
                                          ),
                                        ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.person,
                                      color:
                                          Theme.of(context).iconTheme.color ??
                                          Colors.grey,
                                    ),
                                  ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Blocked on $dateStr',
                              style: TextStyle(
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color ??
                                    Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          trailing: CustomButton(
                            text: 'Unblock',
                            onPressed: () {
                              BlockConfirmationBottomSheet.show(
                                context: context,
                                isBlocking: false,
                                userName: name,
                                onConfirm: () async {
                                  await _blockService.unblockUser(
                                    targetUser['id'],
                                  );
                                },
                                onSuccess: () {
                                  _fetchBlockedUsers();
                                },
                              );
                            },
                            type: CustomButtonType.outline,
                            width: 110,
                            height: 36,
                            fontSize: 13,
                            textColor: const Color(0xFFFF5252),
                            backgroundColor: const Color(0xFFFF5252),
                            borderRadius: 8.0,
                          ),
                        );
                      },
                    ),
            ),

            // Footer Text
            if (!_isLoading && _blockedUsers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
                child: Center(
                  child: Text(
                    'You can unblock a user anytime.',
                    style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
