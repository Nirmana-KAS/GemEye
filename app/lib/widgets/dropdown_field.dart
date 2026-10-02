import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'input_field.dart';

/// Labelled select field that opens a white menu under the field.
/// Pass a null [onChanged] to disable it.
class DropdownField<T> extends StatefulWidget {
  final String label;
  final String? labelSuffix;
  final T? value;
  final List<T> items;
  final String Function(T item)? itemLabel;
  final String hintText;
  final String? errorText;
  final ValueChanged<T>? onChanged;

  const DropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.labelSuffix,
    this.itemLabel,
    this.hintText = 'Select',
    this.errorText,
  });

  @override
  State<DropdownField<T>> createState() => _DropdownFieldState<T>();
}

class _DropdownFieldState<T> extends State<DropdownField<T>> {
  final MenuController _menuController = MenuController();
  bool _open = false;

  String _labelOf(T item) => widget.itemLabel?.call(item) ?? item.toString();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;
    final hasError =
        widget.errorText != null && widget.errorText!.isNotEmpty && !_open;
    final hasValue = widget.value != null;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FieldLabel(
            text: widget.label,
            suffix: widget.labelSuffix,
            color: AppFieldStyle.labelColor(
              focused: _open,
              hasError: hasError,
              enabled: enabled,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            return MenuAnchor(
              controller: _menuController,
              alignmentOffset: const Offset(0, AppSpacing.xs),
              onOpen: () => setState(() => _open = true),
              onClose: () => setState(() => _open = false),
              style: MenuStyle(
                backgroundColor: const WidgetStatePropertyAll(AppColors.card),
                surfaceTintColor:
                    const WidgetStatePropertyAll(Colors.transparent),
                shadowColor: const WidgetStatePropertyAll(AppColors.menuShadow),
                elevation: const WidgetStatePropertyAll(8),
                padding:
                    const WidgetStatePropertyAll(EdgeInsets.all(AppSpacing.sm)),
                minimumSize: WidgetStatePropertyAll(Size(width, 0)),
                maximumSize: WidgetStatePropertyAll(Size(width, 320)),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: const BorderSide(color: AppColors.border),
                )),
              ),
              menuChildren: [
                for (final item in widget.items)
                  _MenuOption(
                    label: _labelOf(item),
                    selected: item == widget.value,
                    width: width - AppSpacing.lg,
                    onPressed: () => widget.onChanged?.call(item),
                  ),
              ],
              builder: (context, controller, _) {
                return Material(
                  color: AppFieldStyle.fill(focused: _open, hasError: hasError),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    side: BorderSide(
                      width: 1.5,
                      color: _open
                          ? AppColors.primary
                          : hasError
                              ? AppColors.error
                              : Colors.transparent,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: enabled
                        ? () => controller.isOpen
                            ? controller.close()
                            : controller.open()
                        : null,
                    child: SizedBox(
                      height: AppSpacing.controlHeight,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                hasValue
                                    ? _labelOf(widget.value as T)
                                    : widget.hintText,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body14.copyWith(
                                  color: hasValue && enabled
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                            Icon(
                              _open
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 22,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          if (hasError) ...[
            const SizedBox(height: AppSpacing.sm),
            FieldErrorText(widget.errorText!),
          ],
        ],
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final String label;
  final bool selected;
  final double width;
  final VoidCallback onPressed;

  const _MenuOption({
    required this.label,
    required this.selected,
    required this.width,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(width, 44)),
        padding:
            const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm))),
        overlayColor: const WidgetStatePropertyAll(AppColors.surface),
        backgroundColor: WidgetStatePropertyAll(
            selected ? AppColors.surface : Colors.transparent),
      ),
      child: SizedBox(
        width: width - 20,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: selected
                    ? AppText.titleSmall.copyWith(color: AppColors.primary)
                    : AppText.body14,
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded,
                  size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
