import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class NumberDecimalFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;
    if (newText.isEmpty) return newValue;

    final cursorPosition = newText.length - newValue.selection.end;
    final numberFormat = NumberFormat.decimalPattern();

    // remove all not digit and not special char
    newText = newText.replaceAll(RegExp(r'[^0-9.,]'), '');

    // remove grouping
    if (newText.contains(numberFormat.symbols.GROUP_SEP)) {
      newText = newText.replaceAll(numberFormat.symbols.GROUP_SEP, '');
    }

    // replace decimal separator with standard `.`
    if (newText.contains(numberFormat.symbols.DECIMAL_SEP)) {
      newText = newText.replaceAll(numberFormat.symbols.DECIMAL_SEP, '.');
    }

    // format number
    if (newText.isNotEmpty) newText = numberFormat.format(num.parse(newText));

    // readd comma if it exist
    if (newValue.text.endsWith(numberFormat.symbols.DECIMAL_SEP)) {
      newText = '$newText${numberFormat.symbols.DECIMAL_SEP}';
    }

    final newOffset = newText.length - cursorPosition;
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newOffset > 0 ? newOffset : 0,
      ),
    );
  }
}
