import request from './request'

/**
 * 文件接口（SpringBoot: FileController）
 *
 * POST   /api/file/upload              上传（multipart，字段名 file）      需令牌
 * GET    /api/file/page?...            分页列表                            需令牌
 * DELETE /api/file/{id}                删除（DB + 物理文件）               需令牌
 * GET    /api/file/preview/{id}        图片预览（<img> 直连，无需令牌头）
 * GET    /api/file/download/{id}       下载（<a> 直连，无需令牌头）
 */

/** 上传单个文件，onProgress 收到 0-100 的进度 */
export const uploadFile = (file, onProgress) => {
  const form = new FormData()
  form.append('file', file)
  return request.post('/file/upload', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
    onUploadProgress: (e) => {
      if (onProgress && e.total) {
        onProgress(Math.round((e.loaded * 100) / e.total))
      }
    }
  })
}

/** 分页列表：{ page, size, type: 'image'|'attachment', keyword } */
export const filePage = (params) => request.get('/file/page', { params })

/** 删除文件 */
export const removeFile = (id) => request.delete(`/file/${id}`)

/** 图片预览地址（可直接放进 <img src>） */
export const previewUrl = (id) => `/api/file/preview/${id}`

/** 下载地址（可直接放进 <a href>，后端已设置 Content-Disposition） */
export const downloadUrl = (id) => `/api/file/download/${id}`
