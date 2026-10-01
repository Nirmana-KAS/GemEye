import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

/// Label shown above every form control: "Email *", "Phone · Optional".
class FieldLabel extends StatelessWidget {
  final String text;
  final String? suffix;
  final Color color;

  const FieldLabel({
    super.key,
    required this.text,
    this.suffix,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: AppText.label.copyWith(color: color),
        children: [
          if (suffix != null)
            TextSpan(
              text: suffix,
              style: AppText.label.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }
}

/// Red helper line under a field.
class FieldErrorText extends StatelessWidget {
  final String message;
  final bool showIcon;

  const FieldErrorText(this.message, {super.key, this.showIcon = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showIcon) ...[
          const Icon(Icons.error_rounded, size: 14, color: AppColors.error),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            message,
            style: AppText.caption.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}

/// Shared look for the filled, rounded GemEye fields.
class AppFieldStyle {
  static OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: color, width: 1.5),
      );

  static Color fill({required bool focused, required bool hasError}) =>
      focused || hasError ? AppColors.background : AppColors.surface;

  static Color labelColor({
    required bool focused,
    required bool hasError,
    bool enabled = true,
  }) {
    if (!enabled) return AppColors.textMuted;
    if (hasError) return AppColors.error;
    if (focused) return AppColors.primary;
    return AppColors.textSecondary;
  }
}

/// Labelled text input. Filled Primary Surface by default, white with a
/// Royal Blue border when focused, white with a red border on error.
/// Set [locked] for values that come from another source (e.g. Google).
class InputField extends StatefulWidget {
  final String label;
  final String? labelSuffix;
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final bool showErrorIcon;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final bool enabled;
  final bool locked;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const InputField({
    super.key,
    required this.label,
    this.labelSuffix,
    this.controller,
    this.hintText,
    this.errorText,
    this.showErrorIcon = false,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.enabled = true,
    this.locked = false,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  FocusNode? _ownFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant InputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // An empty errorText gives error styling without a message line.
    final hasError = widget.errorText != null;
    final focused = _focusNode.hasFocus && !widget.locked;
    final editable = widget.enabled && !widget.locked;

    Widget? suffix = widget.suffix;
    if (widget.locked) {
      suffix = const Icon(Icons.lock_rounded,
          size: 18, color: AppColors.textMuted);
    } else if (hasError && suffix == null && widget.showErrorIcon) {
      suffix = const Icon(Icons.error_rounded,
          size: 20, color: AppColors.error);
    }

    final field = TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      readOnly: widget.locked,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: editable ? widget.autofillHints : null,
      inputFormatters: widget.inputFormatters,
      textCapitalization: widget.textCapitalization,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.maxLines > 1 ? widget.maxLines : null,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: AppText.body14.copyWith(
        height: widget.maxLines > 1 ? 1.45 : 1.2,
        color: widget.locked || !widget.enabled
            ? AppColors.textSecondary
            : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppFieldStyle.fill(focused: focused, hasError: hasError),
        hintText: widget.hintText,
        hintStyle: AppText.body14
            .copyWith(height: 1.2, color: AppColors.textMuted),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: widget.maxLines > 1 ? AppSpacing.lg : 15,
        ),
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(widget.prefixIcon, size: 20, color: AppColors.textSecondary),
        suffixIcon: suffix,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 40),
        enabledBorder: AppFieldStyle.border(
            hasError ? AppColors.error : Colors.transparent),
        disabledBorder: AppFieldStyle.border(Colors.transparent),
        focusedBorder: AppFieldStyle.border(widget.locked
            ? Colors.transparent
            : hasError
                ? AppColors.error
                : AppColors.primary),
        border: AppFieldStyle.border(Colors.transparent),
      ),
    );

    return Opacity(
      opacity: widget.enabled ? 1 : 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FieldLabel(
            text: widget.label,
            suffix: widget.locked ? ' · From Google' : widget.labelSuffix,
            color: AppFieldStyle.labelColor(
              focused: focused,
              hasError: hasError,
              enabled: widget.enabled,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          field,
          if (hasError && widget.errorText!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            FieldErrorText(widget.errorText!, showIcon: widget.showErrorIcon),
          ],
        ],
      ),
    );
  }
}
