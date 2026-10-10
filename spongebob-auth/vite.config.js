import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// 后端固定端口 8081（见 springBootTest/src/main/resources/application-dev.properties）
const BACKEND = 'http://localhost:8081'

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5173,
    host: '0.0.0.0',
    open: false,
    proxy: {
      '/api': {
        target: BACKEND,
        changeOrigin: true
      }
    }
  },
  build: {
    outDir: 'dist',
    chunkSizeWarningLimit: 1500
  }
})
