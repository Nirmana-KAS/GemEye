import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'input_field.dart';

/// One password requirement shown under a [PasswordField].
class PasswordRule {
  final String label;
  final bool Function(String value) test;

  const PasswordRule(this.label, this.test);

  /// GemEye registration rules: 8+ characters, 1 uppercase, 1 number.
  static final List<PasswordRule> registration = [
    PasswordRule('At least 8 characters', (v) => v.length >= 8),
    PasswordRule('1 uppercase letter', (v) => v.contains(RegExp(r'[A-Z]'))),
    PasswordRule('1 number', (v) => v.contains(RegExp(r'\d'))),
  ];

  static bool allPass(List<PasswordRule> rules, String value) =>
      rules.every((r) => r.test(value));
}

/// [InputField] with a show/hide toggle and an optional live rule checklist.
class PasswordField extends StatefulWidget {
  final String label;
  final String? labelSuffix;
  final TextEditingController controller;
  final String? hintText;
  final String? errorText;
  final bool showErrorIcon;
  final List<PasswordRule>? rules;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.labelSuffix,
    this.hintText = 'Password',
    this.errorText,
    this.showErrorIcon = false,
    this.rules,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    if (widget.rules != null) widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final rules = widget.rules;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    final input = InputField(
      label: widget.label,
      labelSuffix: widget.labelSuffix,
      controller: widget.controller,
      hintText: widget.hintText,
      obscureText: _obscured,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      // Error text is rendered below the rule list instead.
      errorText: rules == null ? widget.errorText : (hasError ? '' : null),
      showErrorIcon: widget.showErrorIcon,
      suffix: IconButton(
        tooltip: _obscured ? 'Show password' : 'Hide password',
        iconSize: 20,
        color: AppColors.textSecondary,
        style: IconButton.styleFrom(
          minimumSize: const Size(40, 40),
          highlightColor: AppColors.surface,
        ),
        icon: Icon(_obscured
            ? Icons.visibility_rounded
            : Icons.visibility_off_rounded),
        onPressed: () => setState(() => _obscured = !_obscured),
      ),
    );

    if (rules == null) return input;

    final value = widget.controller.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        input,
        const SizedBox(height: AppSpacing.xs),
        for (final rule in rules)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: _RuleRow(label: rule.label, ok: rule.test(value)),
          ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          FieldErrorText(widget.errorText!),
        ],
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String label;
  final bool ok;

  const _RuleRow({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          ok
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: ok ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppText.caption.copyWith(
            color: ok ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
