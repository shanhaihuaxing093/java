import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'

// 后端地址 / 端口 / 超时全部抽到 .env.development（模板见 .env.example）
// 以前这里是硬编码 8081，改端口要动源码；现在只改环境变量文件即可。
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')

  const BACKEND = env.VITE_BACKEND_URL || 'http://localhost:8081'
  const API_BASE = env.VITE_API_BASE || '/api'
  const PORT = Number(env.VITE_PORT || 5173)

  return {
    plugins: [vue()],
    server: {
      port: PORT,
      host: '0.0.0.0',
      open: false,
      proxy: {
        // 键来自环境变量：/api → http://localhost:8081
        [API_BASE]: {
          target: BACKEND,
          changeOrigin: true
        }
      }
    },
    build: {
      outDir: 'dist',
      chunkSizeWarningLimit: 1500
    }
  }
})
