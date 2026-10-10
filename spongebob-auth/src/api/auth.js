import request from './request'

/**
 * 后端接口一览（SpringBoot: com.fenglin.springboottest.controller.AuthController）
 * 公开接口：
 *   GET  /api/auth/hello             连通性测试
 *   GET  /api/auth/check?username=xx 用户名是否已存在
 *   POST /api/auth/login             登录（返回体含 token）
 *   POST /api/auth/register          注册
 * 需登录接口（request.js 会自动带 Authorization 头）：
 *   GET  /api/auth/profile           当前登录用户信息
 *   POST /api/auth/logout            退出登录
 */
export const login = (data) => request.post('/auth/login', data)
export const register = (data) => request.post('/auth/register', data)
export const checkUsername = (username) => request.get('/auth/check', { params: { username } })
export const hello = () => request.get('/auth/hello')
export const profile = () => request.get('/auth/profile')
export const logout = () => request.post('/auth/logout')
