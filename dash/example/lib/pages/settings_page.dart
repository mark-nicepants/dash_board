import 'dart:async';

import 'package:dash/dash.dart';
import 'package:jaspr/jaspr.dart';
import 'package:shelf/shelf.dart';

/// Example settings page demonstrating the Custom Pages and Settings Storage features.
///
/// This page shows how to:
/// - Create a custom page that integrates with the admin layout
/// - Use the SettingsService to persist key-value settings
/// - Handle form submissions to save settings
class SettingsPage extends Page {
  /// Factory constructor following Dash conventions.
  static SettingsPage make() => SettingsPage();

  @override
  String get slug => 'settings';

  @override
  String get title => 'Settings';

  @override
  HeroIcons? get icon => HeroIcons.cog6Tooth;

  @override
  String? get navigationGroup => 'System';

  @override
  int get navigationSort => 100;

  @override
  List<BreadCrumbItem> breadcrumbs(String basePath) => [
    BreadCrumbItem(label: 'Dashboard', url: basePath),
    const BreadCrumbItem(label: 'Settings'),
  ];

  @override
  FutureOr<Component> build(Request request, String basePath, {Map<String, dynamic>? formData}) async {
    final settings = inject<SettingsService>();

    // Handle form submission
    String? successMessage;
    if (request.method == 'POST' && formData != null) {
      // Save settings from parsed form data
      if (formData['app_name'] != null) {
        await settings.set('app.name', formData['app_name']);
      }
      if (formData['app_description'] != null) {
        await settings.set('app.description', formData['app_description']);
      }
      await settings.set('app.debug', formData['app_debug'] == 'on');
      await settings.set('app.maintenance', formData['app_maintenance'] == 'on');

      // Mail settings
      if (formData['mail_driver'] != null) {
        await settings.set('mail.driver', formData['mail_driver']);
      }
      if (formData['mail_host'] != null) {
        await settings.set('mail.smtp.host', formData['mail_host']);
      }
      if (formData['mail_port'] != null) {
        final port = int.tryParse(formData['mail_port']?.toString() ?? '');
        if (port != null) {
          await settings.set('mail.smtp.port', port);
        }
      }

      successMessage = 'Settings saved successfully!';
    }

    // Load current settings
    final appName = await settings.getString('app.name', defaultValue: 'Dash Admin');
    final appDescription = await settings.getString('app.description', defaultValue: '');
    final debugMode = await settings.getBool('app.debug', defaultValue: false);
    final maintenanceMode = await settings.getBool('app.maintenance', defaultValue: false);
    final mailDriver = await settings.getString('mail.driver', defaultValue: 'smtp');
    final mailHost = await settings.getString('mail.smtp.host', defaultValue: 'localhost');
    final mailPort = await settings.getInt('mail.smtp.port', defaultValue: 587);

    return div(classes: 'space-y-6', [
      // Page header
      div(classes: 'flex flex-col gap-2', [
        nav(classes: 'text-sm', [
          ol(classes: 'flex items-center gap-2', [
            li(classes: 'inline-flex', [
              a(href: basePath, classes: 'text-gray-400 hover:text-gray-200 transition-colors', [text('Dashboard')]),
            ]),
            li(classes: 'text-gray-600 select-none', [text('›')]),
            li(classes: 'inline-flex', [
              span(classes: 'text-gray-200', [text('Settings')]),
            ]),
          ]),
        ]),
        div(classes: 'flex justify-between items-center gap-4', [
          h1(classes: 'text-3xl font-bold text-gray-100', [text('Settings')]),
        ]),
      ]),

      // Success message
      if (successMessage != null)
        div(classes: 'bg-green-900/30 border border-green-700 rounded-lg p-4', [
          div(classes: 'flex gap-3', [
            div(classes: 'text-green-400', [const Heroicon(HeroIcons.checkCircle)]),
            div([
              p(classes: 'text-green-200', [text(successMessage)]),
            ]),
          ]),
        ]),

      // Settings form
      form(method: FormMethod.post, action: '$basePath/pages/settings', classes: 'space-y-6', [
        // Application Settings Card
        div(classes: 'bg-gray-800 rounded-xl border border-gray-700 overflow-hidden', [
          div(classes: 'border-b border-gray-700 px-6 py-4', [
            div(classes: 'flex items-center gap-3', [
              div(classes: 'text-cyan-400', [const Heroicon(HeroIcons.cog6Tooth)]),
              h2(classes: 'text-lg font-semibold text-white', [text('Application Settings')]),
            ]),
          ]),
          div(classes: 'p-6 space-y-4', [
            _buildTextField(
              name: 'app_name',
              label_: 'Application Name',
              value: appName ?? '',
              placeholder: 'Enter application name',
            ),
            _buildTextField(
              name: 'app_description',
              label_: 'Description',
              value: appDescription ?? '',
              placeholder: 'Enter application description',
            ),
            div(classes: 'grid grid-cols-1 md:grid-cols-2 gap-4', [
              _buildToggle(
                name: 'app_debug',
                label_: 'Debug Mode',
                description: 'Enable detailed error messages',
                checked: debugMode ?? false,
              ),
              _buildToggle(
                name: 'app_maintenance',
                label_: 'Maintenance Mode',
                description: 'Put the site into maintenance mode',
                checked: maintenanceMode ?? false,
              ),
            ]),
          ]),
        ]),

        // Mail Settings Card
        div(classes: 'bg-gray-800 rounded-xl border border-gray-700 overflow-hidden', [
          div(classes: 'border-b border-gray-700 px-6 py-4', [
            div(classes: 'flex items-center gap-3', [
              div(classes: 'text-cyan-400', [const Heroicon(HeroIcons.envelope)]),
              h2(classes: 'text-lg font-semibold text-white', [text('Mail Settings')]),
            ]),
          ]),
          div(classes: 'p-6 space-y-4', [
            _buildSelect(
              name: 'mail_driver',
              label_: 'Mail Driver',
              value: mailDriver ?? 'smtp',
              options: {'smtp': 'SMTP', 'sendmail': 'Sendmail', 'log': 'Log (Development)'},
            ),
            div(classes: 'grid grid-cols-1 md:grid-cols-2 gap-4', [
              _buildTextField(
                name: 'mail_host',
                label_: 'SMTP Host',
                value: mailHost ?? '',
                placeholder: 'smtp.example.com',
              ),
              _buildTextField(
                name: 'mail_port',
                label_: 'SMTP Port',
                value: mailPort?.toString() ?? '587',
                placeholder: '587',
                type: 'number',
              ),
            ]),
          ]),
        ]),

        // Submit button
        div(classes: 'flex justify-end', [
          button(
            type: ButtonType.submit,
            classes:
                'inline-flex items-center gap-2 px-4 py-2 bg-cyan-600 hover:bg-cyan-500 text-white font-medium rounded-lg transition-colors',
            [const Heroicon(HeroIcons.check, size: 20), text('Save Settings')],
          ),
        ]),
      ]),

      // Info box about SettingsService
      div(classes: 'bg-blue-900/30 border border-blue-700 rounded-lg p-4', [
        div(classes: 'flex gap-3', [
          div(classes: 'text-blue-400', [const Heroicon(HeroIcons.informationCircle)]),
          div([
            h3(classes: 'font-medium text-blue-200', [text('Settings Storage Feature')]),
            p(classes: 'mt-1 text-sm text-blue-300', [
              text(
                'This page demonstrates the Settings Storage feature. Settings are persisted '
                'to the database using the SettingsService with type-safe accessors. '
                'Use dot notation for hierarchical settings like "app.name" or "mail.smtp.host".',
              ),
            ]),
          ]),
        ]),
      ]),
    ]);
  }

  /// Builds a text input field.
  Component _buildTextField({
    required String name,
    required String label_,
    required String value,
    String? placeholder,
    String type = 'text',
  }) {
    return div(classes: 'space-y-2', [
      label(attributes: {'for': name}, classes: 'block text-sm font-medium text-gray-300', [text(label_)]),
      input(
        type: InputType.values.firstWhere((t) => t.name == type, orElse: () => InputType.text),
        name: name,
        id: name,
        value: value,
        attributes: {'placeholder': placeholder ?? ''},
        classes:
            'w-full px-3 py-2 bg-gray-900 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-cyan-500 focus:ring-1 focus:ring-cyan-500',
      ),
    ]);
  }

  /// Builds a toggle/checkbox field.
  Component _buildToggle({
    required String name,
    required String label_,
    required String description,
    required bool checked,
  }) {
    return div(classes: 'flex items-start gap-3', [
      div(classes: 'pt-0.5', [
        input(
          type: InputType.checkbox,
          name: name,
          id: name,
          attributes: checked ? {'checked': 'checked'} : {},
          classes: 'w-4 h-4 bg-gray-900 border-gray-600 rounded text-cyan-500 focus:ring-cyan-500 focus:ring-offset-0',
        ),
      ]),
      div([
        label(
          attributes: {'for': name},
          classes: 'block text-sm font-medium text-gray-300 cursor-pointer',
          [text(label_)],
        ),
        p(classes: 'text-sm text-gray-500', [text(description)]),
      ]),
    ]);
  }

  /// Builds a select dropdown.
  Component _buildSelect({
    required String name,
    required String label_,
    required String value,
    required Map<String, String> options,
  }) {
    return div(classes: 'space-y-2', [
      label(attributes: {'for': name}, classes: 'block text-sm font-medium text-gray-300', [text(label_)]),
      select(
        name: name,
        id: name,
        classes:
            'w-full px-3 py-2 bg-gray-900 border border-gray-600 rounded-lg text-white focus:outline-none focus:border-cyan-500 focus:ring-1 focus:ring-cyan-500',
        [
          for (final entry in options.entries)
            option(value: entry.key, attributes: entry.key == value ? {'selected': 'selected'} : {}, [
              text(entry.value),
            ]),
        ],
      ),
    ]);
  }
}
