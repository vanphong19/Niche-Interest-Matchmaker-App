// lib/core/widgets/vibe_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

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

  @override
  State<VibeTextField> createState() => _VibeTextFieldState();
}

class _VibeTextFieldState extends State<VibeTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animController;
  late Animation<double> _labelAnimation;
  bool _hasFocus = false;
  bool _obscureText = false;
  String? _errorText;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.obscureText;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _labelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
      if (_hasFocus) {
        _animController.forward();
      } else {
        if (widget.controller?.text.isEmpty ?? true) {
          _animController.reverse();
        }
      }
    });
  }

  void _toggleObscure() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          AnimatedBuilder(
            animation: _labelAnimation,
            builder: (context, child) {
              return Text(
                widget.label!,
                style: AppTextStyles.inputLabel.copyWith(
                  color: _hasFocus
                      ? AppColors.primary
                      : _errorText != null
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
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
          style: AppTextStyles.inputText,
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
          onFieldSubmitted: widget.onFieldSubmitted,
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
            counterText: widget.showCounter ? null : '',
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: _hasFocus ? AppColors.primary : AppColors.textHint,
                  )
                : null,
            suffixIcon: _buildSuffixIcon(),
          ),
        ),
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

    if (widget.obscureText) {
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

    if (widget.suffixIcon != null && !widget.obscureText) {
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
