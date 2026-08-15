import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showLeading;
  final Color? backgroundColor;
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
    this.backgroundColor,
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
                        color:
                            Theme.of(context).appBarTheme.foregroundColor ??
                            Theme.of(context).textTheme.bodyLarge?.color,
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
                  icon: Icon(
                    Icons.arrow_back,
                    color:
                        Theme.of(context).appBarTheme.iconTheme?.color ??
                        Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
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
