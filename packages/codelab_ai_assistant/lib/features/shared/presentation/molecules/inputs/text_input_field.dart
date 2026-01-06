// Переиспользуемое поле ввода текста
import 'package:fluent_ui/fluent_ui.dart';
import '../../theme/app_theme.dart';

/// Переиспользуемое поле ввода текста с консистентным стилем
/// 
/// Поддерживает валидацию, placeholder, иконки и различные состояния
class TextInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final String? label;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  const TextInputField({
    super.key,
    this.controller,
    this.placeholder,
    this.label,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextFormBox(
      controller: controller,
      placeholder: placeholder,
      enabled: enabled,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      prefix: prefix,
      suffix: suffix,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
    );

    if (label != null) {
      return InfoLabel(
        label: label!,
        child: field,
      );
    }

    return field;
  }
}
