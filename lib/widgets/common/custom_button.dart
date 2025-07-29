import 'package:exfactor/utils/colors.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Icon? icon;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final double? borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined
              ? kPrimaryColor
              : (backgroundColor ?? theme.primaryColor),
          foregroundColor:
              isOutlined ? theme.primaryColor : (textColor ?? Colors.white),
          padding: padding ??
              const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                borderRadius ?? AppConstants.defaultRadius),
            side: isOutlined
                ? BorderSide(color: theme.primaryColor)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 30),
                  ],
                  Text(
                    text,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isOutlined
                          ? theme.primaryColor
                          : (textColor ?? Colors.white),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
