// lib/core/widgets/vibe_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class VibeTextField extends StatefulWidget {
  const VibeTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onFieldSubmitted,
    this.autovalidateMode,
    this.textInputAction,
    this.focusNode,
    this.inputFormatters,
    this.showCounter = false,
    this.enabled = true,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.isPassword = false,
    this.onSubmitted,
    this.textAlignVertical,
    this.contentPadding,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final AutovalidateMode? autovalidateMode;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final bool showCounter;
  final bool enabled;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final bool isPassword;
  final ValueChanged<String>? onSubmitted;
  final TextAlignVertical? textAlignVertical;
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<VibeTextField> createState() => _VibeTextFieldState();
}

class _VibeTextFieldState extends State<VibeTextField> {
  late FocusNode _focusNode;
  bool _hasFocus = false;
  bool _obscureText = false;
  String? _errorText;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.obscureText || widget.isPassword;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    }
  }

  void _toggleObscure() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMultilineWithIcon =
        widget.maxLines > 1 && widget.prefixIcon != null;

    final textField = TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      textCapitalization: widget.textCapitalization,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      textAlignVertical:
          widget.textAlignVertical ??
          (widget.maxLines > 1
              ? TextAlignVertical.top
              : TextAlignVertical.center),
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
      autovalidateMode:
          widget.autovalidateMode ?? AutovalidateMode.onUserInteraction,
      onChanged: (value) {
        widget.onChanged?.call(value);
        if (widget.validator != null) {
          setState(() {
            _errorText = widget.validator!(value);
            _isValid = _errorText == null && value.isNotEmpty;
          });
        }
      },
      onFieldSubmitted: widget.onFieldSubmitted ?? widget.onSubmitted,
      validator: (value) {
        final error = widget.validator?.call(value);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _errorText = error;
              _isValid = error == null && (value?.isNotEmpty ?? false);
            });
          }
        });
        return error;
      },
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        filled: true,
        isDense: true,
        fillColor: isDark ? AppColors.darkBgTertiary : AppColors.bgSecondary,
        contentPadding:
            widget.contentPadding ??
            EdgeInsets.only(
              // Extra left padding for multiline to make room for the icon
              left: isMultilineWithIcon ? 48 : 16,
              right: 16,
              top: 12,
              bottom: 12,
            ),
        counterText: widget.showCounter ? null : '',
        // Only use prefixIcon for single-line fields
        prefixIcon: (!isMultilineWithIcon && widget.prefixIcon != null)
            ? Container(
                width: 48,
                alignment: Alignment.center,
                child: Icon(
                  widget.prefixIcon,
                  size: 20,
                  color: _hasFocus ? AppColors.primary : AppColors.textHint,
                ),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 48,
        ),
        suffixIcon: _buildSuffixIcon(),
        // Using immediate borders (no internal animation visible)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        // For multiline with icon: use Stack to position icon at top-left
        if (isMultilineWithIcon)
          Stack(
            children: [
              textField,
              Positioned(
                top: 14,
                left: 14,
                child: Icon(
                  widget.prefixIcon,
                  size: 20,
                  color: _hasFocus ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ],
          )
        else
          textField,
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffix != null) return widget.suffix;

    final icons = <Widget>[];

    if (_isValid && widget.validator != null) {
      icons.add(
        const Icon(
          Icons.check_circle_rounded,
          size: 20,
          color: AppColors.success,
        ),
      );
    }

    if (widget.obscureText || widget.isPassword) {
      icons.add(
        GestureDetector(
          onTap: _toggleObscure,
          child: Icon(
            _obscureText
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            size: 20,
            color: AppColors.textHint,
          ),
        ),
      );
    }

    if (widget.suffixIcon != null &&
        !(widget.obscureText || widget.isPassword)) {
      icons.add(
        Icon(
          widget.suffixIcon,
          size: 20,
          color: _hasFocus ? AppColors.primary : AppColors.textHint,
        ),
      );
    }

    if (icons.isEmpty) return null;
    if (icons.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: icons.first,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: icons
            .map(
              (icon) =>
                  Padding(padding: const EdgeInsets.only(left: 8), child: icon),
            )
            .toList(),
      ),
    );
  }
}
