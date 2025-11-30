import 'package:dash/src/components/partials/heroicon.dart';
import 'package:jaspr/jaspr.dart';

/// A reusable pagination component for displaying page navigation controls.
///
/// Renders previous/next buttons and page number links with ellipsis for large page counts.
/// Pages are shown with a sliding window around the current page.
///
/// Supports two modes:
/// - **Link mode**: Use `buildPageUrl` to generate href links for traditional navigation
/// - **Interactive mode**: Use `onPageClick` to generate wire:click attributes for SPA-like behavior
class Pagination extends StatelessComponent {
  /// The current page number (1-indexed).
  final int currentPage;

  /// The total number of records.
  final int totalRecords;

  /// The number of records per page.
  final int perPage;

  /// A function that builds the URL for a given page number (for link-based navigation).
  final String Function(int page)? buildPageUrl;

  /// A function that builds the wire:click action for a given page number (for interactive navigation).
  final String Function(int page)? onPageClick;

  const Pagination({
    required this.currentPage,
    required this.totalRecords,
    required this.perPage,
    this.buildPageUrl,
    this.onPageClick,
    super.key,
  }) : assert(buildPageUrl != null || onPageClick != null, 'Either buildPageUrl or onPageClick must be provided');

  /// Factory constructor for creating a Pagination component with link-based navigation.
  static Pagination make({
    required int currentPage,
    required int totalRecords,
    required int perPage,
    String Function(int page)? buildPageUrl,
    String Function(int page)? onPageClick,
  }) {
    return Pagination(
      currentPage: currentPage,
      totalRecords: totalRecords,
      perPage: perPage,
      buildPageUrl: buildPageUrl,
      onPageClick: onPageClick,
    );
  }

  int get totalPages => (totalRecords / perPage).ceil();

  bool get _isInteractive => onPageClick != null;

  @override
  Component build(BuildContext context) {
    if (totalRecords == 0 || totalPages <= 1) {
      return div([]);
    }

    return div(classes: 'flex justify-between items-center', [_buildPageInfo(), _buildPageControls()]);
  }

  Component _buildPageInfo() {
    return div(classes: 'text-sm text-gray-400', [
      text('Showing '),
      span(classes: 'font-medium', [text('${(currentPage - 1) * perPage + 1}')]),
      text(' to '),
      span(classes: 'font-medium', [text('${(currentPage * perPage).clamp(0, totalRecords)}')]),
      text(' of '),
      span(classes: 'font-medium', [text('$totalRecords')]),
      text(' results'),
    ]);
  }

  Component _buildPageControls() {
    return nav(classes: 'flex gap-1', [_buildPreviousButton(), ..._buildPageNumbers(), _buildNextButton()]);
  }

  Component _buildPreviousButton() {
    final isDisabled = currentPage <= 1;
    if (_isInteractive) {
      return button(
        classes: '${_navButtonClasses()} rounded-l-lg ${isDisabled ? 'opacity-50 cursor-not-allowed' : ''}',
        attributes: isDisabled ? {'disabled': 'disabled'} : {'wire:click': onPageClick!(currentPage - 1)},
        [const Heroicon(HeroIcons.chevronLeft, className: 'w-5 h-5')],
      );
    }
    if (isDisabled) {
      return span(classes: '${_navButtonClasses()} rounded-l-lg opacity-50 cursor-not-allowed', [
        const Heroicon(HeroIcons.chevronLeft, className: 'w-5 h-5'),
      ]);
    }
    return a(href: buildPageUrl!(currentPage - 1), classes: '${_navButtonClasses()} rounded-l-lg', [
      const Heroicon(HeroIcons.chevronLeft, className: 'w-5 h-5'),
    ]);
  }

  Component _buildNextButton() {
    final isDisabled = currentPage >= totalPages;
    if (_isInteractive) {
      return button(
        classes: '${_navButtonClasses()} rounded-r-lg ${isDisabled ? 'opacity-50 cursor-not-allowed' : ''}',
        attributes: isDisabled ? {'disabled': 'disabled'} : {'wire:click': onPageClick!(currentPage + 1)},
        [const Heroicon(HeroIcons.chevronRight, className: 'w-5 h-5')],
      );
    }
    if (isDisabled) {
      return span(classes: '${_navButtonClasses()} rounded-r-lg opacity-50 cursor-not-allowed', [
        const Heroicon(HeroIcons.chevronRight, className: 'w-5 h-5'),
      ]);
    }
    return a(href: buildPageUrl!(currentPage + 1), classes: '${_navButtonClasses()} rounded-r-lg', [
      const Heroicon(HeroIcons.chevronRight, className: 'w-5 h-5'),
    ]);
  }

  List<Component> _buildPageNumbers() {
    final components = <Component>[];

    for (var i = 1; i <= totalPages; i++) {
      if (_shouldShowPage(i)) {
        components.add(_buildPageButton(i));
      } else if (i == currentPage - 2 || i == currentPage + 2) {
        components.add(_buildEllipsis());
      }
    }

    return components;
  }

  Component _buildPageButton(int page) {
    final isActive = page == currentPage;
    if (_isInteractive) {
      return button(
        classes: isActive ? _activePageClasses() : _pageButtonClasses(),
        attributes: {'wire:click': onPageClick!(page)},
        [text('$page')],
      );
    }
    if (isActive) {
      return span(classes: _activePageClasses(), [text('$page')]);
    }
    return a(href: buildPageUrl!(page), classes: _pageButtonClasses(), [text('$page')]);
  }

  Component _buildEllipsis() {
    return span(classes: _ellipsisClasses(), [text('...')]);
  }

  /// Determines if a page number should be shown.
  /// Shows first, last, and pages within 1 of the current page.
  bool _shouldShowPage(int page) {
    if (page == 1 || page == totalPages) return true;
    if (page >= currentPage - 1 && page <= currentPage + 1) return true;
    return false;
  }

  String _navButtonClasses() {
    return 'inline-flex items-center justify-center px-2 py-2 text-sm font-medium text-gray-400 bg-gray-800 hover:bg-gray-700 transition-colors';
  }

  String _pageButtonClasses() {
    return 'inline-flex items-center justify-center px-4 py-2 text-sm font-medium text-gray-300 bg-gray-800 hover:bg-gray-700 transition-colors';
  }

  String _activePageClasses() {
    return 'inline-flex items-center justify-center px-4 py-2 text-sm font-semibold text-white bg-primary-600 transition-colors';
  }

  String _ellipsisClasses() {
    return 'inline-flex items-center justify-center px-4 py-2 text-sm font-medium text-gray-500 bg-gray-800';
  }
}
