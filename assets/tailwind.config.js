// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

let plugin = require('tailwindcss/plugin')

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex'
  ],
  theme: {
    screens: {
        'xl': {'max': '2000px'},
        // => @media (max-width: 1279px) { ... }
        'lg': {'max': '1199px'},
        // => @media (max-width: 1023px) { ... }
        'md': {'max': '767px'},
        // => @media (max-width: 767px) { ... }
        'sm': {'max': '639px'},
        // => @media (max-width: 639px) { ... }

        // sm: '640px',
        // md: '768px',
        // lg: '1024px',
        // xl: '1280px',
      },
    fontFamily: {
        display: ['Avenir', 'sans-serif'],
        body: ['Avenir', 'sans-serif'],
    },
    extend: {
        colors: {
            darkgreen: '#114b5f',
            green: '#1a936f',
            lightgreen: '#88d498',
            plain: '#dbd8c0',
            plainlight: '#f3e9d2',
        },
        margin: {
            '96': '20rem',
            '128': '28rem',
        },
        inset: {
            '-9999': '-9999px',
        },
        
    }
  },
  variants: {
    opacity: ['responsive', 'hover']
  },
  plugins: [
    require('@tailwindcss/forms'),
    plugin(({addVariant}) => addVariant('phx-no-feedback', ['&.phx-no-feedback', '.phx-no-feedback &'])),
    plugin(({addVariant}) => addVariant('phx-click-loading', ['&.phx-click-loading', '.phx-click-loading &'])),
    plugin(({addVariant}) => addVariant('phx-submit-loading', ['&.phx-submit-loading', '.phx-submit-loading &'])),
    plugin(({addVariant}) => addVariant('phx-change-loading', ['&.phx-change-loading', '.phx-change-loading &']))
  ]
}

