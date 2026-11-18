<template>
  <OceanBg>
    <main class="sponge-card wide">
      <h1 class="title">🖼️ 比奇堡文件中心</h1>
      <p class="subtitle">上传图片与附件 · 文件保存在后端 uploads 目录，按日期归档</p>

      <!-- ===== 拖拽上传区 ===== -->
      <div
        class="drop-zone"
        :class="{ dragging }"
        @dragover.prevent="dragging = true"
        @dragleave.prevent="dragging = false"
        @drop.prevent="onDrop"
        @click="triggerPick"
      >
        <div class="drop-icon">{{ dragging ? '📥' : '📤' }}</div>
        <div class="drop-title">{{ dragging ? '松手即可上传' : '点击选择文件，或把文件拖进来' }}</div>
        <div class="drop-desc">支持图片（jpg/png/gif/webp…）与附件（pdf/doc/zip/mp4…），单个不超过 20MB，可多选</div>
        <input ref="fileInput" type="file" multiple hidden @change="onPick" />
      </div>

      <!-- ===== 上传进度列表 ===== -->
      <div v-if="uploads.length" class="uploads">
        <div v-for="u in uploads" :key="u.id" class="upload-row">
          <span class="u-name" :title="u.name">{{ u.name }}</span>
          <div class="bar"><i :style="{ width: u.progress + '%' }"></i></div>
          <span class="u-status" :class="u.state">{{ u.status }}</span>
        </div>
      </div>

      <!-- ===== 筛选工具栏 ===== -->
      <div class="toolbar">
        <div class="tabs">
          <button
            v-for="t in tabs"
            :key="t.value"
            class="tab"
            :class="{ active: curType === t.value }"
            type="button"
            @click="switchType(t.value)"
          >{{ t.label }}</button>
        </div>
        <div class="search">
          <div class="input-wrap">
            <span class="icon">🔍</span>
            <input v-model.trim="keyword" type="text" placeholder="按文件名搜索" @keyup.enter="load(1)" />
          </div>
          <button class="btn small" :disabled="loading" @click="load(1)">搜索</button>
        </div>
      </div>

      <!-- ===== 文件网格 ===== -->
      <div v-if="records.length" class="grid">
        <div v-for="f in records" :key="f.id" class="file-card">
          <div class="thumb" @click="f.fileType === 'image' && openPreview(f)">
            <img v-if="f.fileType === 'image'" :src="previewUrl(f.id)" :alt="f.originalName" loading="lazy" />
            <span v-else class="file-icon">{{ fileIcon(f.extension) }}</span>
            <span class="type-badge" :class="f.fileType">{{ f.fileType === 'image' ? '图片' : '附件' }}</span>
          </div>
          <div class="fname" :title="f.originalName">{{ f.originalName }}</div>
          <div class="fmeta">{{ f.sizeText }} · {{ f.uploaderName || '未知' }} · {{ formatTime(f.uploadTime) }}</div>
          <div class="facts">
            <a class="op" :href="downloadUrl(f.id)" download>⬇ 下载</a>
            <button class="op danger" type="button" @click="askRemove(f)">🗑 删除</button>
          </div>
        </div>
      </div>
      <div v-else class="empty">🫧 还没有文件，先上传一个试试吧</div>

      <!-- ===== 分页 ===== -->
      <div class="pager">
        <button class="btn tiny" :disabled="current <= 1 || loading" @click="load(current - 1)">上一页</button>
        <span class="pinfo">第 {{ current }} / {{ pages || 1 }} 页 · 共 {{ total }} 个文件</span>
        <button class="btn tiny" :disabled="current >= pages || loading" @click="load(current + 1)">下一页</button>
      </div>

      <router-link class="back" to="/home">← 回蟹堡王后台</router-link>
    </main>

    <!-- ===== 大图预览 ===== -->
    <div v-if="preview" class="mask" @click.self="preview = null">
      <div class="preview-box">
        <img :src="previewUrl(preview.id)" :alt="preview.originalName" />
        <div class="preview-foot">
          <span>{{ preview.originalName }}</span>
          <button class="btn tiny ghost" type="button" @click="preview = null">关闭 ×</button>
        </div>
      </div>
    </div>

    <!-- ===== 删除确认 ===== -->
    <div v-if="delTarget" class="mask" @click.self="delTarget = null">
      <div class="dialog">
        <h3>🗑️ 删除文件</h3>
        <p class="dialog-sub">确定要删除 <b>{{ delTarget.originalName }}</b> 吗？<br />物理文件也会一并删除，此操作不可恢复。</p>
        <div class="dialog-btns">
          <button class="btn tiny ghost" type="button" @click="delTarget = null">取消</button>
          <button class="btn tiny danger" type="button" :disabled="deleting" @click="confirmRemove">
            {{ deleting ? '删除中…' : '确定删除' }}
          </button>
        </div>
      </div>
    </div>
  </OceanBg>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import OceanBg from '../components/OceanBg.vue'
import { toast } from '../utils/toast'
import { uploadFile, filePage, removeFile, previewUrl, downloadUrl } from '../api/file'

const tabs = [
  { label: '全部', value: '' },
  { label: '🖼️ 图片', value: 'image' },
  { label: '📎 附件', value: 'attachment' }
]

const records = ref([])
const loading = ref(false)
const deleting = ref(false)
const keyword = ref('')
const curType = ref('')
const current = ref(1)
const pages = ref(0)
const total = ref(0)
const size = 12

const dragging = ref(false)
const fileInput = ref(null)
const uploads = ref([])
const preview = ref(null)
const delTarget = ref(null)
let uploadSeq = 0

async function load(p = 1) {
  current.value = p
  loading.value = true
  try {
    const res = await filePage({
      page: p,
      size,
      type: curType.value || undefined,
      keyword: keyword.value || undefined
    })
    if (res.code === 200) {
      records.value = res.data?.records || []
      pages.value = res.data?.pages || 0
      total.value = res.data?.total || 0
    } else {
      toast('❌ ' + (res.msg || '加载文件列表失败'), 'err')
    }
  } catch (e) {
    toast('❌ ' + e.message, 'err')
  } finally {
    loading.value = false
  }
}

function switchType(t) {
  curType.value = t
  load(1)
}

function triggerPick() {
  fileInput.value?.click()
}

function onPick(e) {
  const files = Array.from(e.target.files || [])
  e.target.value = '' // 允许重复选同一个文件
  doUpload(files)
}

function onDrop(e) {
  dragging.value = false
  const files = Array.from(e.dataTransfer?.files || [])
  doUpload(files)
}

async function doUpload(files) {
  if (!files.length) return
  for (const f of files) {
    const item = { id: ++uploadSeq, name: f.name, progress: 0, status: '上传中…', state: '' }
    uploads.value.push(item)
    try {
      const res = await uploadFile(f, (p) => { item.progress = p })
      if (res.code === 200) {
        item.progress = 100
        item.status = '✅ 上传成功'
        item.state = 'ok'
      } else {
        item.status = '❌ ' + (res.msg || '上传失败')
        item.state = 'err'
        toast('❌ ' + (res.msg || '上传失败'), 'err')
      }
    } catch (err) {
      item.status = '❌ ' + err.message
      item.state = 'err'
      toast('❌ ' + err.message, 'err')
    }
  }
  // 2.5 秒后清掉成功项，失败项保留提示
  setTimeout(() => {
    uploads.value = uploads.value.filter((u) => u.state !== 'ok')
  }, 2500)
  load(1)
}

function askRemove(f) {
  delTarget.value = f
}

async function confirmRemove() {
  const f = delTarget.value
  if (!f) return
  delTarget.value = null
  deleting.value = true
  try {
    const res = await removeFile(f.id)
    if (res.code === 200) {
      toast('🗑️ 文件已删除', 'ok')
      load(current.value)
    } else {
      toast('❌ ' + (res.msg || '删除失败'), 'err')
    }
  } catch (e) {
    toast('❌ ' + e.message, 'err')
  } finally {
    deleting.value = false
  }
}

function fileIcon(ext) {
  const map = {
    pdf: '📕', doc: '📘', docx: '📘', xls: '📗', xlsx: '📗',
    ppt: '📙', pptx: '📙', zip: '🗜️', rar: '🗜️', '7z': '🗜️',
    mp3: '🎵', mp4: '🎬', avi: '🎬', mov: '🎬', txt: '📄', md: '📄',
    csv: '📊', json: '📄', xml: '📄'
  }
  return map[ext] || '📎'
}

function formatTime(t) {
  return t ? String(t).slice(0, 10) : ''
}

function openPreview(f) {
  preview.value = f
}

onMounted(() => load(1))
</script>

<style scoped>
.wide { max-width: 900px; }

/* ---------- 拖拽上传区 ---------- */
.drop-zone {
  margin-top: 16px;
  padding: 22px 18px;
  text-align: center;
  cursor: pointer;
  background: rgba(255, 255, 255, .65);
  border: 4px dashed var(--sponge-border);
  border-radius: 20px;
  transition: .15s;
}
.drop-zone:hover, .drop-zone.dragging {
  background: rgba(255, 236, 130, .75);
  border-color: var(--ocean-1);
  transform: translateY(-3px);
}
.drop-icon { font-size: 40px; line-height: 1; }
.drop-title { margin-top: 8px; font-size: 16px; font-weight: 800; color: #7a5400; }
.drop-desc { margin-top: 5px; font-size: 12px; color: #8a6500; }

/* ---------- 上传进度 ---------- */
.uploads { margin-top: 12px; display: flex; flex-direction: column; gap: 6px; }
.upload-row { display: flex; align-items: center; gap: 10px; font-size: 12px; }
.u-name { width: 140px; color: #5a4500; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.u-status { width: 90px; font-weight: 700; color: #7a5400; }
.u-status.ok { color: var(--green-dark); }
.u-status.err { color: var(--red); }
.bar { flex: 1; height: 9px; background: #fff; border: 2px solid var(--sponge-border); border-radius: 6px; overflow: hidden; }
.bar i { display: block; height: 100%; background: var(--ocean-1); transition: width .15s; }

/* ---------- 工具栏 ---------- */
.toolbar { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-top: 18px; flex-wrap: wrap; }
.tabs { display: flex; gap: 8px; }
.tab {
  padding: 7px 14px; font-size: 13px; font-weight: 800; font-family: inherit;
  color: #7a5400; cursor: pointer;
  background: #fff; border: 3px solid var(--sponge-border); border-radius: 11px;
  transition: .12s;
}
.tab:hover { background: #fff3b0; }
.tab.active { color: #fff; background: var(--ocean-1); border-color: var(--ocean-2); }
.search { display: flex; gap: 10px; align-items: center; }
.search .input-wrap { width: 220px; }
.search input { padding-left: 42px; }
.btn.small { margin-top: 0; width: auto; padding: 10px 16px; font-size: 14px; }
.btn.tiny { margin-top: 0; width: auto; padding: 8px 14px; font-size: 14px; }

/* ---------- 文件网格 ---------- */
.grid {
  margin-top: 14px;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 12px;
  max-height: 440px;
  overflow: auto;
  padding: 10px;
  background: rgba(255, 255, 255, .55);
  border: 3px dashed var(--sponge-border);
  border-radius: 18px;
}
.file-card {
  padding: 8px;
  background: #fffdf2;
  border: 3px solid var(--sponge-border);
  border-radius: 14px;
  box-shadow: 0 4px 0 var(--sponge-border);
  display: flex; flex-direction: column; gap: 5px;
}
.thumb {
  position: relative;
  height: 92px;
  border-radius: 9px;
  overflow: hidden;
  background: linear-gradient(135deg, #bfe6ff, #7fc4ff);
  display: flex; align-items: center; justify-content: center;
}
.thumb img { width: 100%; height: 100%; object-fit: cover; cursor: zoom-in; }
.file-icon { font-size: 40px; }
.type-badge {
  position: absolute; top: 5px; right: 5px;
  padding: 2px 7px; font-size: 10px; font-weight: 800;
  border-radius: 8px; color: #fff;
}
.type-badge.image { background: #1d9bd1; }
.type-badge.attachment { background: #e08a00; }
.fname { font-size: 12px; font-weight: 800; color: #5a4500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.fmeta { font-size: 11px; color: #8a6500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.facts { display: flex; gap: 6px; margin-top: 2px; }
.op {
  flex: 1; padding: 4px 6px;
  font-size: 11px; font-weight: 700; font-family: inherit; text-align: center; text-decoration: none;
  color: var(--ocean-1); cursor: pointer;
  background: #fff; border: 2px solid var(--ocean-1); border-radius: 8px;
  transition: .12s;
}
.op:hover { background: var(--ocean-3); color: #fff; border-color: var(--ocean-2); }
.op.danger { color: var(--red); border-color: var(--red); }
.op.danger:hover { background: var(--red); color: #fff; }
.empty { margin-top: 16px; padding: 34px; text-align: center; color: #7a5400; font-weight: 700; background: rgba(255,255,255,.55); border: 3px dashed var(--sponge-border); border-radius: 18px; }

.pager { display: flex; align-items: center; justify-content: center; gap: 12px; margin-top: 14px; }
.pinfo { font-size: 13px; font-weight: 700; color: #7a5400; }
.back { display: block; margin-top: 16px; text-align: center; font-size: 13px; font-weight: 700; color: #8a5a00; }

/* ---------- 弹窗 ---------- */
.mask {
  position: fixed; inset: 0; z-index: 200;
  display: flex; align-items: center; justify-content: center;
  padding: 20px;
  background: rgba(4, 55, 107, .55);
}
.preview-box {
  width: 100%; max-width: 640px;
  padding: 12px;
  background: #fffdf5;
  border: 5px solid var(--sponge-border);
  border-radius: 22px;
  box-shadow: 0 10px 0 var(--sponge-border), 0 20px 40px rgba(0, 0, 0, .4);
}
.preview-box img { display: block; max-width: 100%; max-height: 68vh; margin: 0 auto; border-radius: 10px; }
.preview-foot { display: flex; align-items: center; justify-content: space-between; gap: 10px; margin-top: 10px; font-size: 13px; font-weight: 700; color: #7a5400; }
.dialog {
  width: 100%; max-width: 360px;
  padding: 20px 22px;
  background: #fffdf5;
  border: 5px solid var(--sponge-border);
  border-radius: 22px;
  box-shadow: 0 10px 0 var(--sponge-border), 0 20px 40px rgba(0, 0, 0, .4);
}
.dialog h3 { font-size: 18px; margin-bottom: 6px; }
.dialog-sub { font-size: 13px; color: #7a5400; line-height: 1.6; margin-bottom: 14px; }
.dialog-btns { display: flex; gap: 10px; justify-content: flex-end; }
.btn.tiny.ghost { background: #fff; color: var(--ink); border: 3px solid var(--sponge-border); }
.btn.tiny.danger { background: var(--red); color: #fff; border-color: #8e1a08; }

@media (max-width: 640px) {
  .toolbar { flex-direction: column; align-items: stretch; }
  .search .input-wrap { width: 100%; }
  .grid { grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); }
}
</style>
