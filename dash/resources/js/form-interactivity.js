/**
 * Lightweight event dispatcher for form field interactivity.
 *
 * Fields emit `field:changed` and `field:<name>:changed` events with the
 * latest value, allowing dependent fields to react without a full reload.
 */
function createDispatcher() {
  const listeners = new Map();

  function on(event, callback) {
    if (!listeners.has(event)) {
      listeners.set(event, new Set());
    }
    listeners.get(event).add(callback);
  }

  function off(event, callback) {
    if (!listeners.has(event)) return;
    listeners.get(event).delete(callback);
  }

  function emit(event, payload) {
    if (listeners.has(event)) {
      for (const callback of listeners.get(event)) {
        try {
          callback(payload);
        } catch (err) {
          console.error('[FormEvents] listener error', err);
        }
      }
    }
    if (listeners.has('*')) {
      for (const callback of listeners.get('*')) {
        try {
          callback({ event, payload });
        } catch (err) {
          console.error('[FormEvents] wildcard listener error', err);
        }
      }
    }
  }

  return { on, off, emit };
}

function normalizeValue(value) {
  if (value === null || value === undefined) return null;
  if (Array.isArray(value)) return value.map(normalizeValue);
  if (typeof value === 'string') {
    const lower = value.toLowerCase();
    if (lower === 'true') return true;
    if (lower === 'false') return false;
  }
  return value;
}

function isTruthy(value) {
  if (value === null || value === undefined) return false;
  if (Array.isArray(value)) return value.length > 0;
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value !== 0;
  if (typeof value === 'string') {
    if (value.trim() === '') return false;
    const lower = value.toLowerCase();
    return lower !== 'false' && lower !== '0';
  }
  return true;
}

function evaluateCondition(condition, state) {
  const comparator = condition?.comparator;
  const targetField = condition?.field;
  if (!comparator || !targetField) return true;

  const current = normalizeValue(state[targetField]);
  const expected = normalizeValue(condition.value);
  const list = (condition.values || []).map(normalizeValue);

  switch (comparator) {
    case 'equals':
      return current === expected;
    case 'notEquals':
      return current !== expected;
    case 'inList':
      return list.includes(current);
    case 'notInList':
      return !list.includes(current);
    case 'truthy':
      return isTruthy(current);
    case 'falsy':
      return !isTruthy(current);
    default:
      return true;
  }
}

function toggleVisibility(wrapper, shouldShow) {
  if (!wrapper) return;
  if (shouldShow) {
    wrapper.classList.remove('hidden');
    wrapper.dataset.fieldHidden = 'false';
    wrapper.removeAttribute('aria-hidden');
  } else {
    wrapper.classList.add('hidden');
    wrapper.dataset.fieldHidden = 'true';
    wrapper.setAttribute('aria-hidden', 'true');
  }
}

function readFieldValue(wrapper, fieldName) {
  if (!wrapper) return null;

  const checkbox = wrapper.querySelector(`input[type="checkbox"][name="${fieldName}"]`);
  if (checkbox) {
    const offInput = wrapper.querySelector(`input[type="hidden"][name="${fieldName}"]`);
    const offValue = offInput ? offInput.value : '0';
    return checkbox.checked ? checkbox.value ?? '1' : offValue;
  }

  const radios = Array.from(wrapper.querySelectorAll(`input[type="radio"][name="${fieldName}"]`));
  if (radios.length > 0) {
    const checked = radios.find((input) => input.checked);
    return checked ? checked.value : null;
  }

  const selectEl = wrapper.querySelector(`select[name="${fieldName}"]`);
  if (selectEl) {
    if (selectEl.multiple) {
      return Array.from(selectEl.selectedOptions).map((opt) => opt.value);
    }
    return selectEl.value;
  }

  const textarea = wrapper.querySelector(`textarea[name="${fieldName}"]`);
  if (textarea) return textarea.value;

  const input = wrapper.querySelector(`input[name="${fieldName}"]`);
  if (input) return input.value;

  return null;
}

function attachLiveListeners(wrapper, fieldName, state, dispatcher) {
  const inputs = wrapper.querySelectorAll('input:not([type="hidden"]), select, textarea');

  const handler = () => {
    const value = readFieldValue(wrapper, fieldName);
    state[fieldName] = value;
    const payload = { name: fieldName, value, state: { ...state } };
    dispatcher.emit('field:changed', payload);
    dispatcher.emit(`field:${fieldName}:changed`, payload);
  };

  inputs.forEach((el) => {
    el.addEventListener('input', handler);
    el.addEventListener('change', handler);
  });
}

function setupVisibility(wrapper, condition, state, dispatcher) {
  if (!condition) return;
  const dependency = condition.field;
  const update = () => {
    const nextVisible = evaluateCondition(condition, state);
    toggleVisibility(wrapper, nextVisible);
  };

  dispatcher.on(`field:${dependency}:changed`, (payload) => {
    state[payload.name] = payload.value;
    update();
  });

  // Initial evaluation
  update();
}

function bootstrapForm(form, dispatcher) {
  const wrappers = Array.from(form.querySelectorAll('[data-field-name]'));
  const state = {};

  // Seed state before wiring listeners
  wrappers.forEach((wrapper) => {
    const name = wrapper.dataset.fieldName;
    if (!name) return;
    state[name] = readFieldValue(wrapper, name);
  });

  wrappers.forEach((wrapper) => {
    const name = wrapper.dataset.fieldName;
    if (!name) return;

    const live = wrapper.dataset.fieldLive !== 'false';
    const conditionRaw = wrapper.dataset.visibleWhen;
    const condition = conditionRaw ? safeParse(conditionRaw) : null;

    if (condition) {
      setupVisibility(wrapper, condition, state, dispatcher);
    } else if (wrapper.dataset.fieldHidden === 'true') {
      toggleVisibility(wrapper, false);
    }

    if (live) {
      attachLiveListeners(wrapper, name, state, dispatcher);
    }
  });
}

function safeParse(raw) {
  try {
    return JSON.parse(raw);
  } catch (err) {
    console.warn('[FormEvents] failed to parse condition', raw, err);
    return null;
  }
}

export function initFormInteractivity() {
  const dispatcher = createDispatcher();
  // Expose for debugging / custom listeners
  window.DashFieldEvents = dispatcher;

  const ready = () => {
    document.querySelectorAll('form').forEach((form) => bootstrapForm(form, dispatcher));
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', ready, { once: true });
  } else {
    ready();
  }
}

// Export helpers for testing if needed
export const _test = { createDispatcher, evaluateCondition, normalizeValue, isTruthy };
