import request from './request'

/**
 * 用户查询接口（SpringBoot: SysUserController）
 * GET /api/user/page?page=1&size=10&keyword=xxx   需登录
 * 返回体 data 是 MyBatis-Plus 的 IPage：{ records, total, size, current, pages }
 */
export const userPage = (params) => request.get('/user/page', { params })
