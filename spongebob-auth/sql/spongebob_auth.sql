-- ============================================================
--  比奇堡登录注册项目 · 数据库脚本
--  数据库名：spongebob_auth   字符集：utf8mb4
--  执行方式（任选一种）：
--    1) MySQL 命令行：mysql -uroot -p123456 < sql/spongebob_auth.sql
--    2) IDEA / Navicat 打开本文件全选执行
--  本脚本可重复执行（建库建表均带 IF NOT EXISTS）
-- ============================================================

CREATE DATABASE IF NOT EXISTS spongebob_auth
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

USE spongebob_auth;

-- ---------------- 用户表 ----------------
-- 本脚本可重复执行；如需彻底重置数据，请手动取消下一行注释
-- DROP TABLE IF EXISTS sys_user;
CREATE TABLE IF NOT EXISTS sys_user (
  id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  username    VARCHAR(50)  NOT NULL                COMMENT '用户名（唯一）',
  password    VARCHAR(100) NOT NULL                COMMENT '密码（MD5 加盐存储）',
  nickname    VARCHAR(50)  DEFAULT NULL            COMMENT '昵称',
  avatar      VARCHAR(200) DEFAULT '🧽'            COMMENT '头像',
  status      TINYINT      NOT NULL DEFAULT 1      COMMENT '状态 1-正常 0-禁用',
  token       VARCHAR(64)  DEFAULT NULL            COMMENT '登录令牌(UUID，登录时签发，退出时清空)',
  token_expire DATETIME    DEFAULT NULL            COMMENT '令牌过期时间(登录后 2 小时)',
  deleted     TINYINT      NOT NULL DEFAULT 0      COMMENT '逻辑删除 0-未删 1-已删',
  create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (id),
  UNIQUE KEY uk_username (username),
  KEY idx_status (status)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COMMENT = '用户表';

-- 兼容旧库：如果表已经建过且没有下面字段，执行这两行补上（新版 MySQL 无 ADD COLUMN IF NOT EXISTS）
-- ALTER TABLE sys_user ADD COLUMN token VARCHAR(64) DEFAULT NULL COMMENT '登录令牌(UUID)' AFTER status;
-- ALTER TABLE sys_user ADD COLUMN token_expire DATETIME DEFAULT NULL COMMENT '令牌过期时间' AFTER token;

-- ---------------- 初始化数据 ----------------
-- 三个内置账号，密码统一为：123456
-- MD5 密文由 com.fenglin.springboottest.util.Md5Util 生成（md5(md5(原文)+盐)）
-- 若你想改密码，请用注册接口重新注册，或在后端重新计算密文
INSERT IGNORE INTO sys_user (username, password, nickname, avatar, status) VALUES
  ('spongebob', '54a66656018f3b1f43e2eef4bd608053', '海绵宝宝', '🧽', 1),
  ('patrick',   '54a66656018f3b1f43e2eef4bd608053', '派大星',   '⭐', 1),
  ('squidward', '54a66656018f3b1f43e2eef4bd608053', '章鱼哥',   '🦑', 1);

-- ---------------- 校验 ----------------
SELECT id, username, nickname, avatar, status, create_time FROM sys_user;
