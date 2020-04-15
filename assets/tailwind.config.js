module.exports = {
    important: true,
    theme: {
        screens: {
            'xl': {'max': '1279px'},
            // => @media (max-width: 1279px) { ... }
            'lg': {'max': '1023px'},
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
                '96': '24rem',
                '128': '32rem',
            },
            inset: {
                '-9999': '-9999px',
            },
            
        }
    },
    variants: {
        opacity: ['responsive', 'hover']
    },
    
}