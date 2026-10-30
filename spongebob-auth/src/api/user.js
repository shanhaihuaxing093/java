import request from './request'

/**
 * 用户接口（SpringBoot: SysUserController）
 *
 * GET    /api/user/page?page=1&size=10&keyword=xxx   需登录
 *        返回体 data 是 MyBatis-Plus 的 IPage：{ records, total, size, current, pages }
 * PUT    /api/user/{id}/nickname   改昵称（只能改自己）
 * PUT    /api/user/{id}/password   改密码（只能改自己，必须带 oldPassword）
 * PUT    /api/user/{id}/status?status=0|1   启用 / 禁用（不能改自己）
 * DELETE /api/user/{id}            删除（不能删自己）
 */

/** 分页查询 */
export const userPage = (params) => request.get('/user/page', { params })

/** 改昵称 */
export const updateNickname = (id, nickname) => request.put(`/user/${id}/nickname`, { nickname })

/** 改密码（需要原密码） */
export const updatePassword = (id, oldPassword, newPassword) =>
  request.put(`/user/${id}/password`, { oldPassword, newPassword })

/** 启用 / 禁用 */
export const updateStatus = (id, status) =>
  request.put(`/user/${id}/status`, null, { params: { status } })

/** 删除用户 */
export const removeUser = (id) => request.delete(`/user/${id}`)
