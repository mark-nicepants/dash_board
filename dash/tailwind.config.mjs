import forms from '@tailwindcss/forms';

/** @type {import('tailwindcss').Config} */
export default {
  content: {
    files: [
      {
        base: './lib',
        pattern: '**/*.dart',
        negated: [],
      },
      {
        base: '../dash_example/lib',
        pattern: '**/*.dart',
        negated: [],
      },
    ],
  },
  plugins: [
    forms({
      strategy: 'class', // only apply form styles when using form-* classes
    }),
  ],
}
