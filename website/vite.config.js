import { defineConfig } from 'vite'

export default defineConfig({
    base: '/',
    root: './',
    server: {
        fs: {
            allow: ['..']
        }
    },
    build: {
        outDir: 'dist',
    }
})
