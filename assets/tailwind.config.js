module.exports = {
    important: true,
    theme: {
        screens: {
            'sm': '640px',
            // => @media (min-width: 640px) { ... }
      
            'md': '768px',
            // => @media (min-width: 768px) { ... }
      
            'lg': '1024px',
            // => @media (min-width: 1024px) { ... }
      
            'xl': '1280px',
            // => @media (min-width: 1280px) { ... }
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
            '96': '24rem',
            '128': '32rem',
        },
        }
    },
    variants: {
        opacity: ['responsive', 'hover']
    }
    }