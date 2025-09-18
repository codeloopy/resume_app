/** @type {import('tailwindcss').Config} */
const forms = require('@tailwindcss/forms');

module.exports = {
  content: [
    './app/views/**/*.{erb,haml,html,slim}',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        // Ensure all the colors used in your articles are available
        blue: {
          100: '#dbeafe',
          200: '#dbeafe',
          300: '#93c5fd',
          500: '#3b82f6',
          600: '#2563eb',
          800: '#1e40af',
        },
        green: {
          100: '#dcfce7',
          200: '#dcfce7',
          300: '#86efac',
          500: '#22c55e',
          600: '#16a34a',
          800: '#166534',
        },
        purple: {
          100: '#e9d5ff',
          200: '#e9d5ff',
          300: '#c4b5fd',
          500: '#a855f7',
          600: '#9333ea',
          800: '#6b21a8',
        },
        red: {
          100: '#fecaca',
          200: '#fecaca',
          300: '#fca5a5',
          500: '#ef4444',
          600: '#dc2626',
          800: '#991b1b',
        },
        yellow: {
          100: '#fef08a',
          200: '#fef08a',
          300: '#fde047',
          500: '#eab308',
          600: '#ca8a04',
          800: '#854d0e',
        },
        indigo: {
          100: '#e0e7ff',
          200: '#e0e7ff',
          300: '#a5b4fc',
          500: '#6366f1',
          600: '#4f46e5',
          800: '#3730a3',
        },
      }
    },
  },
  plugins: [
    forms,
  ],
}
