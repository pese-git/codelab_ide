// Переиспользуемое поле ввода пароля
import 'package:fluent_ui/fluent_ui.dart';
import '../../theme/app_theme.dart';

/// Поле ввода пароля с возможностью показать/скрыть пароль
class PasswordInputField extends StatefulWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final String? label;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool autofocus;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  const PasswordInputField({
    super.key,
    this.controller,
    this.placeholder,
    this.label,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final field = TextFormBox(
      controller: widget.controller,
      placeholder: widget.placeholder ?? '••••••••',
      obscureText: _obscureText,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      suffix: IconButton(
        icon: Icon(
          _obscureText ? FluentIcons.red_eye : FluentIcons.hide,
          size: AppSpacing.iconSm,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );

    if (widget.label != null) {
      return InfoLabel(
        label: widget.label!,
        child: field,
      );
    }

    return field;
  }
}
