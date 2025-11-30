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
    debug: window.DashWireConfig?.debug || false,
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
   * Parse wire:click directive value
   * Supports: "method" or "method(arg1, arg2)"
   */
  function parseAction(value) {
    const match = value.match(/^(\w+)(?:\(([^)]*)\))?$/);
    if (!match) return null;
    
    const [, method, argsStr] = match;
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

    return { method, params };
  }

  /**
   * Collect all wire:model values from the component
   * Supports both wire:model and wire:model.blur
   */
  function collectModelValues(wrapper) {
    const models = {};
    
    // Collect wire:model values
    wrapper.querySelectorAll('[wire\\:model]').forEach(el => {
      const property = el.getAttribute('wire:model');
      if (property) {
        models[property] = getInputValue(el);
      }
    });
    
    // Also collect wire:model.blur values
    wrapper.querySelectorAll('[wire\\:model\\.blur]').forEach(el => {
      const property = el.getAttribute('wire:model.blur');
      if (property) {
        models[property] = getInputValue(el);
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

    // Use Idiomorph if available (recommended)
    if (window.Idiomorph) {
      log('Morphing with Idiomorph');
      window.Idiomorph.morph(wrapper, newWrapper, {
        morphStyle: 'outerHTML',
        callbacks: {
          beforeNodeMorphed: (oldNode, newNode) => {
            // Preserve focus state
            if (oldNode === document.activeElement) {
              setTimeout(() => newNode.focus?.(), 0);
            }
            return true;
          },
        },
      });
    } else if (window.morphdom) {
      // Fallback to morphdom
      log('Morphing with morphdom');
      window.morphdom(wrapper, newWrapper, {
        onBeforeElUpdated: (fromEl, toEl) => {
          // Preserve focus
          if (fromEl === document.activeElement && fromEl.tagName === 'INPUT') {
            const selStart = fromEl.selectionStart;
            const selEnd = fromEl.selectionEnd;
            requestAnimationFrame(() => {
              if (toEl.setSelectionRange) {
                toEl.focus();
                toEl.setSelectionRange(selStart, selEnd);
              }
            });
          }
          return true;
        },
      });
    } else {
      // Simple fallback - replace inner content and update attributes
      log('Replacing content (no morph library)');
      
      // Update the wire:initial-data attribute with new state
      const newData = newWrapper.getAttribute('wire:initial-data');
      if (newData) {
        wrapper.setAttribute('wire:initial-data', newData);
      }
      
      // Update wire:listeners if changed
      const newListeners = newWrapper.getAttribute('wire:listeners');
      if (newListeners !== null) {
        wrapper.setAttribute('wire:listeners', newListeners);
      }
      
      // Replace inner HTML
      wrapper.innerHTML = newWrapper.innerHTML;
    }

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
    const wrapper = findComponent(element);
    if (!wrapper) return;

    const componentData = getComponentData(wrapper);
    const parsed = parseAction(action);
    
    if (!parsed) {
      console.error('[DashWire] Invalid action:', action);
      return;
    }

    // Show loading state
    wrapper.setAttribute('wire:loading', '');
    element.setAttribute('wire:loading', '');

    try {
      const modelValues = collectModelValues(wrapper);
      
      const response = await sendWireRequest(componentData, {
        action: parsed.method,
        params: parsed.params,
        models: modelValues,
      });

      morphComponent(wrapper, response.html);
      
      // Broadcast any dispatched events to other components
      if (response.events && response.events.length > 0) {
        await broadcastEvents(response.events, componentData.id);
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

    const property = element.getAttribute('wire:model');
    const modifier = element.getAttribute('wire:model.lazy') !== null ? 'lazy' : 
                     element.getAttribute('wire:model.debounce') !== null ? 'debounce' : 
                     'live';

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

    // Debounce the request
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
    const parsed = parseAction(action);
    
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
    document.addEventListener('click', (e) => {
      const target = e.target.closest('[wire\\:click]');
      if (target) {
        e.preventDefault();
        const action = target.getAttribute('wire:click');
        handleAction(target, action);
      }
    });

    // Input handler for wire:model (live updates)
    document.addEventListener('input', (e) => {
      const target = e.target.closest('[wire\\:model]');
      if (target && !target.hasAttribute('wire:model.lazy')) {
        handleModelUpdate(target);
      }
    });

    // Change handler for wire:model.lazy and select/checkbox/radio
    document.addEventListener('change', (e) => {
      const target = e.target.closest('[wire\\:model]');
      if (target) {
        // Always update on change for non-text inputs or lazy models
        if (target.hasAttribute('wire:model.lazy') || 
            target.type === 'checkbox' || 
            target.type === 'radio' ||
            target.tagName === 'SELECT') {
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
   */
  function initAlpineIntegration() {
    if (!window.Alpine) {
      log('Alpine.js not found, skipping integration');
      return;
    }

    document.addEventListener('alpine:init', () => {
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
    });
  }

  // Initialize
  initEventListeners();
  initAlpineIntegration();

  // Expose global API
  window.DashWire = {
    config,
    sendRequest: sendWireRequest,
    morph: morphComponent,
    findComponent,
    getComponentData,
    dispatch: dispatchEvent,
    broadcast: broadcastEvents,
  };

  log('DashWire initialized');
}

// Note: initDashWire is called from app.js, not auto-initialized here
// to prevent double initialization when bundled.
