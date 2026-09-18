# 🚩 扫雷 · Minesweeper (Vue 3)

一个用 **Vue 3 + Vite** 实现的经典扫雷网页游戏。

## ✨ 特性

- 三种难度：初级 (9×9 / 10雷)、中级 (16×16 / 40雷)、高级 (16×30 / 99雷)
- **自定义难度**：自由设置行 / 列 / 雷数（自动校验范围）
- **首次点击保证安全**（点击格子及其周围 8 格不会是雷）
- 左键翻开、右键插旗、在数字上双击快速展开（和弦 chord）
- 空白区域自动连片展开（flood fill）
- 计时器与剩余雷数显示
- **最佳成绩**：每个难度的最佳用时保存在浏览器 localStorage
- **亮 / 暗主题**：右上角一键切换，偏好同样被记住
- 胜利 / 失败状态提示

## 🚀 运行

```bash
# 安装依赖
npm install

# 启动开发服务器（默认 http://localhost:5173）
npm run dev

# 构建生产版本到 dist/
npm run build

# 预览构建产物
npm run preview
```

## 📁 目录结构

```
minesweeper-vue/
├── index.html
├── package.json
├── vite.config.js
├── README.md
└── src/
    ├── main.js
    ├── App.vue
    ├── style.css
    ├── composables/
    │   └── useMinesweeper.js   # 游戏核心逻辑（棋盘、布雷、翻开、旗子、胜负判定）
    └── components/
        ├── MinesweeperBoard.vue # 整体布局：难度选择、状态栏、棋盘
        └── Cell.vue             # 单个格子
```

## 🎮 操作说明

| 操作 | 效果 |
| --- | --- |
| 左键单击 | 翻开格子 |
| 右键单击 | 插旗 / 取消旗 |
| 数字格双击 | 若周围旗数等于数字，自动展开周围未标记格 |
