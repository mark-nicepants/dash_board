import 'package:dash_board/src/components/partials/forms/form_styles.dart';
import 'package:jaspr/jaspr.dart';

/// A wrapper for input fields with prefix/suffix adornments.
///
/// This component wraps an input with optional prefix and suffix
/// elements (text or icons).
///
/// Example:
/// ```dart
/// InputAdornmentWrapper(
///   prefix: InputAdornmentText(text: 'https://'),
///   suffix: InputAdornmentIcon(icon: Icon(Icons.search)),
///   child: FormInput(name: 'website', hasAdornments: true),
/// )
/// ```
class InputAdornmentWrapper extends StatelessComponent {
  /// The input component to wrap.
  final Component child;

  /// Optional prefix adornment.
  final Component? prefix;

  /// Optional suffix adornment.
  final Component? suffix;

  /// Custom CSS classes to add to the wrapper.
  final String? customClasses;

  const InputAdornmentWrapper({required this.child, this.prefix, this.suffix, this.customClasses, super.key});

  @override
  Component build(BuildContext context) {
    final classes = customClasses != null
        ? '${FormStyles.adornmentWrapper} $customClasses'
        : FormStyles.adornmentWrapper;

    return div(classes: classes, [
      if (prefix != null) prefix!,
      div(classes: FormStyles.adornmentContent, [child]),
      if (suffix != null) suffix!,
    ]);
  }
}

/// A text adornment for input fields (prefix position).
///
/// Example:
/// ```dart
/// InputAdornmentText(text: 'https://')
/// ```
class InputAdornmentText extends StatelessComponent {
  /// The text to display.
  final String adornmentText;

  /// Whether this is a suffix (changes border side).
  final bool isSuffix;

  const InputAdornmentText({required this.adornmentText, this.isSuffix = false, super.key});

  @override
  Component build(BuildContext context) {
    final classes = isSuffix ? FormStyles.adornmentTextSuffix : FormStyles.adornmentText;

    return span(classes: classes, [text(adornmentText)]);
  }
}

/// An icon adornment for input fields.
///
/// Example:
/// ```dart
/// InputAdornmentIcon(icon: HeroIcon(HeroIcons.search))
/// ```
class InputAdornmentIcon extends StatelessComponent {
  /// The icon component to display.
  final Component icon;

  /// Whether this is a suffix (changes border side).
  final bool isSuffix;

  const InputAdornmentIcon({required this.icon, this.isSuffix = false, super.key});

  @override
  Component build(BuildContext context) {
    final classes = isSuffix ? FormStyles.adornmentIconSuffix : FormStyles.adornmentIcon;

    return span(classes: classes, [icon]);
  }
}

/// Builder helper for creating inputs with adornments.
///
/// Use this to conditionally wrap an input with adornments only when needed.
///
/// Example:
/// ```dart
/// InputWithAdornments.build(
///   input: FormInput(name: 'price'),
///   prefixText: '\$',
///   suffixText: '.00',
/// )
/// ```
class InputWithAdornments {
  InputWithAdornments._();

  /// Builds an input component, optionally wrapping with adornments.
  ///
  /// If no adornments are provided, returns the input directly.
  /// Otherwise, wraps the input in an [InputAdornmentWrapper].
  static Component build({
    required Component input,
    String? prefixText,
    String? suffixText,
    Component? prefixIcon,
    Component? suffixIcon,
  }) {
    final hasAdornments = prefixText != null || suffixText != null || prefixIcon != null || suffixIcon != null;

    if (!hasAdornments) {
      return input;
    }

    Component? prefix;
    if (prefixText != null) {
      prefix = InputAdornmentText(adornmentText: prefixText);
    } else if (prefixIcon != null) {
      prefix = InputAdornmentIcon(icon: prefixIcon);
    }

    Component? suffix;
    if (suffixText != null) {
      suffix = InputAdornmentText(adornmentText: suffixText, isSuffix: true);
    } else if (suffixIcon != null) {
      suffix = InputAdornmentIcon(icon: suffixIcon, isSuffix: true);
    }

    return InputAdornmentWrapper(prefix: prefix, suffix: suffix, child: input);
  }
}
