import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../services/finance_calculator.dart';

/// Transparent app bar used by every screen.
class KAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KAppBar({super.key, required this.title, this.actions, this.showBack = true});

  final String title;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: p.background,
      foregroundColor: p.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: showBack,
      actions: actions,
    );
  }
}

InputDecoration kInputDecoration(
  BuildContext context, {
  String? label,
  String? hint,
  IconData? icon,
  Widget? suffix,
  String? prefixText,
}) {
  final p = context.pal;
  OutlineInputBorder border(Color c, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefixText,
    prefixIcon: icon == null ? null : Icon(icon, size: 20),
    prefixIconColor: p.textMuted,
    suffixIcon: suffix,
    filled: true,
    fillColor: p.surface,
    labelStyle: TextStyle(color: p.textSecondary),
    hintStyle: TextStyle(color: p.textMuted),
    prefixStyle: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
    counterText: '',
    errorMaxLines: 2,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(p.border),
    enabledBorder: border(p.border),
    disabledBorder: border(p.border),
    focusedBorder: border(p.accent, 1.6),
    errorBorder: border(p.debit),
    focusedErrorBorder: border(p.debit, 1.6),
  );
}

class KTextField extends StatelessWidget {
  const KTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.prefixText,
    this.suffix,
    this.obscure = false,
    this.autofocus = false,
    this.enabled = true,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final String? prefixText;
  final Widget? suffix;
  final bool obscure;
  final bool autofocus;
  final bool enabled;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      maxLines: obscure ? 1 : maxLines,
      validator: validator,
      autofocus: autofocus,
      enabled: enabled,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      textCapitalization: textCapitalization,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(color: context.pal.textPrimary),
      decoration: kInputDecoration(
        context,
        label: label,
        hint: hint,
        icon: icon,
        suffix: suffix,
        prefixText: prefixText,
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return KTextField(
      controller: widget.controller,
      label: widget.label,
      icon: Icons.lock_outline,
      obscure: _hidden,
      autofocus: widget.autofocus,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      keyboardType: TextInputType.visiblePassword,
      suffix: IconButton(
        tooltip: _hidden ? 'Show password' : 'Hide password',
        icon: Icon(_hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
        onPressed: () => setState(() => _hidden = !_hidden),
      ),
    );
  }
}

/// Amount field: digits and one decimal point, at most 10 whole digits and
/// 2 decimals. Pasted thousands separators are stripped.
class AmountInputFormatter extends TextInputFormatter {
  static final RegExp _valid = RegExp(r'^\d{0,10}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = newValue.text.replaceAll(',', '').replaceAll(' ', '');
    if (!_valid.hasMatch(cleaned)) return oldValue;
    if (cleaned == newValue.text) return newValue;
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}

class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.autofocus = false,
    this.textInputAction,
    this.onChanged,
    this.hint = '0.00',
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return KTextField(
      controller: controller,
      label: label,
      hint: hint,
      prefixText: '\u20B9 ',
      autofocus: autofocus,
      validator: validator,
      onChanged: onChanged,
      textInputAction: textInputAction,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[AmountInputFormatter()],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.danger = false,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool danger;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final base = danger ? p.debit : p.accent;
    final onBase = danger ? Colors.white : p.onAccent;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final VoidCallback? action = loading ? null : onPressed;

    Widget content(Color fg) {
      if (loading) {
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[Icon(icon, size: 20), const SizedBox(width: 8)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
            ),
          ),
        ],
      );
    }

    if (outlined) {
      return OutlinedButton(
        onPressed: action,
        style: OutlinedButton.styleFrom(
          foregroundColor: base,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: base),
          shape: shape,
        ),
        child: content(base),
      );
    }
    return FilledButton(
      onPressed: action,
      style: FilledButton.styleFrom(
        backgroundColor: base,
        foregroundColor: onBase,
        disabledBackgroundColor: base.withValues(alpha: 0.5),
        disabledForegroundColor: onBase.withValues(alpha: 0.7),
        minimumSize: const Size.fromHeight(52),
        shape: shape,
      ),
      child: content(onBase),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final shape = BorderRadius.circular(radius);
    return Material(
      color: color ?? p.surface,
      borderRadius: shape,
      child: InkWell(
        onTap: onTap,
        borderRadius: shape,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(color: borderColor ?? p.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: p.accent),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: p.surfaceAlt, shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: p.accent),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textSecondary, height: 1.4),
            ),
          ],
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 16),
            SizedBox(
              width: 220,
              child: PrimaryButton(label: actionLabel!, onPressed: onAction),
            ),
          ],
        ],
      ),
    );
  }
}

class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({super.key, required this.month, required this.onChanged});

  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final now = DateTime.now();
    final next = FinanceCalculator.addMonths(month, 1);
    final canGoNext = !next.isAfter(DateTime(now.year, now.month));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          tooltip: 'Previous month',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(FinanceCalculator.addMonths(month, -1)),
        ),
        Expanded(
          child: Text(
            Fmt.monthYear(month),
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          icon: const Icon(Icons.chevron_right),
          onPressed: canGoNext ? () => onChanged(next) : null,
        ),
      ],
    );
  }
}

class ChipSelector extends StatelessWidget {
  const ChipSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.iconFor,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;
  final IconData Function(String option)? iconFor;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = o == selected;
        return ChoiceChip(
          label: Text(o),
          avatar: iconFor == null
              ? null
              : Icon(iconFor!(o), size: 18, color: isSelected ? p.onAccent : p.textSecondary),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (_) => onSelected(o),
          selectedColor: p.accent,
          backgroundColor: p.surface,
          side: BorderSide(color: isSelected ? p.accent : p.border),
          labelStyle: TextStyle(
            color: isSelected ? p.onAccent : p.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final color = danger ? p.debit : p.accent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      color: danger ? p.debit : p.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(color: p.textSecondary, fontSize: 12.5, height: 1.3),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}

// ---- navigation guard, dialogs, sheets and snackbars -------------------------

DateTime? _lastOverlayOpened;

/// True when another screen, sheet or dialog was opened a moment ago. Stops a
/// rapid double-tap from stacking two copies of the same thing.
bool _openedTooRecently() {
  final now = DateTime.now();
  final last = _lastOverlayOpened;
  if (last != null && now.difference(last) < const Duration(milliseconds: 450)) return true;
  _lastOverlayOpened = now;
  return false;
}

/// Pushes [screen] unless one was just opened (double-tap protection).
Future<T?> pushOnce<T>(BuildContext context, Widget screen) {
  if (_openedTooRecently()) return Future<T?>.value();
  return Navigator.of(context).push<T>(MaterialPageRoute<T>(builder: (_) => screen));
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  if (_openedTooRecently()) return false;
  final p = context.pal;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700)),
      content: Text(message, style: TextStyle(color: p.textSecondary, height: 1.4)),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancel', style: TextStyle(color: p.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: destructive ? p.debit : p.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<T?> showKSheet<T>(BuildContext context, WidgetBuilder builder) {
  if (_openedTooRecently()) return Future<T?>.value();
  final p = context.pal;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: p.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2)),
          ),
          Flexible(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: builder(ctx),
            ),
          ),
        ],
      ),
    ),
  );
}

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final p = context.pal;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: error ? Colors.white : p.textPrimary),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? p.debit : p.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}

/// Pill used for the All / Credit / Debit and All / Unread tab rows.
class FilterPill extends StatelessWidget {
  const FilterPill({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? p.accent : p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? p.accent : p.border),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? p.onAccent : p.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
