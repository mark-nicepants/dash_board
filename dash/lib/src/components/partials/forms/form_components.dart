/// Form components library for Dash.
///
/// This library exports all the reusable form components for building
/// consistent, maintainable form UIs.
///
/// ## Styles
///
/// Use [FormStyles] for accessing consistent Tailwind CSS classes:
/// ```dart
/// import 'package:dash_board/src/components/partials/forms/form_components.dart';
///
/// input(classes: FormStyles.inputBase)
/// ```
///
/// ## Components
///
/// ### Labels
/// - [FormLabel] - Standard form field label
/// - [RequiredIndicator] - Red asterisk for required fields
/// - [LabelHint] - Hint text inline with label
///
/// ### Helper Text
/// - [FormHelperText] - Helper text below fields
/// - [FormCharacterCount] - Character count indicator
/// - [FormFieldErrors] - Error messages list
/// - [FormHelperRow] - Combined helper text and character count
///
/// ### Field Wrappers
/// - [FormFieldWrapper] - Standard vertical spacing wrapper
/// - [FormFieldWrapperInline] - Horizontal alignment wrapper
/// - [CheckboxInputContainer] - Container for checkbox alignment
/// - [InlineFieldLabel] - Label for inline fields
///
/// ### Inputs
/// - [FormInput] - Text input with all variants
/// - [FormTextarea] - Multi-line text input
/// - [FormSelect] - Dropdown select
/// - [FormCheckbox] - Checkbox input
/// - [FormToggle] - Toggle switch
/// - [FormToggleField] - Complete toggle with label
///
/// ### Adornments
/// - [InputAdornmentWrapper] - Wrapper for prefix/suffix
/// - [InputAdornmentText] - Text adornment
/// - [InputAdornmentIcon] - Icon adornment
/// - [InputWithAdornments] - Builder helper
///
/// ## Usage Example
///
/// ```dart
/// FormFieldWrapper(
///   children: [
///     FormLabel(
///       labelText: 'Email',
///       forId: 'email',
///       required: true,
///     ),
///     FormInput(
///       type: InputType.email,
///       id: 'email',
///       name: 'email',
///       placeholder: 'you@example.com',
///       required: true,
///     ),
///     FormHelperText(helperText: 'We will never share your email.'),
///   ],
/// )
/// ```
library;

export 'form_field_wrapper.dart';
export 'form_helper_text.dart';
export 'form_inputs.dart';
export 'form_label.dart';
export 'form_styles.dart';
export 'form_toggle.dart';
export 'input_adornment.dart';
