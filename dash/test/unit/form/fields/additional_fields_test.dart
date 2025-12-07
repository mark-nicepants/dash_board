import 'package:dash_board/dash_board.dart';
import 'package:test/test.dart';

void main() {
  group('DatePicker', () {
    group('Factory', () {
      test('make() creates date picker with name', () {
        final field = DatePicker.make('birth_date');
        expect(field.getName(), equals('birth_date'));
      });
    });

    group('Time Configuration', () {
      test('withTime() enables time selection', () {
        final field = DatePicker.make('appointment').withTime();
        expect(field.hasTime(), isTrue);
      });

      test('withTime(false) disables time selection', () {
        final field = DatePicker.make('appointment').withTime(false);
        expect(field.hasTime(), isFalse);
      });

      test('timeOnly() enables time-only mode', () {
        final field = DatePicker.make('time').timeOnly();
        expect(field.isTimeOnly(), isTrue);
      });

      test('timeOnly(false) disables time-only mode', () {
        final field = DatePicker.make('time').timeOnly(false);
        expect(field.isTimeOnly(), isFalse);
      });
    });

    group('Date Constraints', () {
      test('minDate() sets minimum date', () {
        final minDate = DateTime(2024, 1, 1);
        final field = DatePicker.make('date').minDate(minDate);
        expect(field.getMinDate(), equals(minDate));
      });

      test('minDate() adds DateAfter validation rule', () {
        final minDate = DateTime(2024, 1, 1);
        final field = DatePicker.make('date').minDate(minDate);
        expect(field.getValidationRules().any((r) => r.contains('date_after')), isTrue);
      });

      test('maxDate() sets maximum date', () {
        final maxDate = DateTime(2025, 12, 31);
        final field = DatePicker.make('date').maxDate(maxDate);
        expect(field.getMaxDate(), equals(maxDate));
      });

      test('maxDate() adds DateBefore validation rule', () {
        final maxDate = DateTime(2025, 12, 31);
        final field = DatePicker.make('date').maxDate(maxDate);
        expect(field.getValidationRules().any((r) => r.contains('date_before')), isTrue);
      });

      test('minToday() sets minimum to current date', () {
        final field = DatePicker.make('date').minToday();
        expect(field.getMinDate(), isNotNull);
        expect(field.getMinDate()!.day, equals(DateTime.now().day));
      });

      test('maxToday() sets maximum to current date', () {
        final field = DatePicker.make('date').maxToday();
        expect(field.getMaxDate(), isNotNull);
        expect(field.getMaxDate()!.day, equals(DateTime.now().day));
      });

      test('disabledDates() sets dates that cannot be selected', () {
        final disabled = [DateTime(2024, 12, 25), DateTime(2024, 12, 26)];
        final field = DatePicker.make('date').disabledDates(disabled);
        expect(field.getDisabledDates(), equals(disabled));
      });
    });

    group('Display Configuration', () {
      test('displayFormat() sets format string', () {
        final field = DatePicker.make('date').displayFormat('MM/dd/yyyy');
        expect(field.getDisplayFormat(), equals('MM/dd/yyyy'));
      });

      test('default displayFormat is yyyy-MM-dd', () {
        final field = DatePicker.make('date');
        expect(field.getDisplayFormat(), equals('yyyy-MM-dd'));
      });

      test('native() enables native HTML input', () {
        final field = DatePicker.make('date').native();
        expect(field.isNative(), isTrue);
      });

      test('native(false) disables native HTML input', () {
        final field = DatePicker.make('date').native(false);
        expect(field.isNative(), isFalse);
      });

      test('default native is true', () {
        final field = DatePicker.make('date');
        expect(field.isNative(), isTrue);
      });
    });

    group('Calendar Configuration', () {
      test('firstDayOfWeek() sets start day', () {
        final field = DatePicker.make('date').firstDayOfWeek(0);
        expect(field.getFirstDayOfWeek(), equals(0));
      });

      test('default firstDayOfWeek is 1 (Monday)', () {
        final field = DatePicker.make('date');
        expect(field.getFirstDayOfWeek(), equals(1));
      });

      test('closeOnSelect() sets close behavior', () {
        final field = DatePicker.make('date').closeOnSelect(false);
        expect(field.shouldCloseOnSelect(), isFalse);
      });

      test('default closeOnSelect is true', () {
        final field = DatePicker.make('date');
        expect(field.shouldCloseOnSelect(), isTrue);
      });
    });

    group('Fluent API Chaining', () {
      test('all methods can be chained', () {
        final minDate = DateTime(2024, 1, 1);
        final maxDate = DateTime(2024, 12, 31);

        final field = DatePicker.make('appointment')
            .label('Appointment Date')
            .placeholder('Select a date')
            .withTime()
            .minDate(minDate)
            .maxDate(maxDate)
            .displayFormat('MM/dd/yyyy HH:mm')
            .firstDayOfWeek(0)
            .closeOnSelect()
            .required();

        expect(field.getLabel(), equals('Appointment Date'));
        expect(field.getPlaceholder(), equals('Select a date'));
        expect(field.hasTime(), isTrue);
        expect(field.getMinDate(), equals(minDate));
        expect(field.getMaxDate(), equals(maxDate));
        expect(field.getDisplayFormat(), equals('MM/dd/yyyy HH:mm'));
        expect(field.getFirstDayOfWeek(), equals(0));
        expect(field.shouldCloseOnSelect(), isTrue);
        expect(field.isRequired(), isTrue);
      });
    });
  });

  group('Checkbox', () {
    group('Factory', () {
      test('make() creates checkbox with name', () {
        final field = Checkbox.make('agree');
        expect(field.getName(), equals('agree'));
      });
    });

    group('Inline', () {
      test('inline() enables inline display', () {
        final field = Checkbox.make('agree').inline();
        expect(field.isInline(), isTrue);
      });

      test('inline(false) disables inline display', () {
        final field = Checkbox.make('agree').inline(false);
        expect(field.isInline(), isFalse);
      });

      test('default inline is true', () {
        final field = Checkbox.make('agree');
        expect(field.isInline(), isTrue);
      });
    });

    group('Accepted Validation', () {
      test('accepted() adds accepted validation', () {
        final field = Checkbox.make('terms').accepted();
        expect(field.getValidationRules(), contains('accepted'));
        expect(field.mustBeAccepted(), isTrue);
      });
    });

    group('Values', () {
      test('checkedValue() sets checked value', () {
        final field = Checkbox.make('agree').checkedValue('yes');
        expect(field.getCheckedValue(), equals('yes'));
      });

      test('default checkedValue is 1', () {
        final field = Checkbox.make('agree');
        expect(field.getCheckedValue(), equals('1'));
      });

      test('uncheckedValue() sets unchecked value', () {
        final field = Checkbox.make('agree').uncheckedValue('no');
        expect(field.getUncheckedValue(), equals('no'));
      });
    });

    group('Fluent API Chaining', () {
      test('all methods can be chained', () {
        final field = Checkbox.make('terms')
            .label('I agree to the terms')
            .helperText('Please read the terms carefully')
            .accepted()
            .inline()
            .checkedValue('yes')
            .uncheckedValue('no');

        expect(field.getLabel(), equals('I agree to the terms'));
        expect(field.getHelperText(), equals('Please read the terms carefully'));
        expect(field.mustBeAccepted(), isTrue);
        expect(field.isInline(), isTrue);
        expect(field.getCheckedValue(), equals('yes'));
        expect(field.getUncheckedValue(), equals('no'));
      });
    });
  });

  group('Select', () {
    group('Factory', () {
      test('make() creates select with name', () {
        final field = Select.make('country');
        expect(field.getName(), equals('country'));
      });
    });

    group('Options', () {
      test('options() sets select options', () {
        final field = Select.make(
          'status',
        ).options([const SelectOption('active', 'Active'), const SelectOption('inactive', 'Inactive')]);
        expect(field.getOptions(), hasLength(2));
      });

      test('SelectOption stores value and label', () {
        const option = SelectOption('us', 'United States');
        expect(option.value, equals('us'));
        expect(option.label, equals('United States'));
      });

      test('SelectOption.fromMap creates options from map', () {
        final options = SelectOption.fromMap({'red': 'Red', 'green': 'Green', 'blue': 'Blue'});
        expect(options, hasLength(3));
      });

      test('SelectOptionGroup groups options', () {
        final group = const SelectOptionGroup(
          label: 'Primary Colors',
          options: [SelectOption('red', 'Red'), SelectOption('blue', 'Blue'), SelectOption('yellow', 'Yellow')],
        );
        expect(group.label, equals('Primary Colors'));
        expect(group.options, hasLength(3));
      });
    });

    group('Selection Mode', () {
      test('multiple() enables multi-select', () {
        final field = Select.make('tags').multiple();
        expect(field.isMultiple(), isTrue);
      });

      test('multiple(false) disables multi-select', () {
        final field = Select.make('tags').multiple(false);
        expect(field.isMultiple(), isFalse);
      });

      test('default multiple is false', () {
        final field = Select.make('status');
        expect(field.isMultiple(), isFalse);
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

    group('Creatable', () {
      test('creatable() enables creating new options', () {
        final field = Select.make('tags').creatable();
        expect(field.isCreatable(), isTrue);
      });

      test('creatable(false) disables creating options', () {
        final field = Select.make('tags').creatable(false);
        expect(field.isCreatable(), isFalse);
      });
    });

    group('Native', () {
      test('native() enables native select', () {
        final field = Select.make('status').native();
        expect(field.isNative(), isTrue);
      });

      test('native(false) disables native select', () {
        final field = Select.make('status').native(false);
        expect(field.isNative(), isFalse);
      });

      test('default native is true', () {
        final field = Select.make('status');
        expect(field.isNative(), isTrue);
      });
    });

    group('Size', () {
      test('size() sets visible option count', () {
        final field = Select.make('items').size(5);
        expect(field.getSize(), equals(5));
      });
    });

    group('Placeholder Option', () {
      test('selectPlaceholder() sets placeholder in dropdown', () {
        final field = Select.make('status').selectPlaceholder('Choose an option');
        expect(field.getSelectPlaceholder(), equals('Choose an option'));
      });
    });

    group('Groups', () {
      test('groups() sets option groups', () {
        final field = Select.make('color').groups([
          const SelectOptionGroup(
            label: 'Primary',
            options: [SelectOption('red', 'Red'), SelectOption('blue', 'Blue')],
          ),
          const SelectOptionGroup(
            label: 'Secondary',
            options: [SelectOption('orange', 'Orange'), SelectOption('purple', 'Purple')],
          ),
        ]);
        expect(field.getGroups(), hasLength(2));
      });
    });

    group('Fluent API Chaining', () {
      test('all methods can be chained', () {
        final field = Select.make('country')
            .label('Country')
            .placeholder('Select country')
            .selectPlaceholder('-- Choose --')
            .options([const SelectOption('us', 'United States'), const SelectOption('uk', 'United Kingdom')])
            .searchable()
            .required();

        expect(field.getLabel(), equals('Country'));
        expect(field.getPlaceholder(), equals('Select country'));
        expect(field.getSelectPlaceholder(), equals('-- Choose --'));
        expect(field.getOptions(), hasLength(2));
        expect(field.isSearchable(), isTrue);
        expect(field.isRequired(), isTrue);
      });
    });
  });

  group('Toggle', () {
    group('Factory', () {
      test('make() creates toggle with name', () {
        final field = Toggle.make('active');
        expect(field.getName(), equals('active'));
      });
    });

    group('Labels', () {
      test('onLabel() sets on state label', () {
        final field = Toggle.make('active').onLabel('Active');
        expect(field.getOnLabel(), equals('Active'));
      });

      test('offLabel() sets off state label', () {
        final field = Toggle.make('active').offLabel('Inactive');
        expect(field.getOffLabel(), equals('Inactive'));
      });
    });

    group('Colors', () {
      test('onColor() sets on state color', () {
        final field = Toggle.make('active').onColor('green');
        expect(field.getOnColor(), equals('green'));
      });

      test('offColor() sets off state color', () {
        final field = Toggle.make('active').offColor('red');
        expect(field.getOffColor(), equals('red'));
      });
    });

    group('Fluent API Chaining', () {
      test('all methods can be chained', () {
        final field = Toggle.make('is_published')
            .label('Published')
            .onLabel('Published')
            .offLabel('Draft')
            .onColor('green')
            .offColor('gray')
            .defaultValue(false);

        expect(field.getLabel(), equals('Published'));
        expect(field.getOnLabel(), equals('Published'));
        expect(field.getOffLabel(), equals('Draft'));
        expect(field.getOnColor(), equals('green'));
        expect(field.getOffColor(), equals('gray'));
        expect(field.getDefaultValue(), isFalse);
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
      test('rows() sets row count', () {
        final field = Textarea.make('bio').rows(10);
        expect(field.getRows(), equals(10));
      });
    });

    group('Auto Resize', () {
      test('autoResize() enables auto-resize', () {
        final field = Textarea.make('content').autoResize();
        expect(field.shouldAutoResize(), isTrue);
      });

      test('minRows() sets minimum rows', () {
        final field = Textarea.make('content').minRows(3);
        expect(field.getMinRows(), equals(3));
      });

      test('maxRows() sets maximum rows', () {
        final field = Textarea.make('content').maxRows(20);
        expect(field.getMaxRows(), equals(20));
      });
    });

    group('Fluent API Chaining', () {
      test('all methods can be chained', () {
        final field = Textarea.make('bio')
            .label('Biography')
            .placeholder('Tell us about yourself')
            .rows(5)
            .autoResize()
            .minRows(3)
            .maxRows(15)
            .maxLength(500)
            .required();

        expect(field.getLabel(), equals('Biography'));
        expect(field.getPlaceholder(), equals('Tell us about yourself'));
        expect(field.getRows(), equals(5));
        expect(field.shouldAutoResize(), isTrue);
        expect(field.getMinRows(), equals(3));
        expect(field.getMaxRows(), equals(15));
        expect(field.isRequired(), isTrue);
      });
    });
  });
}
