import 'package:flutter/material.dart';

import 'package:mylifepartner/core/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showLeading;
  final Color backgroundColor;
  final double elevation;
  final TextStyle? titleStyle;
  final double toolbarHeight;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showLeading = true,
    this.backgroundColor = AppColors.background,
    this.elevation = 0,
    this.titleStyle,
    this.toolbarHeight = kToolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title:
          titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style:
                      titleStyle ??
                      TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 20,
                      ),
                )
              : null),
      centerTitle: false,
      backgroundColor: backgroundColor,
      elevation: elevation,
      toolbarHeight: toolbarHeight,
      leading: showLeading
          ? (leading ??
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ))
          : null,
      automaticallyImplyLeading: showLeading,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
}
