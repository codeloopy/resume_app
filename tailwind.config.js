/** @type {import('tailwindcss').Config} */
const forms = require('@tailwindcss/forms');

module.exports = {
  content: [
    './app/views/**/*.{erb,haml,html,slim}',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  safelist: [
    // Dynamic gradient classes for article colors
    'from-blue-200', 'to-blue-300', 'text-blue-600', 'from-blue-300', 'to-blue-500',
    'from-green-200', 'to-green-300', 'text-green-600', 'from-green-300', 'to-green-500',
    'from-purple-200', 'to-purple-300', 'text-purple-600', 'from-purple-300', 'to-purple-500',
    'from-red-200', 'to-red-300', 'text-red-600', 'from-red-300', 'to-red-500',
    'from-yellow-200', 'to-yellow-300', 'text-yellow-600', 'from-yellow-300', 'to-yellow-500',
    'from-indigo-200', 'to-indigo-300', 'text-indigo-600', 'from-indigo-300', 'to-indigo-500',
    // Category component colors
    'bg-blue-100', 'text-blue-800',
    'bg-green-100', 'text-green-800',
    'bg-purple-100', 'text-purple-800',
    'bg-red-100', 'text-red-800',
    'bg-yellow-100', 'text-yellow-800',
    'bg-indigo-100', 'text-indigo-800',
    'hover:bg-blue-600', 'hover:text-white',
    'hover:bg-green-600', 'hover:text-white',
    'hover:bg-purple-600', 'hover:text-white',
    'hover:bg-red-600', 'hover:text-white',
    'hover:bg-yellow-600', 'hover:text-white',
    'hover:bg-indigo-600', 'hover:text-white',
    'hover:bg-gray-600', 'hover:text-white',
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
        gray: {
          100: '#f3f4f6',
          200: '#f3f4f6',
          300: '#d1d5db',
          500: '#6b7280',
          600: '#4b5563',
          800: '#1f2937',
        },
        hover: {
      }
    },
  },
  plugins: [
    forms,
  ],
}
