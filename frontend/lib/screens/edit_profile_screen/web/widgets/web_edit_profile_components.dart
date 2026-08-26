import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';

// ─── Web Section Card ───────────────────────────────────────────────────────

class WebSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const WebSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
          // Section Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── Web Form Field Container ───────────────────────────────────────────────

class WebFormFieldContainer extends StatelessWidget {
  final String label;
  final String? helperText;
  final Widget child;
  final bool isRequired;

  const WebFormFieldContainer({
    super.key,
    required this.label,
    this.helperText,
    required this.child,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        if (helperText != null) ...[
          const SizedBox(height: 2),
          Text(
            helperText!,
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

// ─── Web Text Input ─────────────────────────────────────────────────────────

class WebTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final int minLines;
  final int maxLines;

  const WebTextInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      minLines: minLines,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: theme.textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 14,
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          fontWeight: FontWeight.normal,
        ),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                size: 18,
                color: theme.textTheme.bodySmall?.color,
              )
            : null,
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: minLines > 1 ? 14 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.7),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}

// ─── Web Clickable Picker Field ─────────────────────────────────────────────

class WebClickablePickerField extends StatelessWidget {
  final String? value;
  final String hintText;
  final IconData prefixIcon;
  final VoidCallback onTap;
  final Widget? trailingBadge;
  final Widget? customLeading;

  const WebClickablePickerField({
    super.key,
    required this.value,
    required this.hintText,
    required this.prefixIcon,
    required this.onTap,
    this.trailingBadge,
    this.customLeading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null && value!.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? theme.primaryColor.withValues(alpha: 0.4)
                : theme.dividerColor.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          children: [
            if (customLeading != null) ...[
              customLeading!,
              const SizedBox(width: 10),
            ] else ...[
              Icon(
                prefixIcon,
                size: 18,
                color: hasValue
                    ? theme.primaryColor
                    : theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                hasValue ? value! : hintText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                  color: hasValue
                      ? theme.textTheme.bodyLarge?.color
                      : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailingBadge != null) ...[
              const SizedBox(width: 8),
              trailingBadge!,
            ],
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: theme.textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Web Selectable Option Pill / Card ──────────────────────────────────────

class WebOptionPill<T> extends StatelessWidget {
  final String label;
  final T value;
  final T? selectedValue;
  final IconData? icon;
  final ValueChanged<T> onSelected;

  const WebOptionPill({
    super.key,
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value == selectedValue;

    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.12)
              : theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : theme.dividerColor.withValues(alpha: 0.7),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? theme.primaryColor
                    : theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? theme.primaryColor
                    : theme.textTheme.bodyLarge?.color,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_rounded,
                size: 14,
                color: theme.primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Web Option Grid / Wrap Selector ────────────────────────────────────────

class WebOptionSelectorGroup extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  const WebOptionSelectorGroup({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final val = opt['value'] as String;
        final label = opt['label'] as String;
        final icon = opt['icon'] as IconData?;

        return WebOptionPill<String>(
          label: label,
          value: val,
          selectedValue: selectedValue,
          icon: icon,
          onSelected: onSelected,
        );
      }).toList(),
    );
  }
}
