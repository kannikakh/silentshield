import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom app bar variants for SilentShield application.
/// Implements clean, professional design with contextual actions.
enum CustomAppBarVariant {
  /// Standard app bar with title and optional actions
  standard,

  /// App bar with back button
  withBack,

  /// App bar with search functionality
  withSearch,

  /// Minimal app bar for emergency states
  minimal,

  /// App bar with custom leading widget
  custom,
}

/// Custom app bar widget for consistent navigation and branding.
/// Follows Confident Minimalism design with clean layouts.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title text to display
  final String? title;

  /// App bar variant
  final CustomAppBarVariant variant;

  /// Leading widget (overrides default back button)
  final Widget? leading;

  /// Action widgets
  final List<Widget>? actions;

  /// Whether to show back button automatically
  final bool automaticallyImplyLeading;

  /// Background color (defaults to theme surface color)
  final Color? backgroundColor;

  /// Foreground color (defaults to theme onSurface color)
  final Color? foregroundColor;

  /// Elevation (defaults to 0 for flat design)
  final double elevation;

  /// Whether to center the title
  final bool centerTitle;

  /// Custom bottom widget (e.g., TabBar)
  final PreferredSizeWidget? bottom;

  /// Search callback for search variant
  final ValueChanged<String>? onSearch;

  /// Search hint text
  final String searchHint;

  const CustomAppBar({
    super.key,
    this.title,
    this.variant = CustomAppBarVariant.standard,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0.0,
    this.centerTitle = true,
    this.bottom,
    this.onSearch,
    this.searchHint = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine background and foreground colors
    final bgColor = backgroundColor ?? colorScheme.surface;
    final fgColor = foregroundColor ?? colorScheme.onSurface;

    // Build title widget based on variant
    Widget? titleWidget;
    Widget? leadingWidget = leading;
    List<Widget>? actionWidgets = actions;

    switch (variant) {
      case CustomAppBarVariant.standard:
        titleWidget = title != null
            ? Text(
                title!,
                style: theme.appBarTheme.titleTextStyle?.copyWith(
                  color: fgColor,
                ),
              )
            : null;
        break;

      case CustomAppBarVariant.withBack:
        titleWidget = title != null
            ? Text(
                title!,
                style: theme.appBarTheme.titleTextStyle?.copyWith(
                  color: fgColor,
                ),
              )
            : null;
        if (leadingWidget == null && automaticallyImplyLeading) {
          leadingWidget = IconButton(
            icon: Icon(Icons.arrow_back, color: fgColor),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          );
        }
        break;

      case CustomAppBarVariant.withSearch:
        titleWidget = TextField(
          onChanged: onSearch,
          style: theme.textTheme.bodyLarge?.copyWith(color: fgColor),
          decoration: InputDecoration(
            hintText: searchHint,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: fgColor.withValues(alpha: 0.6),
            ),
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.search,
              color: fgColor.withValues(alpha: 0.6),
            ),
          ),
        );
        break;

      case CustomAppBarVariant.minimal:
        // Minimal variant for emergency states - no title, minimal actions
        titleWidget = null;
        break;

      case CustomAppBarVariant.custom:
        titleWidget = title != null
            ? Text(
                title!,
                style: theme.appBarTheme.titleTextStyle?.copyWith(
                  color: fgColor,
                ),
              )
            : null;
        break;
    }

    return AppBar(
      title: titleWidget,
      leading: leadingWidget,
      actions: actionWidgets,
      automaticallyImplyLeading:
          automaticallyImplyLeading && leadingWidget == null,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: elevation,
      centerTitle: centerTitle,
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: theme.brightness,
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
