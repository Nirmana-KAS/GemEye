import 'package:flutter/material.dart';
import '../config/theme.dart';

enum GemAppBarStyle { primary, surface }

enum GemAppBarLeading { none, back, menu }

/// Top app bar. [GemAppBarStyle.primary] is Royal Blue with white content,
/// [GemAppBarStyle.surface] is white with a bottom border.
class GemAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final GemAppBarStyle style;
  final GemAppBarLeading leading;
  final VoidCallback? onLeadingPressed;
  final List<Widget> actions;

  const GemAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.style = GemAppBarStyle.primary,
    this.leading = GemAppBarLeading.none,
    this.onLeadingPressed,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  bool get _isPrimary => style == GemAppBarStyle.primary;

  @override
  Widget build(BuildContext context) {
    final fg = _isPrimary ? AppColors.onPrimary : AppColors.textPrimary;

    Widget? leadingWidget;
    if (leading != GemAppBarLeading.none) {
      leadingWidget = IconButton(
        iconSize: 24,
        color: fg,
        tooltip: leading == GemAppBarLeading.back ? 'Back' : 'Menu',
        style: IconButton.styleFrom(
          minimumSize:
              const Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
          highlightColor:
              _isPrimary ? AppColors.primaryLight : AppColors.surface,
        ),
        icon: Icon(leading == GemAppBarLeading.back
            ? Icons.arrow_back_rounded
            : Icons.menu_rounded),
        onPressed: onLeadingPressed ??
            (leading == GemAppBarLeading.back
                ? () => Navigator.of(context).maybePop()
                : () => Scaffold.of(context).openEndDrawer()),
      );
    }

    return AppBar(
      toolbarHeight: 56,
      automaticallyImplyLeading: false,
      backgroundColor: _isPrimary ? AppColors.primary : AppColors.background,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle:
          _isPrimary ? AppSystemUi.lightIcons : AppSystemUi.darkIcons,
      shape: _isPrimary
          ? null
          : const Border(bottom: BorderSide(color: AppColors.border)),
      leading: leadingWidget,
      leadingWidth: leadingWidget == null ? 0 : 52,
      titleSpacing: leadingWidget == null ? AppSpacing.screen : AppSpacing.xs,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: AppText.screenTitle.copyWith(
              height: 1.2,
              color: _isPrimary ? AppColors.onPrimary : AppColors.textPrimary,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: AppText.caption.copyWith(
                color: _isPrimary ? AppColors.grade7 : AppColors.textSecondary,
              ),
            ),
        ],
      ),
      actions: actions,
    );
  }
}
