/// Basic CSS styles for the Dash admin panel.
///
/// This provides minimal styling to make the admin panel functional.
/// In the future, this will be replaced with a proper theming system.
const String dashStyles = '''
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  font-size: 14px;
  line-height: 1.5;
  color: #e5e7eb;
  background: #111827;
}

/* Login Page */
.login-page {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.login-container {
  width: 100%;
  max-width: 400px;
  padding: 20px;
}

.login-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
  padding: 40px;
}

.login-header {
  text-align: center;
  margin-bottom: 30px;
}

.login-header h1 {
  font-size: 32px;
  font-weight: bold;
  color: #667eea;
  margin-bottom: 8px;
}

.login-header p {
  color: #6b7280;
}

/* Form Styles */
.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 6px;
  font-weight: 500;
  color: #374151;
}

.form-group input[type="email"],
.form-group input[type="password"],
.form-group input[type="text"] {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 14px;
  transition: border-color 0.2s;
}

.form-group input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

/* Buttons */
.btn-primary,
button[type="submit"] {
  padding: 8px 16px;
  background: #84cc16;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.btn-primary:hover,
button[type="submit"]:hover {
  background: #65a30d;
}

/* Layout */
.dash-layout {
  display: flex;
  min-height: 100vh;
}

.dash-sidebar {
  width: 250px;
  background: #1f2937;
  color: white;
  display: flex;
  flex-direction: column;
}

.dash-logo {
  padding: 20px;
  border-bottom: 1px solid #374151;
}

.dash-logo h2 {
  font-size: 24px;
  font-weight: bold;
  color: #667eea;
}

.dash-nav {
  flex: 1;
  padding: 20px 0;
}

.dash-nav ul {
  list-style: none;
}

.dash-nav li {
  margin-bottom: 4px;
}

.dash-nav li.nav-group-header {
  margin-top: 20px;
  margin-bottom: 8px;
  padding: 8px 20px;
}

.dash-nav li.nav-group-header:first-child {
  margin-top: 0;
}

.dash-nav li.nav-group-header span {
  font-size: 11px;
  text-transform: uppercase;
  font-weight: 600;
  letter-spacing: 0.5px;
  color: #9ca3af;
}

.nav-icon {
  width: 1.25rem;
  height: 1.25rem;
  margin-right: 0.75rem;
  display: inline-block;
  vertical-align: middle;
  flex-shrink: 0;
}

.dash-nav a {
  display: flex;
  align-items: center;
  padding: 12px 20px;
  color: #d1d5db;
  text-decoration: none;
  transition: all 0.2s;
}

.dash-nav a span {
  display: inline-block;
}

.dash-nav a:hover {
  background: #374151;
  color: white;
}

.dash-sidebar-footer {
  padding: 20px;
  border-top: 1px solid #374151;
}

.logout-button {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 10px;
  text-align: center;
  color: #d1d5db;
  text-decoration: none;
  border: 1px solid #374151;
  border-radius: 6px;
  transition: all 0.2s;
  gap: 0.5rem;
}

.logout-button:hover {
  background: #374151;
  color: white;
}

.dash-main {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.dash-header {
  background: white;
  border-bottom: 1px solid #e5e7eb;
  padding: 20px 30px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.dash-header h1 {
  font-size: 24px;
  font-weight: 600;
  color: #1f2937;
}

.dash-content {
  flex: 1;
  padding: 30px;
}

/* Dashboard */
.dashboard-widgets {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.widget-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  padding: 20px;
}

.widget-card h3 {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 12px;
  color: #1f2937;
}

.widget-card ul {
  list-style: none;
}

.widget-card li {
  padding: 8px 0;
  border-bottom: 1px solid #f3f4f6;
}

.widget-card li:last-child {
  border-bottom: none;
}

/* Resource Views */
.resource-content {
  background: white;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  padding: 20px;
}

/* Resource Index & Table Styles */
.resource-index-container {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

/* Breadcrumbs */
.breadcrumbs {
  font-size: 14px;
}

.breadcrumb-list {
  display: flex;
  align-items: center;
  list-style: none;
  gap: 8px;
}

.breadcrumb-item {
  display: inline-flex;
}

.breadcrumb-link {
  color: #9ca3af;
  text-decoration: none;
  transition: color 0.2s;
}

.breadcrumb-link:hover {
  color: #e5e7eb;
}

.breadcrumb-current {
  color: #e5e7eb;
}

.breadcrumb-separator {
  color: #6b7280;
  user-select: none;
}

/* Page Header */
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
}

.page-header-title {
  font-size: 32px;
  font-weight: 700;
  color: #f9fafb;
  margin: 0;
}

.page-header-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

/* Table Card */
.resource-table-card {
  background: #1f2937;
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid #374151;
}

.table-header-actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 12px;
  padding: 16px 24px;
  background: #1f2937;
  border-bottom: 1px solid #374151;
}

.resource-search {
  flex: 1;
  max-width: 320px;
}

.search-input {
  width: 100%;
  padding: 8px 12px;
  background: #111827;
  border: 1px solid #374151;
  border-radius: 6px;
  font-size: 14px;
  color: #e5e7eb;
  transition: all 0.2s;
}

.search-input:focus {
  outline: none;
  border-color: #4b5563;
  background: #0f172a;
}

.search-input::placeholder {
  color: #6b7280;
}

/* Table */
.table-container {
  overflow-x: auto;
  border-top: 1px solid #374151;
}

.resource-table {
  width: 100%;
  border-collapse: collapse;
}

.resource-table thead {
  background: #1f2937;
  border-bottom: 1px solid #374151;
}

.table-header-cell {
  padding: 12px 20px;
  text-align: left;
  font-weight: 500;
  font-size: 13px;
  color: #9ca3af;
  white-space: nowrap;
}

.table-header-content {
  display: flex;
  align-items: center;
  gap: 6px;
}

.header-link {
  color: inherit;
  text-decoration: none;
  display: block;
}

.header-link:hover .header-label {
  color: #e5e7eb;
}

.sort-indicator {
  font-size: 12px;
  color: #6b7280;
  cursor: pointer;
}

.sort-indicator.sort-asc,
.sort-indicator.sort-desc {
  color: #e5e7eb;
}

.table-row {
  transition: background 0.15s;
  background: #1f2937;
  border-bottom: 1px solid #374151;
}

.table-row:hover {
  background: #374151;
}

.table-striped tbody tr:nth-child(even) {
  background: #1a1f2e;
}

.table-striped tbody tr:nth-child(even):hover {
  background: #374151;
}

.table-cell {
  padding: 16px 20px;
  color: #e5e7eb;
  font-size: 14px;
}

/* Column Alignment */
.align-start {
  text-align: left;
}

.align-center {
  text-align: center;
}

.align-end {
  text-align: right;
}

/* Column Content */
.column-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.column-text {
  font-size: 14px;
  color: #e5e7eb;
}

.column-description {
  font-size: 12px;
  color: #9ca3af;
}

.column-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
  margin-right: 6px;
}

.column-link {
  color: #60a5fa;
  text-decoration: none;
}

.column-link:hover {
  text-decoration: underline;
}

/* Badges */
.badge {
  display: inline-block;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
  white-space: nowrap;
}

.badge-default {
  background: #f3f4f6;
  color: #374151;
}

.badge-primary {
  background: #dbeafe;
  color: #1e40af;
}

.badge-success {
  background: #d1fae5;
  color: #065f46;
}

.badge-danger {
  background: #fee2e2;
  color: #991b1b;
}

.badge-warning {
  background: #fef3c7;
  color: #92400e;
}

.badge-info {
  background: #dbeafe;
  color: #1e40af;
}

/* Icons with colors */
.icon-success {
  color: #10b981;
}

.icon-danger {
  color: #ef4444;
}

.icon-warning {
  color: #f59e0b;
}

.icon-info {
  color: #3b82f6;
}

.icon-default {
  color: #6b7280;
}

/* Empty State */
.empty-state {
  padding: 60px 24px;
  text-align: center;
}

.empty-state-content {
  max-width: 400px;
  margin: 0 auto;
}

.empty-state-icon {
  font-size: 48px;
  margin-bottom: 16px;
}

.empty-state-heading {
  font-size: 18px;
  font-weight: 600;
  color: #f9fafb;
  margin-bottom: 8px;
}

.empty-state-description {
  font-size: 14px;
  color: #9ca3af;
  margin-bottom: 24px;
}

/* Pagination */
.pagination {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  border-top: 1px solid #374151;
}

.pagination-info {
  font-size: 14px;
  color: #9ca3af;
}

.pagination-controls {
  display: flex;
  gap: 8px;
}

.pagination-ellipsis {
  display: flex;
  align-items: center;
  padding: 0 8px;
  color: #6b7280;
}

/* Button Variants */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 8px 16px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  text-decoration: none;
}

.btn-icon {
  font-size: 16px;
}

.btn-secondary {
  padding: 6px 12px;
  background: #374151;
  color: #9ca3af;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s;
  text-decoration: none;
  display: inline-block;
}

.btn-secondary:hover:not(.disabled) {
  background: #4b5563;
  color: #e5e7eb;
}

.btn-secondary.active {
  background: #1f2937;
  color: #e5e7eb;
  font-weight: 600;
}

.btn-secondary.disabled,
.btn-secondary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Column Toggle */
.column-toggle {
  position: relative;
}

.column-toggle-button {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.column-toggle-menu {
  position: absolute;
  right: 0;
  top: calc(100% + 8px);
  min-width: 220px;
  background: #111827;
  border: 1px solid #374151;
  border-radius: 8px;
  padding: 12px;
  box-shadow: 0 12px 30px rgba(0, 0, 0, 0.35);
  z-index: 50;
}

.column-toggle-header {
  font-size: 13px;
  font-weight: 600;
  color: #f9fafb;
  margin-bottom: 8px;
}

.column-toggle-options {
  list-style: none;
  margin: 0 0 12px;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.column-toggle-option {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 8px;
  border: 1px solid transparent;
  border-radius: 6px;
  background: transparent;
  color: #e5e7eb;
  cursor: pointer;
  transition: all 0.2s;
}

.column-toggle-option:hover {
  background: #1f2937;
}

.column-toggle-option.active {
  border-color: #4b5563;
  background: #0f172a;
}

.column-toggle-check {
  width: 1.25rem;
  text-align: center;
  color: #84cc16;
  font-weight: 700;
}

.column-toggle-label {
  flex: 1;
  font-size: 13px;
}

.column-toggle-footer {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.column-hidden {
  display: none !important;
}

/* HTMX Loading Indicator */
.htmx-indicator {
  display: none;
}

.htmx-request .htmx-indicator,
.htmx-request.htmx-indicator {
  display: inline-block;
}

.loading-indicator {
  position: fixed;
  top: 20px;
  right: 20px;
  background: #3b82f6;
  color: white;
  padding: 12px 20px;
  border-radius: 8px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  font-size: 14px;
  font-weight: 500;
  z-index: 1000;
  animation: slideIn 0.3s ease;
}

@keyframes slideIn {
  from {
    transform: translateX(100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

/* Sortable Header Links */
.header-link {
  display: block;
  color: inherit;
  text-decoration: none;
  cursor: pointer;
  transition: color 0.2s;
}

.header-link:hover {
  color: #3b82f6;
}

.table-header-content {
  display: flex;
  align-items: center;
  gap: 8px;
}

/* Alpine.js x-cloak support */
[x-cloak] {
  display: none !important;
}
''';
