import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Row of dots showing how many PIN digits have been entered.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.length, required this.filled, this.error = false});

  final int length;
  final int filled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(length, (i) {
        final on = i < filled;
        return Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? (error ? p.debit : p.accent) : Colors.transparent,
            border: Border.all(color: error ? p.debit : (on ? p.accent : p.textMuted), width: 1.5),
          ),
        );
      }),
    );
  }
}

/// 0-9 keypad with backspace. The parent owns the entered value.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.value,
    required this.length,
    required this.onChanged,
  });

  final String value;
  final int length;
  final ValueChanged<String> onChanged;

  void _digit(String d) {
    if (value.length < length) onChanged(value + d);
  }

  void _back() {
    if (value.isNotEmpty) onChanged(value.substring(0, value.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    Widget row(List<String> keys) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: keys.map((k) {
              if (k.isEmpty) return const SizedBox(width: 68, height: 68);
              if (k == '<') {
                return _PadKey(
                  semanticLabel: 'Delete',
                  onTap: _back,
                  child: const Icon(Icons.backspace_outlined, size: 22),
                );
              }
              return _PadKey(
                semanticLabel: k,
                onTap: () => _digit(k),
                child: Text(k, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              );
            }).toList(),
          ),
        );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          row(<String>['1', '2', '3']),
          row(<String>['4', '5', '6']),
          row(<String>['7', '8', '9']),
          row(<String>['', '0', '<']),
        ],
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({required this.child, required this.onTap, required this.semanticLabel});

  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: p.surface,
        shape: CircleBorder(side: BorderSide(color: p.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 68,
            height: 68,
            child: DefaultTextStyle.merge(
              style: TextStyle(color: p.textPrimary),
              child: IconTheme.merge(
                data: IconThemeData(color: p.textPrimary),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
