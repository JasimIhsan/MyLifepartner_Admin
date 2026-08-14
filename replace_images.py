import os
import re

files_to_update = [
    "frontend/lib/screens/profile_screen/web/web_profile_screen.dart",
    "frontend/lib/screens/edit_profile_screen/mobile/mobile_edit_profile_screen.dart",
    "frontend/lib/screens/edit_profile_screen/web/web_edit_profile_screen.dart",
    "frontend/lib/screens/blocked_users_screen/blocked_users_screen.dart",
    "frontend/lib/screens/landing_screen/landing_screen.dart",
    "frontend/lib/screens/profile_image_upload/widgets/filled_slot.dart",
    "frontend/lib/screens/profile_screen/mobile/mobile_profile_screen.dart",
    "frontend/lib/screens/profile_detail_screen/widgets/profile_image_gallery.dart",
    "frontend/lib/screens/manage_profile_images_screens/widgets/manage_profile_pictures_ui_helpers.dart",
    "frontend/lib/widgets/auth_layout.dart",
    "frontend/lib/widgets/onboarding_background_image.dart",
    "frontend/lib/widgets/incoming_call_overlay.dart",
    "frontend/lib/screens/image_access_screen/image_access_screen.dart",
    "frontend/lib/screens/chat_screen/call_screen.dart",
    "frontend/lib/screens/chat_screen/widgets/chat_detail_app_bar.dart",
    "frontend/lib/screens/chat_screen/outgoing_call_screen.dart"
]

for file in files_to_update:
    path = os.path.join(os.getcwd(), file)
    if not os.path.exists(path):
        print(f"Not found: {file}")
        continue
        
    with open(path, 'r') as f:
        content = f.read()
        
    original = content
    
    # Imports
    content = content.replace("import 'package:cached_network_image/cached_network_image.dart';", "")
    if "CachedNetworkImage" in original or "S3CachedImage" in original or "NetworkImage" in original:
        if "s3_cached_image.dart" not in content:
            # find first import
            import_idx = content.find("import ")
            if import_idx != -1:
                content = content[:import_idx] + "import 'package:life_partner_again/widgets/s3_cached_image.dart';\n" + content[import_idx:]
    
    # CachedNetworkImage widget
    content = content.replace("CachedNetworkImage(", "S3CachedImage(")
    # NetworkImage provider
    content = content.replace("NetworkImage(", "S3CachedImageProvider(")
    
    if content != original:
        with open(path, 'w') as f:
            f.write(content)
        print(f"Updated {file}")
