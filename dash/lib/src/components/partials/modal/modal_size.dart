/// Size variants for modals.
///
/// Controls the maximum width of the modal container:
/// - [sm] - Small (max-w-sm, ~384px)
/// - [md] - Medium (max-w-md, ~448px)
/// - [lg] - Large (max-w-lg, ~512px)
/// - [xl] - Extra large (max-w-xl, ~576px)
/// - [xxl] - 2x Extra large (max-w-2xl, ~672px)
/// - [full] - Nearly full screen (max-w-4xl)
enum ModalSize {
  sm,
  md,
  lg,
  xl,
  xxl,
  full;

  /// Returns the Tailwind max-width class for this size.
  String get maxWidthClass => switch (this) {
    ModalSize.sm => 'max-w-sm',
    ModalSize.md => 'max-w-md',
    ModalSize.lg => 'max-w-lg',
    ModalSize.xl => 'max-w-xl',
    ModalSize.xxl => 'max-w-2xl',
    ModalSize.full => 'max-w-4xl',
  };
}
