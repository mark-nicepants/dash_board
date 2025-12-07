import 'package:dash/dash.dart';
import 'package:test/test.dart';

void main() {
  group('FormField (Base)', () {
    group('Name and ID', () {
      test('getName() returns field name', () {
        final field = TextInput.make('email');
        expect(field.getName(), equals('email'));
      });

      test('id() sets custom ID', () {
        final field = TextInput.make('email').id('user-email');
        expect(field.getId(), equals('user-email'));
      });

      test('getId() defaults to name', () {
        final field = TextInput.make('email');
        expect(field.getId(), equals('email'));
      });
    });

    group('Label', () {
      test('label() sets custom label', () {
        final field = TextInput.make('email').label('Email Address');
        expect(field.getLabel(), equals('Email Address'));
      });

      test('getLabel() derives from snake_case name', () {
        final field = TextInput.make('email_address');
        expect(field.getLabel(), equals('Email Address'));
      });

      test('getLabel() derives from camelCase name', () {
        final field = TextInput.make('emailAddress');
        expect(field.getLabel(), equals('Email Address'));
      });
    });

    group('Placeholder', () {
      test('placeholder() sets placeholder text', () {
        final field = TextInput.make('email').placeholder('you@example.com');
        expect(field.getPlaceholder(), equals('you@example.com'));
      });
    });

    group('Helper Text and Hint', () {
      test('helperText() sets helper text', () {
        final field = TextInput.make('email').helperText('We will not share your email.');
        expect(field.getHelperText(), equals('We will not share your email.'));
      });

      test('hint() sets hint text', () {
        final field = TextInput.make('email').hint('Enter a valid email');
        expect(field.getHint(), equals('Enter a valid email'));
      });
    });

    group('Default Value', () {
      test('defaultValue() sets default', () {
        final field = TextInput.make('status').defaultValue('active');
        expect(field.getDefaultValue(), equals('active'));
      });
    });

    group('Required', () {
      test('required() marks field as required', () {
        final field = TextInput.make('name').required();
        expect(field.isRequired(), isTrue);
      });

      test('required() adds Required validation rule', () {
        final field = TextInput.make('name').required();
        expect(field.getValidationRules(), contains('required'));
      });

      test('required(false) removes required flag', () {
        final field = TextInput.make('name').required(false);
        expect(field.isRequired(), isFalse);
      });
    });

    group('Disabled', () {
      test('disabled() disables the field', () {
        final field = TextInput.make('name').disabled();
        expect(field.isDisabled(), isTrue);
      });

      test('disabled(false) enables the field', () {
        final field = TextInput.make('name').disabled(false);
        expect(field.isDisabled(), isFalse);
      });
    });

    group('Readonly', () {
      test('readonly() makes field readonly', () {
        final field = TextInput.make('id').readonly();
        expect(field.isReadonly(), isTrue);
      });

      test('readonly(false) makes field editable', () {
        final field = TextInput.make('id').readonly(false);
        expect(field.isReadonly(), isFalse);
      });
    });

    group('Hidden', () {
      test('hidden() hides the field', () {
        final field = TextInput.make('secret').hidden();
        expect(field.isHidden(), isTrue);
      });

      test('hidden(false) shows the field', () {
        final field = TextInput.make('secret').hidden(false);
        expect(field.isHidden(), isFalse);
      });
    });

    group('Nullable', () {
      test('nullable() allows empty values', () {
        final field = TextInput.make('bio').nullable();
        expect(field.isNullable(), isTrue);
      });

      test('nullable(false) disallows empty values', () {
        final field = TextInput.make('bio').nullable(false);
        expect(field.isNullable(), isFalse);
      });
    });

    group('Column Span', () {
      test('columnSpan() sets span value', () {
        final field = TextInput.make('description').columnSpan(2);
        expect(field.getColumnSpan(), equals(2));
      });

      test('columnSpanFull() sets full width', () {
        final field = TextInput.make('description').columnSpanFull();
        expect(field.isColumnSpanFull(), isTrue);
      });

      test('columnSpanBreakpoint() sets responsive spans', () {
        final field = TextInput.make('name').columnSpanBreakpoint('md', 2).columnSpanBreakpoint('lg', 1);
        final breakpoints = field.getColumnSpanBreakpoints();
        expect(breakpoints['md'], equals(2));
        expect(breakpoints['lg'], equals(1));
      });

      test('getColumnSpanClasses() returns correct Tailwind class', () {
        final field = TextInput.make('name').columnSpan(2);
        expect(field.getColumnSpanClasses(3), equals('col-span-2'));
      });

      test('getColumnSpanClasses() returns col-span-full for full width', () {
        final field = TextInput.make('name').columnSpanFull();
        expect(field.getColumnSpanClasses(2), equals('col-span-full'));
      });
    });

    group('Extra Classes', () {
      test('extraClasses() sets custom CSS classes', () {
        final field = TextInput.make('name').extraClasses('my-custom-class');
        expect(field.getExtraClasses(), equals('my-custom-class'));
      });
    });

    group('Autofocus', () {
      test('autofocus() enables autofocus', () {
        final field = TextInput.make('name').autofocus();
        expect(field.shouldAutofocus(), isTrue);
      });

      test('autofocus(false) disables autofocus', () {
        final field = TextInput.make('name').autofocus(false);
        expect(field.shouldAutofocus(), isFalse);
      });
    });

    group('Autocomplete', () {
      test('autocomplete() sets autocomplete value', () {
        final field = TextInput.make('email').autocomplete('email');
        expect(field.getAutocomplete(), equals('email'));
      });
    });

    group('Tabindex', () {
      test('tabindex() sets tab order', () {
        final field = TextInput.make('name').tabindex(1);
        expect(field.getTabindex(), equals(1));
      });
    });

    group('Validation Rules', () {
      test('rule() adds single validation rule', () {
        final field = TextInput.make('name').rule(MinLength(3));
        expect(field.getValidationRules(), contains('min:3'));
      });

      test('rules() adds multiple validation rules', () {
        final field = TextInput.make('name').rules([MinLength(3), MaxLength(50)]);
        expect(field.getValidationRules(), contains('min:3'));
        expect(field.getValidationRules(), contains('max:50'));
      });

      test('validationMessage() sets custom error message', () {
        final field = TextInput.make('name').required().validationMessage('required', 'Name is required');

        final errors = field.validate('');
        expect(errors, contains('Name is required'));
      });
    });

    group('Validation', () {
      test('validate() returns empty list for valid value', () {
        final field = TextInput.make('name').required();
        final errors = field.validate('John');
        expect(errors, isEmpty);
      });

      test('validate() returns errors for invalid value', () {
        final field = TextInput.make('name').required();
        final errors = field.validate('');
        expect(errors, isNotEmpty);
      });

      test('validate() runs multiple rules', () {
        final field = TextInput.make('name').required().rule(MinLength(3)).rule(MaxLength(10));

        // Too short
        var errors = field.validate('ab');
        expect(errors, hasLength(1));

        // Just right
        errors = field.validate('John');
        expect(errors, isEmpty);

        // Too long
        errors = field.validate('This is way too long');
        expect(errors, hasLength(1));
      });
    });

    group('Dehydrate and Hydrate', () {
      test('dehydrate() sets transformation callback', () {
        final field = TextInput.make('slug').dehydrate((value) => value?.toString().toLowerCase().replaceAll(' ', '-'));

        expect(field.getDehydrateCallback(), isNotNull);
        expect(field.dehydrateValue('Hello World'), equals('hello-world'));
      });

      test('dehydrateValue() returns original when no callback', () {
        final field = TextInput.make('name');
        expect(field.dehydrateValue('test'), equals('test'));
      });

      test('hydrate() sets transformation callback', () {
        final field = TextInput.make('price').hydrate((value) => '\$${(value as num).toStringAsFixed(2)}');

        expect(field.getHydrateCallback(), isNotNull);
        expect(field.hydrateValue(29.99), equals('\$29.99'));
      });

      test('hydrateValue() returns original when no callback', () {
        final field = TextInput.make('name');
        expect(field.hydrateValue('test'), equals('test'));
      });
    });

    group('Build Input Attributes', () {
      test('buildInputAttributes() includes placeholder', () {
        final field = TextInput.make('name').placeholder('Enter name');
        final attrs = field.buildInputAttributes();
        expect(attrs['placeholder'], equals('Enter name'));
      });

      test('buildInputAttributes() includes disabled', () {
        final field = TextInput.make('name').disabled();
        final attrs = field.buildInputAttributes();
        expect(attrs['disabled'], equals('true'));
      });

      test('buildInputAttributes() includes readonly', () {
        final field = TextInput.make('name').readonly();
        final attrs = field.buildInputAttributes();
        expect(attrs['readonly'], equals('true'));
      });

      test('buildInputAttributes() includes autofocus', () {
        final field = TextInput.make('name').autofocus();
        final attrs = field.buildInputAttributes();
        expect(attrs['autofocus'], equals('true'));
      });

      test('buildInputAttributes() includes required', () {
        final field = TextInput.make('name').required();
        final attrs = field.buildInputAttributes();
        expect(attrs['required'], equals('true'));
      });
    });
  });

  group('TextInput', () {
    group('Factory', () {
      test('make() creates field with name', () {
        final field = TextInput.make('email');
        expect(field.getName(), equals('email'));
      });
    });

    group('Input Type', () {
      test('getType() returns the input type', () {
        final field = TextInput.make('name');
        expect(field.getType(), isNotNull);
      });

      test('email() adds email validation', () {
        final field = TextInput.make('email').email();
        expect(field.getValidationRules(), contains('email'));
      });

      test('password() sets autocomplete to current-password', () {
        final field = TextInput.make('password').password();
        expect(field.getAutocomplete(), equals('current-password'));
      });

      test('url() adds url validation', () {
        final field = TextInput.make('website').url();
        expect(field.getValidationRules(), contains('url'));
      });

      test('tel() sets autocomplete to tel', () {
        final field = TextInput.make('phone').tel();
        expect(field.getAutocomplete(), equals('tel'));
      });

      test('search() creates search input', () {
        final field = TextInput.make('query').search();
        expect(field, isNotNull);
      });

      test('numeric() sets numeric validation', () {
        final field = TextInput.make('age').numeric();
        expect(field.getValidationRules(), contains('numeric'));
      });

      test('integer() sets integer validation', () {
        final field = TextInput.make('count').integer();
        expect(field.getValidationRules(), contains('integer'));
      });
    });

    group('Length Validation', () {
      test('minLength() adds min length validation', () {
        final field = TextInput.make('password').minLength(8);
        expect(field.getValidationRules(), contains('min:8'));
        expect(field.getMinLength(), equals(8));
      });

      test('maxLength() adds max length validation', () {
        final field = TextInput.make('name').maxLength(50);
        expect(field.getValidationRules(), contains('max:50'));
        expect(field.getMaxLength(), equals(50));
      });
    });

    group('Pattern Validation', () {
      test('pattern() adds regex validation', () {
        final field = TextInput.make('code').pattern(RegExp(r'^[A-Z]{2}\d{4}$'));
        expect(field.getValidationRules(), contains('regex'));
        expect(field.getPattern(), isNotNull);
      });
    });

    group('Prefix and Suffix', () {
      test('prefix() sets prefix text', () {
        final field = TextInput.make('price').prefix('\$');
        expect(field.getPrefix(), equals('\$'));
      });

      test('suffix() sets suffix text', () {
        final field = TextInput.make('weight').suffix('kg');
        expect(field.getSuffix(), equals('kg'));
      });

      test('prefixIcon() sets prefix icon', () {
        final field = TextInput.make('email').prefixIcon(HeroIcons.envelope);
        expect(field.getPrefixIcon(), equals(HeroIcons.envelope));
      });

      test('suffixIcon() sets suffix icon', () {
        final field = TextInput.make('search').suffixIcon(HeroIcons.magnifyingGlass);
        expect(field.getSuffixIcon(), equals(HeroIcons.magnifyingGlass));
      });
    });

    group('Character Count', () {
      test('characterCount() enables character count display', () {
        final field = TextInput.make('bio').characterCount();
        expect(field.shouldShowCharacterCount(), isTrue);
      });
    });

    group('Datalist', () {
      test('datalist() sets autocomplete options', () {
        final field = TextInput.make('country').datalist(['USA', 'Canada', 'Mexico']);
        expect(field.getDatalist(), equals(['USA', 'Canada', 'Mexico']));
      });
    });

    group('Fluent API Chaining', () {
      test('methods can be chained together', () {
        final field = TextInput.make('email')
            .label('Email Address')
            .placeholder('you@example.com')
            .helperText('We will not share your email.')
            .required()
            .email()
            .maxLength(100)
            .prefixIcon(HeroIcons.envelope)
            .columnSpan(2)
            .autofocus();

        expect(field.getLabel(), equals('Email Address'));
        expect(field.getPlaceholder(), equals('you@example.com'));
        expect(field.getHelperText(), equals('We will not share your email.'));
        expect(field.isRequired(), isTrue);
        expect(field.getMaxLength(), equals(100));
        expect(field.getPrefixIcon(), equals(HeroIcons.envelope));
        expect(field.getColumnSpan(), equals(2));
        expect(field.shouldAutofocus(), isTrue);
      });
    });
  });

  group('Textarea', () {
    group('Factory', () {
      test('make() creates textarea with name', () {
        final field = Textarea.make('description');
        expect(field.getName(), equals('description'));
      });
    });

    group('Rows', () {
      test('rows() sets number of rows', () {
        final field = Textarea.make('bio').rows(5);
        expect(field.getRows(), equals(5));
      });
    });

    group('Auto Resize', () {
      test('autoResize() enables auto-resize', () {
        final field = Textarea.make('content').autoResize();
        expect(field.shouldAutoResize(), isTrue);
      });

      test('autoResize(false) disables auto-resize', () {
        final field = Textarea.make('content').autoResize(false);
        expect(field.shouldAutoResize(), isFalse);
      });
    });

    group('Min/Max Rows', () {
      test('minRows() sets minimum rows for auto-resize', () {
        final field = Textarea.make('content').minRows(3);
        expect(field.getMinRows(), equals(3));
      });

      test('maxRows() sets maximum rows for auto-resize', () {
        final field = Textarea.make('content').maxRows(10);
        expect(field.getMaxRows(), equals(10));
      });
    });
  });

  group('Toggle', () {
    group('Factory', () {
      test('make() creates toggle with name', () {
        final field = Toggle.make('is_active');
        expect(field.getName(), equals('is_active'));
      });
    });

    group('Labels', () {
      test('onLabel() sets on state label', () {
        final field = Toggle.make('is_active').onLabel('Active');
        expect(field.getOnLabel(), equals('Active'));
      });

      test('offLabel() sets off state label', () {
        final field = Toggle.make('is_active').offLabel('Inactive');
        expect(field.getOffLabel(), equals('Inactive'));
      });
    });

    group('Colors', () {
      test('onColor() sets on state color', () {
        final field = Toggle.make('is_active').onColor('green');
        expect(field.getOnColor(), equals('green'));
      });

      test('offColor() sets off state color', () {
        final field = Toggle.make('is_active').offColor('red');
        expect(field.getOffColor(), equals('red'));
      });
    });
  });

  group('Select', () {
    group('Factory', () {
      test('make() creates select with name', () {
        final field = Select.make('status');
        expect(field.getName(), equals('status'));
      });
    });

    group('Options', () {
      test('options() sets select options', () {
        final field = Select.make(
          'status',
        ).options([const SelectOption('active', 'Active'), const SelectOption('inactive', 'Inactive')]);
        expect(field.getOptions().length, equals(2));
      });

      test('options() with fromMap helper', () {
        final field = Select.make(
          'color',
        ).options(SelectOption.fromMap({'red': 'Red', 'green': 'Green', 'blue': 'Blue'}));
        expect(field.getOptions().length, equals(3));
      });
    });

    group('Placeholder', () {
      test('placeholder() sets placeholder option', () {
        final field = Select.make('status').placeholder('Select a status');
        expect(field.getPlaceholder(), equals('Select a status'));
      });
    });

    group('Searchable', () {
      test('searchable() enables search', () {
        final field = Select.make('country').searchable();
        expect(field.isSearchable(), isTrue);
      });

      test('searchable(false) disables search', () {
        final field = Select.make('country').searchable(false);
        expect(field.isSearchable(), isFalse);
      });
    });

    group('Multiple', () {
      test('multiple() enables multi-select', () {
        final field = Select.make('tags').multiple();
        expect(field.isMultiple(), isTrue);
      });

      test('multiple(false) disables multi-select', () {
        final field = Select.make('tags').multiple(false);
        expect(field.isMultiple(), isFalse);
      });
    });
  });

  group('Checkbox', () {
    group('Factory', () {
      test('make() creates checkbox with name', () {
        final field = Checkbox.make('terms');
        expect(field.getName(), equals('terms'));
      });
    });

    group('Accepted', () {
      test('accepted() adds accepted validation rule', () {
        final field = Checkbox.make('terms').accepted();
        expect(field.getValidationRules(), contains('accepted'));
      });
    });
  });
}
