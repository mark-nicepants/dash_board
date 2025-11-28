/// Centralized Tailwind CSS class definitions for form components.
///
/// This file contains all the CSS class strings used across form fields,
/// ensuring consistent styling and making it easy to update the design system.
///
/// Example:
/// ```dart
/// input(classes: FormStyles.inputBase)
/// label(classes: FormStyles.label)
/// ```
abstract final class FormStyles {
  // ============================================
  // LABELS
  // ============================================

  /// Base label styling for form fields.
  static const String label = 'block text-sm font-medium text-gray-300';

  /// Required asterisk indicator styling.
  static const String requiredIndicator = 'text-red-500 ml-1';

  /// Hint text displayed next to labels.
  static const String labelHint = 'text-gray-500 ml-2 font-normal';

  // ============================================
  // INPUTS
  // ============================================

  /// Base input field styling with full border radius.
  static const String inputBase =
      'w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-gray-100 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-lime-500 focus:border-transparent transition-all disabled:opacity-50 disabled:cursor-not-allowed';

  /// Input field styling without border (for use inside adornment wrapper).
  static const String inputBaseNoBorder =
      'w-full px-3 py-2 bg-gray-700 text-gray-100 placeholder-gray-400 focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed';

  /// Textarea styling.
  static const String textarea =
      'w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-gray-100 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-lime-500 focus:border-transparent transition-all disabled:opacity-50 disabled:cursor-not-allowed';

  /// Select/dropdown styling.
  static const String select =
      'w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-gray-100 focus:outline-none focus:ring-2 focus:ring-lime-500 focus:border-transparent transition-all disabled:opacity-50 disabled:cursor-not-allowed appearance-none cursor-pointer';

  /// Checkbox styling.
  static const String checkbox =
      'w-4 h-4 bg-gray-700 border-gray-600 rounded text-lime-500 focus:ring-2 focus:ring-lime-500 focus:ring-offset-0 cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed';

  // ============================================
  // HELPER TEXT & DESCRIPTIONS
  // ============================================

  /// Helper text displayed below inputs.
  static const String helperText = 'text-sm text-gray-400';

  /// Character count text styling.
  static const String characterCount = 'text-xs text-gray-500';

  /// Character count aligned to the right.
  static const String characterCountRight = 'text-xs text-gray-500 text-right';

  // ============================================
  // FIELD CONTAINERS
  // ============================================

  /// Standard field wrapper with vertical spacing.
  static const String fieldWrapper = 'space-y-2';

  /// Horizontal flex container for checkbox/toggle layouts.
  static const String fieldWrapperInline = 'flex items-start gap-3';

  /// Container for checkbox input element.
  static const String checkboxContainer = 'flex items-center h-5';

  /// Label for inline checkbox fields.
  static const String checkboxLabel = 'text-sm text-gray-300 cursor-pointer select-none';

  // ============================================
  // INPUT ADORNMENTS (PREFIX/SUFFIX)
  // ============================================

  /// Wrapper for inputs with prefix/suffix adornments.
  static const String adornmentWrapper =
      'flex rounded-lg overflow-hidden border border-gray-600 focus-within:ring-2 focus-within:ring-lime-500 focus-within:border-transparent';

  /// Text prefix/suffix styling.
  static const String adornmentText =
      'inline-flex items-center px-3 bg-gray-700 text-gray-400 text-sm border-r border-gray-600';

  /// Icon prefix/suffix styling.
  static const String adornmentIcon =
      'inline-flex items-center px-3 bg-gray-700 text-gray-400 border-r border-gray-600';

  /// Text suffix styling (border on left instead of right).
  static const String adornmentTextSuffix =
      'inline-flex items-center px-3 bg-gray-700 text-gray-400 text-sm border-l border-gray-600';

  /// Icon suffix styling (border on left instead of right).
  static const String adornmentIconSuffix =
      'inline-flex items-center px-3 bg-gray-700 text-gray-400 border-l border-gray-600';

  /// Flexible content area within adornment wrapper.
  static const String adornmentContent = 'flex-1';

  // ============================================
  // TOGGLE SWITCH
  // ============================================

  /// Toggle switch container.
  static const String toggleContainer = 'relative inline-flex cursor-pointer';

  /// Toggle switch label text.
  static const String toggleLabel = 'text-sm font-medium text-gray-300';

  /// Toggle switch secondary label (on/off text).
  static const String toggleStateLabel = 'text-sm text-gray-400';

  /// Toggle background (off state).
  static const String toggleBackground = 'bg-gray-600 rounded-full peer transition-colors duration-200';

  /// Toggle knob.
  static const String toggleKnob =
      'absolute top-0.5 left-0.5 bg-white rounded-full shadow-md transition-transform duration-200';

  // ============================================
  // FORM ACTIONS
  // ============================================

  /// Form actions container (buttons row).
  static const String formActions = 'flex items-center justify-start gap-3 pt-4 pb-4';

  /// Primary submit button.
  static const String buttonPrimary =
      'px-4 py-2 text-sm font-medium text-white bg-lime-500 hover:bg-lime-600 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed';

  /// Secondary/cancel button.
  static const String buttonSecondary =
      'px-4 py-2 text-sm font-medium text-gray-300 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors';

  // ============================================
  // ERRORS & VALIDATION
  // ============================================

  /// Error message list styling.
  static const String errorList = 'mt-2 text-sm text-red-400 list-disc list-inside';

  /// Input error state styling (add to input classes).
  static const String inputError = 'border-red-500 focus:ring-red-500';

  // ============================================
  // SELECT OPTIONS
  // ============================================

  /// Option group styling.
  static const String optgroup = 'bg-gray-800 text-gray-100';

  /// Placeholder option styling.
  static const String placeholderOption = 'text-gray-400';

  // ============================================
  // TOGGLE SIZE CLASSES
  // ============================================

  /// Toggle size: small (w-8 = 32px track, w-3 = 12px knob).
  static const (String, String, String, String) toggleSizeSm = ('w-8', 'h-4', 'w-3 h-3', 'translate-x-4');

  /// Toggle size: medium (w-11 = 44px track, w-5 = 20px knob).
  static const (String, String, String, String) toggleSizeMd = ('w-11', 'h-6', 'w-5 h-5', 'translate-x-5');

  /// Toggle size: large (w-14 = 56px track, w-6 = 24px knob).
  static const (String, String, String, String) toggleSizeLg = ('w-14', 'h-7', 'w-6 h-6', 'translate-x-7');

  // ============================================
  // TEXTAREA RESIZE
  // ============================================

  /// Textarea resize: none.
  static const String resizeNone = 'resize-none';

  /// Textarea resize: vertical only.
  static const String resizeVertical = 'resize-y';

  /// Textarea resize: horizontal only.
  static const String resizeHorizontal = 'resize-x';

  /// Textarea resize: both directions.
  static const String resizeBoth = 'resize';

  // ============================================
  // UTILITY METHODS
  // ============================================

  /// Combines the field wrapper class with optional extra classes.
  static String wrapperClasses([String? extraClasses]) {
    if (extraClasses == null || extraClasses.isEmpty) {
      return fieldWrapper;
    }
    return '$fieldWrapper $extraClasses'.trim();
  }

  /// Returns the appropriate toggle size classes.
  static (String width, String height, String knobSize, String translateX) getToggleSize(String size) {
    return switch (size) {
      'sm' => toggleSizeSm,
      'lg' => toggleSizeLg,
      _ => toggleSizeMd,
    };
  }

  /// Returns the resize class for textarea.
  static String getResizeClass(String resize) {
    return switch (resize) {
      'none' => resizeNone,
      'horizontal' => resizeHorizontal,
      'both' => resizeBoth,
      _ => resizeVertical,
    };
  }
}
