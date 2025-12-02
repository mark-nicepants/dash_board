/**
 * DashWire - Interactive Component System
 * 
 * A Livewire-like system for Dash that enables server-driven interactive components.
 * Components render on the server, and this script handles:
 * - wire:* directive parsing and binding
 * - Server communication for actions and model updates
 * - DOM morphing for efficient updates
 * - Event dispatching between components
 * 
 * @example
 * ```html
 * <div wire:id="counter" wire:name="Counter" wire:initial-data="..." wire:listeners="count-updated">
 *   <span>Count: 5</span>
 *   <button wire:click="increment">+</button>
 *   <button wire:click="decrement">-</button>
 *   <input wire:model="name" type="text">
 * </div>
 * ```
 */

import { Idiomorph } from 'idiomorph';

export function initDashWire() {
  /**
   * Configuration
   */
  const config = {
    /** Base path for wire requests */
    basePath: window.DashWireConfig?.basePath || '/dash/wire',
    /** Debounce delay for wire:model updates (ms) */
    modelDebounce: window.DashWireConfig?.modelDebounce || 150,
    /** Enable debug logging */
    debug: window.DashWireConfig?.debug || true,
  };

  /**
   * Debug logger
   */
  function log(...args) {
    if (config.debug) {
      console.log('[DashWire]', ...args);
    }
  }

  /**
   * Toast notification system
   */
  function getOrCreateToastContainer() {
    let container = document.getElementById('dash-toast-container');
    if (!container) {
      container = document.createElement('div');
      container.id = 'dash-toast-container';
      container.className = 'fixed top-4 right-4 z-[100] flex flex-col gap-2';
      document.body.appendChild(container);
    }
    return container;
  }

  function showToast(message, type = 'success', duration = 4000) {
    const container = getOrCreateToastContainer();
    
    const toast = document.createElement('div');
    toast.className = `
      flex items-center gap-3 px-4 py-3 rounded-lg shadow-lg border
      transform transition-all duration-300 ease-out
      translate-x-full opacity-0
      ${type === 'success' 
        ? 'bg-green-900/90 border-green-700 text-green-100' 
        : 'bg-red-900/90 border-red-700 text-red-100'}
    `;
    
    // Icon
    const icon = type === 'success'
      ? `<svg class="w-5 h-5 text-green-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
           <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
         </svg>`
      : `<svg class="w-5 h-5 text-red-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
           <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
         </svg>`;
    
    toast.innerHTML = `
      ${icon}
      <span class="text-sm font-medium">${message}</span>
      <button class="ml-2 text-gray-400 hover:text-white transition-colors" onclick="this.parentElement.remove()">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
        </svg>
      </button>
    `;
    
    container.appendChild(toast);
    
    // Trigger animation
    requestAnimationFrame(() => {
      toast.classList.remove('translate-x-full', 'opacity-0');
      toast.classList.add('translate-x-0', 'opacity-100');
    });
    
    // Auto remove
    setTimeout(() => {
      toast.classList.add('translate-x-full', 'opacity-0');
      setTimeout(() => toast.remove(), 300);
    }, duration);
  }

  /**
   * Find the wire component wrapper for an element
   */
  function findComponent(element) {
    return element.closest('[wire\\:id]');
  }

  /**
   * Get all wire components on the page
   */
  function getAllComponents() {
    return document.querySelectorAll('[wire\\:id]');
  }

  /**
   * Get component data from a wire wrapper element
   */
  function getComponentData(wrapper) {
    return {
      id: wrapper.getAttribute('wire:id'),
      name: wrapper.getAttribute('wire:name'),
      data: wrapper.getAttribute('wire:initial-data'),
      listeners: (wrapper.getAttribute('wire:listeners') || '').split(',').filter(Boolean),
    };
  }

  /**
   * Find a wire:model attribute on an element and return its property name and modifier info.
   * Supports: wire:model, wire:model.lazy, wire:model.blur, wire:model.debounce, wire:model.debounce.Xms
   * @returns {{ property: string, modifier: string, debounceMs: number } | null}
   */
  function getWireModelInfo(element) {
    // Check all attributes for wire:model patterns
    for (const attr of element.attributes) {
      if (attr.name.startsWith('wire:model')) {
        const property = attr.value;
        const parts = attr.name.split('.');
        
        let modifier = 'live';
        let debounceMs = config.modelDebounce;
        
        if (parts.includes('lazy')) {
          modifier = 'lazy';
        } else if (parts.includes('blur')) {
          modifier = 'blur';
        } else if (parts.includes('debounce')) {
          modifier = 'debounce';
          // Check for custom debounce time (e.g., wire:model.debounce.300ms)
          const timeIndex = parts.findIndex(p => p.match(/^\d+ms$/));
          if (timeIndex !== -1) {
            debounceMs = parseInt(parts[timeIndex].replace('ms', ''), 10);
          }
        }
        
        return { property, modifier, debounceMs };
      }
    }
    return null;
  }

  /**
   * Check if an element has any wire:model attribute
   */
  function hasWireModel(element) {
    return Array.from(element.attributes).some(attr => attr.name.startsWith('wire:model'));
  }

  /**
   * Parse wire:click directive value
   * Supports: "method" or "method(arg1, arg2)" or "method(arg1, arg2, $formData)"
   */
  function parseAction(value, element) {
    log('parseAction called with:', value);
    
    // Check if this action includes $formData marker
    const hasFormData = value.includes('$formData');
    // Remove $formData from the string for regex matching
    const cleanedValue = value.replace(/,\s*\$formData/, '');
    
    const match = cleanedValue.match(/^(\w+)(?:\(([^)]*)\))?$/);
    if (!match) {
      log('parseAction regex did not match for:', cleanedValue);
      return null;
    }
    
    const [, method, argsStr] = match;
    log('parseAction matched method:', method, 'argsStr:', argsStr, 'hasFormData:', hasFormData);
    const params = argsStr 
      ? argsStr.split(',').map(arg => {
          const trimmed = arg.trim();
          // Try to parse as JSON value
          try {
            return JSON.parse(trimmed);
          } catch {
            // Return as string (strip quotes if present)
            return trimmed.replace(/^['"]|['"]$/g, '');
          }
        })
      : [];
    
    // If this action needs form data, collect it from the modal
    if (hasFormData && element) {
      const formData = collectModalFormData(element);
      params.push(formData);
    }

    log('parseAction final params:', params);
    return { method, params };
  }
  
  /**
   * Collect form data from a modal's form element
   * The button might be in the footer which is a sibling of the content area,
   * so we need to find the modal container first and then search for the form.
   */
  function collectModalFormData(element) {
    // Find the modal container (role="dialog" or has x-show="open")
    const modal = element.closest('[role="dialog"]') || element.closest('[x-show="open"]');
    if (!modal) {
      log('collectModalFormData: No modal container found');
      return {};
    }
    
    // Find form within the modal
    const form = modal.querySelector('form');
    if (!form) {
      log('collectModalFormData: No form found in modal');
      return {};
    }
    
    const formData = {};
    const elements = form.elements;
    
    for (let i = 0; i < elements.length; i++) {
      const el = elements[i];
      if (!el.name) continue;
      
      if (el.type === 'checkbox') {
        formData[el.name] = el.checked;
      } else if (el.type === 'radio') {
        if (el.checked) {
          formData[el.name] = el.value;
        }
      } else if (el.tagName === 'SELECT' && el.multiple) {
        formData[el.name] = Array.from(el.selectedOptions).map(opt => opt.value);
      } else {
        formData[el.name] = el.value;
      }
    }
    
    log('collectModalFormData: Collected form data:', formData);
    return formData;
  }

  /**
   * Collect all wire:model values from the component
   * Supports wire:model, wire:model.blur, wire:model.lazy, wire:model.debounce.*
   */
  function collectModelValues(wrapper) {
    const models = {};
    
    // Find all elements and check for any wire:model attribute
    wrapper.querySelectorAll('input, select, textarea').forEach(el => {
      const modelInfo = getWireModelInfo(el);
      if (modelInfo) {
        models[modelInfo.property] = getInputValue(el);
      }
    });
    
    return models;
  }

  /**
   * Get the value from an input element
   */
  function getInputValue(element) {
    if (element.type === 'checkbox') {
      return element.checked;
    }
    if (element.type === 'radio') {
      const name = element.name;
      const wrapper = findComponent(element);
      const checked = wrapper?.querySelector(`input[name="${name}"]:checked`);
      return checked?.value;
    }
    if (element.tagName === 'SELECT' && element.multiple) {
      return Array.from(element.selectedOptions).map(opt => opt.value);
    }
    return element.value;
  }

  /**
   * Send a wire request to the server
   * Returns { html: string, events: Array<{name, payload}> }
   */
  async function sendWireRequest(componentData, payload) {
    const url = `${config.basePath}/${componentData.id}`;
    
    log('Sending request:', url, payload);

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Wire-Request': 'true',
      },
      body: JSON.stringify({
        name: componentData.name,
        state: componentData.data,
        ...payload,
      }),
    });

    if (!response.ok) {
      throw new Error(`Wire request failed: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    return data;
  }

  /**
   * Broadcast events to listening components
   */
  async function broadcastEvents(events, sourceComponentId) {
    if (!events || events.length === 0) return;

    log('Broadcasting events:', events);

    // Find all components that listen to these events
    const allComponents = getAllComponents();
    
    for (const event of events) {
      const { name, payload } = event;
      
      log(`Broadcasting event "${name}" with payload:`, payload);

      // Handle system events
      if (name === 'update-url' && payload.url) {
        log('Updating URL to:', payload.url);
        window.history.pushState({}, '', payload.url);
        continue;
      }
      
      // Handle toast notifications
      if (name === 'action-success' && payload.message) {
        showToast(payload.message, 'success');
        continue;
      }
      
      if (name === 'action-error' && payload.message) {
        showToast(payload.message, 'error');
        continue;
      }

      // Find components listening to this event
      for (const wrapper of allComponents) {
        // Don't send event back to the source component
        if (wrapper.getAttribute('wire:id') === sourceComponentId) continue;

        const componentData = getComponentData(wrapper);
        
        // Check if this component listens to this event
        if (componentData.listeners.includes(name)) {
          log(`Component "${componentData.id}" is listening to "${name}"`);
          
          // Send the event to this component
          try {
            wrapper.setAttribute('wire:loading', '');
            
            const response = await sendWireRequest(componentData, {
              event: { name, payload },
            });

            morphComponent(wrapper, response.html);
            
            // Recursively broadcast any events from this component
            if (response.events && response.events.length > 0) {
              await broadcastEvents(response.events, componentData.id);
            }
          } catch (error) {
            console.error(`[DashWire] Failed to send event to ${componentData.id}:`, error);
          } finally {
            wrapper.removeAttribute('wire:loading');
          }
        }
      }
    }
  }

  /**
   * Morph the old DOM to match the new HTML
   * Uses idiomorph if available, falls back to innerHTML replacement
   */
  function morphComponent(wrapper, newHtml) {
    // Create a temporary container to parse the new HTML
    const template = document.createElement('template');
    template.innerHTML = newHtml.trim();
    const newWrapper = template.content.firstElementChild;

    if (!newWrapper) {
      console.error('[DashWire] Invalid response HTML');
      return;
    }

    const wireId = wrapper.getAttribute('wire:id');
    
    // Capture focus state before morphing
    const activeElement = document.activeElement;
    const hadFocus = wrapper.contains(activeElement);
    let focusSelector = null;
    let selectionStart = null;
    let selectionEnd = null;
    
    if (hadFocus && activeElement) {
      // Build a selector to find the element after morphing
      // Try to use wire:model attribute first, then name, then generate a path
      const modelInfo = getWireModelInfo(activeElement);
      
      if (modelInfo) {
        // Find by any wire:model attribute with this property value
        for (const attr of activeElement.attributes) {
          if (attr.name.startsWith('wire:model') && attr.value === modelInfo.property) {
            // Escape special characters in attribute name for CSS selector (: and .)
            const escapedAttrName = attr.name.replace(/:/g, '\\:').replace(/\./g, '\\.');
            focusSelector = `[${escapedAttrName}="${modelInfo.property}"]`;
            break;
          }
        }
      } else if (activeElement.name) {
        focusSelector = `[name="${activeElement.name}"]`;
      } else if (activeElement.id) {
        focusSelector = `#${activeElement.id}`;
      }
      
      // Preserve cursor position for text inputs
      if (activeElement.setSelectionRange) {
        selectionStart = activeElement.selectionStart;
        selectionEnd = activeElement.selectionEnd;
      }
      
      log('Captured focus state:', { focusSelector, selectionStart, selectionEnd });
    }

    // Clean up Alpine components before morphing to prevent transition errors
    if (window.Alpine) {
      // Destroy Alpine state on elements that will be removed/replaced
      // This prevents "Uncaught (in promise)" errors from interrupted transitions
      try {
        window.Alpine.destroyTree(wrapper);
      } catch (e) {
        log('Alpine destroyTree error (ignored):', e);
      }
    }

    // Use Idiomorph for DOM morphing
    log('Morphing with Idiomorph');
    Idiomorph.morph(wrapper, newWrapper, {
      morphStyle: 'outerHTML',
    });

    // Re-initialize Alpine if present
    if (window.Alpine) {
      const newEl = document.querySelector(`[wire\\:id="${wireId}"]`) || wrapper;
      window.Alpine.initTree(newEl);
    }
  }

  /**
   * Handle a wire:click action
   */
  async function handleAction(element, action) {
    log('handleAction called with action:', action);
    log('handleAction element:', element);
    
    const wrapper = findComponent(element);
    if (!wrapper) {
      log('handleAction: No wire component wrapper found');
      return;
    }
    log('handleAction: Found wrapper with wire:id:', wrapper.getAttribute('wire:id'));

    const componentData = getComponentData(wrapper);
    log('handleAction: Component data:', componentData);
    
    const parsed = parseAction(action, element);
    
    if (!parsed) {
      console.error('[DashWire] Invalid action:', action);
      return;
    }
    
    log('handleAction: Parsed action - method:', parsed.method, 'params:', parsed.params);

    // Show loading state
    wrapper.setAttribute('wire:loading', '');
    element.setAttribute('wire:loading', '');

    try {
      // Don't send model values with actions - the serialized state is the source of truth.
      // Model values should only be sent for explicit wire:model updates.
      const requestPayload = {
        action: parsed.method,
        params: parsed.params,
      };
      log('handleAction: Sending wire request with payload:', requestPayload);
      
      const response = await sendWireRequest(componentData, requestPayload);
      log('handleAction: Received response:', response);

      morphComponent(wrapper, response.html);
      
      // Broadcast any dispatched events to other components
      if (response.events && response.events.length > 0) {
        log('Response contains events:', response.events);
        await broadcastEvents(response.events, componentData.id);
      } else {
        log('Response contains no events');
      }
    } catch (error) {
      console.error('[DashWire] Action failed:', error);
    } finally {
      wrapper.removeAttribute('wire:loading');
      element.removeAttribute('wire:loading');
    }
  }

  /**
   * Handle wire:model updates with debouncing
   */
  const modelDebounceTimers = new Map();

  function handleModelUpdate(element) {
    const wrapper = findComponent(element);
    if (!wrapper) return;

    const modelInfo = getWireModelInfo(element);
    if (!modelInfo) {
      log('No wire:model attribute found on element');
      return;
    }

    const { property, modifier, debounceMs } = modelInfo;

    // For lazy, we don't send on every keystroke
    if (modifier === 'lazy') {
      return;
    }

    const componentId = wrapper.getAttribute('wire:id');
    const timerId = `${componentId}:${property}`;

    // Clear existing timer
    if (modelDebounceTimers.has(timerId)) {
      clearTimeout(modelDebounceTimers.get(timerId));
    }

    // Debounce the request (use custom debounce time if specified)
    modelDebounceTimers.set(timerId, setTimeout(async () => {
      modelDebounceTimers.delete(timerId);
      
      const componentData = getComponentData(wrapper);
      const value = getInputValue(element);

      log('Model update:', property, '=', value);

      try {
        const response = await sendWireRequest(componentData, {
          models: { [property]: value },
        });

        morphComponent(wrapper, response.html);
        
        // Broadcast any dispatched events
        if (response.events && response.events.length > 0) {
          await broadcastEvents(response.events, componentData.id);
        }
      } catch (error) {
        console.error('[DashWire] Model update failed:', error);
      }
    }, config.modelDebounce));
  }

  /**
   * Handle wire:model.blur - validates field on blur
   */
  async function handleModelBlur(element) {
    const wrapper = findComponent(element);
    if (!wrapper) return;

    const property = element.getAttribute('wire:model.blur');
    if (!property) return;

    const componentData = getComponentData(wrapper);
    const value = getInputValue(element);
    const modelValues = collectModelValues(wrapper);

    log('Model blur validation:', property, '=', value);

    try {
      const response = await sendWireRequest(componentData, {
        action: 'validateField',
        params: [property],
        models: { ...modelValues, [property]: value },
      });

      morphComponent(wrapper, response.html);
      
      // Broadcast any dispatched events
      if (response.events && response.events.length > 0) {
        await broadcastEvents(response.events, componentData.id);
      }
    } catch (error) {
      console.error('[DashWire] Blur validation failed:', error);
    }
  }

  /**
   * Handle wire:submit on forms
   */
  async function handleSubmit(form, action) {
    const wrapper = findComponent(form);
    if (!wrapper) return;

    const componentData = getComponentData(wrapper);
    const parsed = parseAction(action, form);
    
    if (!parsed) {
      console.error('[DashWire] Invalid submit action:', action);
      return;
    }

    // Show loading state
    wrapper.setAttribute('wire:loading', '');

    try {
      const modelValues = collectModelValues(wrapper);
      
      const response = await sendWireRequest(componentData, {
        action: parsed.method,
        params: parsed.params,
        models: modelValues,
      });

      morphComponent(wrapper, response.html);
      
      // Broadcast any dispatched events
      if (response.events && response.events.length > 0) {
        await broadcastEvents(response.events, componentData.id);
      }
    } catch (error) {
      console.error('[DashWire] Submit failed:', error);
    } finally {
      wrapper.removeAttribute('wire:loading');
    }
  }

  /**
   * Dispatch a custom event from JavaScript
   * Usage: DashWire.dispatch('my-event', { data: 'value' })
   */
  async function dispatchEvent(eventName, payload = {}) {
    log(`Dispatching event "${eventName}" from JS:`, payload);
    await broadcastEvents([{ name: eventName, payload }], null);
  }

  /**
   * Initialize event listeners using event delegation
   */
  function initEventListeners() {
    // Click handler for wire:click
    // Use capture phase to ensure we handle before Alpine
    document.addEventListener('click', (e) => {
      log('Click event detected (capture phase), target:', e.target);
      log('Target tag:', e.target.tagName);
      log('Target classes:', e.target.className);
      
      const target = e.target.closest('[wire\\:click]');
      if (target) {
        log('Found wire:click target:', target);
        log('wire:click attribute value:', target.getAttribute('wire:click'));
        log('Target also has @click:', target.hasAttribute('@click'));
        
        // Get the wire component before any Alpine processing might remove it
        const wrapper = findComponent(target);
        log('Wire component wrapper found:', !!wrapper);
        if (wrapper) {
          log('Wire component id:', wrapper.getAttribute('wire:id'));
        }
        
        e.preventDefault();
        const action = target.getAttribute('wire:click');
        handleAction(target, action);
      } else {
        log('No wire:click target found for element:', e.target);
      }
    }, true); // Use capture phase

    // Input handler for wire:model (live updates)
    // Check if the input element has any wire:model attribute
    document.addEventListener('input', (e) => {
      const target = e.target;
      if (target && hasWireModel(target)) {
        const modelInfo = getWireModelInfo(target);
        // Don't handle lazy models on input - they update on change
        if (modelInfo && modelInfo.modifier !== 'lazy') {
          handleModelUpdate(target);
        }
      }
    });

    // Change handler for wire:model.lazy and select/checkbox/radio
    document.addEventListener('change', (e) => {
      const target = e.target;
      if (target && hasWireModel(target)) {
        const modelInfo = getWireModelInfo(target);
        // Always update on change for non-text inputs or lazy models
        if (modelInfo && (
            modelInfo.modifier === 'lazy' || 
            target.type === 'checkbox' || 
            target.type === 'radio' ||
            target.tagName === 'SELECT')) {
          handleModelUpdate(target);
        }
      }
    });

    // Blur handler for wire:model.blur (validates on blur)
    document.addEventListener('focusout', (e) => {
      const target = e.target.closest('[wire\\:model\\.blur]');
      if (target) {
        handleModelBlur(target);
      }
    });

    // Submit handler for wire:submit
    document.addEventListener('submit', (e) => {
      const form = e.target.closest('form[wire\\:submit]');
      if (form) {
        e.preventDefault();
        const action = form.getAttribute('wire:submit');
        handleSubmit(form, action);
      }
    });

    // Keyboard handlers for wire:keydown.*
    document.addEventListener('keydown', (e) => {
      const key = e.key.toLowerCase();
      const selector = `[wire\\:keydown\\.${key}]`;
      const target = e.target.closest(selector);
      
      if (target) {
        e.preventDefault();
        const action = target.getAttribute(`wire:keydown.${key}`);
        handleAction(target, action);
      }

      // Also check for generic wire:keydown
      const genericTarget = e.target.closest('[wire\\:keydown]');
      if (genericTarget && !target) {
        const action = genericTarget.getAttribute('wire:keydown');
        handleAction(genericTarget, action);
      }
    });

    log('Event listeners initialized');
  }

  /**
   * Alpine.js integration - expose $wire magic property
   * 
   * We register via the `alpine:init` event which fires before Alpine
   * initializes components, allowing us to register our magic.
   */
  function initAlpineIntegration() {
    function registerWireMagic() {
      // Add $wire magic property
      Alpine.magic('wire', (el) => {
        const wrapper = findComponent(el);
        if (!wrapper) return null;

        const componentData = getComponentData(wrapper);

        return {
          // Call a server action
          async call(method, ...params) {
            const modelValues = collectModelValues(wrapper);
            
            const response = await sendWireRequest(componentData, {
              action: method,
              params: params,
              models: modelValues,
            });

            morphComponent(wrapper, response.html);
            
            // Broadcast any dispatched events
            if (response.events && response.events.length > 0) {
              await broadcastEvents(response.events, componentData.id);
            }
          },

          // Dispatch an event to other components
          async dispatch(eventName, payload = {}) {
            await dispatchEvent(eventName, payload);
          },

          // Get/set a property
          get(property) {
            const el = wrapper.querySelector(`[wire\\:model="${property}"]`);
            return el ? getInputValue(el) : undefined;
          },

          async set(property, value) {
            const el = wrapper.querySelector(`[wire\\:model="${property}"]`);
            if (el) {
              if (el.type === 'checkbox') {
                el.checked = value;
              } else {
                el.value = value;
              }
            }

            const response = await sendWireRequest(componentData, {
              models: { [property]: value },
            });

            morphComponent(wrapper, response.html);
            
            // Broadcast any dispatched events
            if (response.events && response.events.length > 0) {
              await broadcastEvents(response.events, componentData.id);
            }
          },

          // Shorthand for calling methods
          __call(method, params) {
            return this.call(method, ...params);
          },
        };
      });

      log('Alpine.js $wire magic registered');
    }

    // Alpine fires `alpine:init` before it initializes the page.
    document.addEventListener('alpine:init', registerWireMagic);
  }

  // Initialize
  initEventListeners();
  initAlpineIntegration();

  /**
   * Snapshot System
   * Restores component state on back/forward navigation to prevent stale UI
   */
  function initSnapshotSystem() {
    if (window.DashWireConfig?.disableSnapshot) return;

    const SNAPSHOT_KEY = 'dash:snapshot:' + window.location.href;

    // Save snapshot before leaving the page
    // We use pagehide as it's more reliable on mobile than beforeunload
    window.addEventListener('pagehide', () => {
      const components = {};
      getAllComponents().forEach(wrapper => {
        const id = wrapper.getAttribute('wire:id');
        if (id) {
          components[id] = wrapper.outerHTML;
        }
      });
      
      try {
        sessionStorage.setItem(SNAPSHOT_KEY, JSON.stringify({
          timestamp: Date.now(),
          components
        }));
      } catch (e) {
        // Ignore quota errors
      }
    });

    // Restore snapshot if navigating back/forward
    window.addEventListener('pageshow', (event) => {
      // Check if this is a back/forward navigation
      // event.persisted is true if loaded from BFCache
      // performance.navigation.type === 2 is BACK_FORWARD (deprecated but useful fallback)
      // performance.getEntriesByType("navigation")[0].type === 'back_forward' is modern way
      
      let isBackForward = event.persisted;
      
      if (!isBackForward && window.performance) {
        const nav = window.performance.getEntriesByType 
          ? window.performance.getEntriesByType("navigation")[0] 
          : null;
          
        if (nav && nav.type === 'back_forward') {
          isBackForward = true;
        } else if (window.performance.navigation && window.performance.navigation.type === 2) {
          isBackForward = true;
        }
      }

      if (isBackForward) {
        try {
          const raw = sessionStorage.getItem(SNAPSHOT_KEY);
          if (!raw) return;

          const snapshot = JSON.parse(raw);
          
          // Only restore if we have components
          if (snapshot && snapshot.components) {
            log('Restoring snapshot from sessionStorage');
            
            Object.entries(snapshot.components).forEach(([id, html]) => {
              const wrapper = document.querySelector(`[wire\\:id="${id}"]`);
              if (wrapper) {
                // Use morph to update the DOM to the saved state
                morphComponent(wrapper, html);
              }
            });
          }
        } catch (e) {
          console.error('[DashWire] Failed to restore snapshot:', e);
        }
      }
    });
  }

  initSnapshotSystem();

  // ============================================================
  // LocalStorage Utilities
  // ============================================================

  /**
   * Load JSON data from localStorage with a prefixed key.
   * @param {string} key - The storage key (will be prefixed with 'dash:')
   * @param {object} defaults - Default values to merge with stored data
   * @returns {object} The stored data merged with defaults
   */
  function storageLoad(key, defaults = {}) {
    const prefixedKey = `dash:${key}`;
    try {
      const raw = window.localStorage.getItem(prefixedKey);
      if (raw) {
        const parsed = JSON.parse(raw);
        return { ...defaults, ...parsed };
      }
    } catch (_) {
      // Ignore storage issues (private browsing, etc.)
    }
    return { ...defaults };
  }

  /**
   * Save JSON data to localStorage with a prefixed key.
   * @param {string} key - The storage key (will be prefixed with 'dash:')
   * @param {object} data - The data to store
   */
  function storageSave(key, data) {
    const prefixedKey = `dash:${key}`;
    try {
      window.localStorage.setItem(prefixedKey, JSON.stringify(data));
    } catch (_) {
      // Ignore persistence failures
    }
  }

  /**
   * Remove data from localStorage.
   * @param {string} key - The storage key (will be prefixed with 'dash:')
   */
  function storageRemove(key) {
    const prefixedKey = `dash:${key}`;
    try {
      window.localStorage.removeItem(prefixedKey);
    } catch (_) {
      // Ignore removal failures
    }
  }

  // Expose global API
  window.DashWire = {
    config,
    sendRequest: sendWireRequest,
    morph: morphComponent,
    findComponent,
    getComponentData,
    dispatch: dispatchEvent,
    broadcast: broadcastEvents,
    // LocalStorage utilities
    storage: {
      load: storageLoad,
      save: storageSave,
      remove: storageRemove,
    },
  };

  log('DashWire initialized');
}