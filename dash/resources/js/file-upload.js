/**
 * File Upload Alpine.js Component
 *
 * Provides drag-and-drop file uploads with HTMX integration,
 * progress tracking, and image previews.
 */

export function initFileUpload() {
  document.addEventListener('alpine:init', () => {
    Alpine.data('fileUpload', ({ fieldName, files = [], config = {}, disabled = false }) => ({
      // State
      files,
      dragging: false,
      uploading: false,
      progress: 0,
      error: null,
      disabled,
      config,
      fieldName,

      /**
       * Handle files dropped onto the dropzone
       */
      handleDrop(event) {
        this.dragging = false;
        if (this.disabled) return;

        const droppedFiles = event.dataTransfer?.files;
        if (droppedFiles) {
          this.processFiles(droppedFiles);
        }
      },

      /**
       * Handle files selected via file input
       */
      handleFileSelect(event) {
        const selectedFiles = event.target.files;
        if (selectedFiles) {
          this.processFiles(selectedFiles);
        }
        // Reset input to allow selecting the same file again
        event.target.value = '';
      },

      /**
       * Process and validate files before upload
       */
      async processFiles(fileList) {
        this.error = null;
        const filesToUpload = Array.from(fileList);

        // Validate file count for multiple uploads
        if (this.config.maxFiles && this.config.multiple) {
          const totalFiles = this.files.length + filesToUpload.length;
          if (totalFiles > this.config.maxFiles) {
            this.error = `Maximum ${this.config.maxFiles} files allowed`;
            return;
          }
        }

        // If single file mode, clear existing files
        if (!this.config.multiple) {
          this.files = [];
        }

        // Validate and upload each file
        for (const file of filesToUpload) {
          const validationError = this.validateFile(file);
          if (validationError) {
            this.error = validationError;
            continue;
          }

          await this.uploadFile(file);
        }
      },

      /**
       * Validate a single file
       */
      validateFile(file) {
        // Check file size (config is in KB)
        if (this.config.maxSize) {
          const maxBytes = this.config.maxSize * 1024;
          if (file.size > maxBytes) {
            return `File "${file.name}" exceeds maximum size of ${this.formatFileSize(maxBytes)}`;
          }
        }

        if (this.config.minSize) {
          const minBytes = this.config.minSize * 1024;
          if (file.size < minBytes) {
            return `File "${file.name}" is smaller than minimum size of ${this.formatFileSize(minBytes)}`;
          }
        }

        // Check file type
        if (this.config.acceptedTypes && this.config.acceptedTypes.length > 0) {
          const isAccepted = this.config.acceptedTypes.some((type) => {
            if (type.endsWith('/*')) {
              // Wildcard type like 'image/*'
              const prefix = type.slice(0, -2);
              return file.type.startsWith(prefix);
            }
            return file.type === type;
          });

          if (!isAccepted) {
            return `File type "${file.type}" is not accepted`;
          }
        }

        return null;
      },

      /**
       * Upload a file via HTMX/fetch
       */
      async uploadFile(file) {
        this.uploading = true;
        this.progress = 0;

        try {
          const formData = new FormData();
          formData.append('file', file);
          formData.append('fieldName', this.fieldName);

          if (this.config.disk) {
            formData.append('disk', this.config.disk);
          }
          if (this.config.directory) {
            formData.append('directory', this.config.directory);
          }

          // Get the upload URL from the current page's base path
          const basePath = window.location.pathname.split('/resources')[0];
          const uploadUrl = `${basePath}/upload`;

          const response = await this.uploadWithProgress(uploadUrl, formData);

          if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.error || `Upload failed with status ${response.status}`);
          }

          const result = await response.json();

          // Create file entry
          const fileEntry = {
            id: result.id || this.generateId(),
            name: result.name || file.name,
            path: result.path,
            url: result.url,
            size: file.size,
            type: file.type,
            isImage: file.type.startsWith('image/'),
            previewUrl: null,
          };

          // Generate preview for images
          if (fileEntry.isImage) {
            fileEntry.previewUrl = await this.generatePreview(file);
          }

          // Add to files array
          if (this.config.appendFiles !== false) {
            this.files.push(fileEntry);
          } else {
            this.files.unshift(fileEntry);
          }
        } catch (error) {
          console.error('Upload error:', error);
          this.error = error.message || 'Upload failed';
        } finally {
          this.uploading = false;
          this.progress = 0;
        }
      },

      /**
       * Upload with progress tracking
       */
      uploadWithProgress(url, formData) {
        return new Promise((resolve, reject) => {
          const xhr = new XMLHttpRequest();

          xhr.upload.addEventListener('progress', (event) => {
            if (event.lengthComputable) {
              this.progress = Math.round((event.loaded / event.total) * 100);
            }
          });

          xhr.addEventListener('load', () => {
            resolve({
              ok: xhr.status >= 200 && xhr.status < 300,
              status: xhr.status,
              json: () => Promise.resolve(JSON.parse(xhr.responseText)),
            });
          });

          xhr.addEventListener('error', () => {
            reject(new Error('Network error'));
          });

          xhr.open('POST', url);

          // Include HTMX headers for compatibility
          xhr.setRequestHeader('HX-Request', 'true');

          xhr.send(formData);
        });
      },

      /**
       * Generate a preview URL for an image file
       */
      generatePreview(file) {
        return new Promise((resolve) => {
          const reader = new FileReader();
          reader.onload = (e) => resolve(e.target.result);
          reader.onerror = () => resolve(null);
          reader.readAsDataURL(file);
        });
      },

      /**
       * Remove a file from the list
       */
      removeFile(fileId) {
        const index = this.files.findIndex((f) => f.id === fileId);
        if (index > -1) {
          this.files.splice(index, 1);
        }
      },

      /**
       * Format file size for display
       */
      formatFileSize(bytes) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
      },

      /**
       * Generate a unique ID
       */
      generateId() {
        return 'file_' + Math.random().toString(36).substr(2, 9);
      },
    }));
  });

  // Also expose formatFileSize globally for use in templates
  window.formatFileSize = function (bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  };
}
