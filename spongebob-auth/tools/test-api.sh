#!/usr/bin/env bash
# 后端接口验收脚本（Agent 自动化验证用，不属于交付物）
API="http://localhost:8081/api"
export no_proxy="localhost,127.0.0.1"
export NO_PROXY="localhost,127.0.0.1"
C="curl -s -m 5"

pass=0; fail=0
chk() { # chk "名称" "实际" "期望包含"
  if echo "$2" | grep -q "$3"; then echo "  [OK]   $1"; pass=$((pass+1));
  else echo "  [FAIL] $1"; echo "         实际: $2"; echo "         期望含: $3"; fail=$((fail+1)); fi
}

echo "=== 1. 连通性 ==="
chk "GET /auth/hello" "$($C $API/auth/hello)" '"code":200'

echo "=== 2. 用户名占用检查 ==="
chk "check spongebob -> true"  "$($C "$API/auth/check?username=spongebob")" '"data":true'
chk "check nobody123 -> false" "$($C "$API/auth/check?username=nobody123")" '"data":false'

echo "=== 3. 登录 ==="
LOGIN=$($C -X POST "$API/auth/login" -H 'Content-Type: application/json' -d '{"username":"spongebob","password":"123456"}')
chk "登录成功" "$LOGIN" '"code":200'
TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*"' | head -1 | sed 's/"token":"//;s/"//')
echo "         token = ${TOKEN:0:12}..."
chk "返回 tokenExpire" "$LOGIN" 'tokenExpire'
if echo "$LOGIN" | grep -q '"password"'; then echo "  [FAIL] 返回体里带了 password"; fail=$((fail+1)); else echo "  [OK]   未泄漏 password"; pass=$((pass+1)); fi

chk "密码错误被拒" "$($C -X POST "$API/auth/login" -H 'Content-Type: application/json' -d '{"username":"spongebob","password":"wrong"}')" '用户名或密码错误'
chk "不存在的用户被拒" "$($C -X POST "$API/auth/login" -H 'Content-Type: application/json' -d '{"username":"nobody123","password":"123456"}')" '用户名或密码错误'

echo "=== 4. 令牌校验（profile）==="
chk "无令牌 -> 401"      "$($C $API/auth/profile)" '"code":401'
chk "假令牌 -> 401"      "$($C $API/auth/profile -H 'Authorization: not-a-real-token')" '"code":401'
chk "真令牌 -> 200"      "$($C $API/auth/profile -H "Authorization: $TOKEN")" '"code":200'
chk "Bearer 前缀兼容"    "$($C $API/auth/profile -H "Authorization: Bearer $TOKEN")" '"code":200'

echo "=== 5. 用户列表分页 ==="
chk "无令牌 -> 401"      "$($C "$API/user/page?page=1&size=5")" '"code":401'
PAGE=$($C "$API/user/page?page=1&size=2" -H "Authorization: $TOKEN")
chk "带令牌 -> 200"      "$PAGE" '"code":200'
chk "IPage 形状 records" "$PAGE" '"records"'
chk "IPage 形状 total"   "$PAGE" '"total"'
chk "IPage 形状 pages"   "$PAGE" '"pages"'
chk "每页 2 条(size=2)"  "$PAGE" '"size":2'
chk "关键字搜索 patrick" "$($C "$API/user/page?page=1&size=5&keyword=patrick" -H "Authorization: $TOKEN")" 'patrick'
if echo "$PAGE" | grep -q '"token":"'; then echo "  [FAIL] 列表里带了 token"; fail=$((fail+1)); else echo "  [OK]   列表未泄漏 token"; pass=$((pass+1)); fi
if echo "$PAGE" | grep -q '"password"'; then echo "  [FAIL] 列表里带了 password"; fail=$((fail+1)); else echo "  [OK]   列表未泄漏 password"; pass=$((pass+1)); fi

echo "=== 6. 注册 ==="
NEWUSER="bubble$(date +%H%M%S)"
chk "新用户注册成功" "$($C -X POST "$API/auth/register" -H 'Content-Type: application/json' -d "{\"username\":\"$NEWUSER\",\"password\":\"123456\",\"nickname\":\"泡泡\"}")" '"code":200'
chk "新用户可直接登录" "$($C -X POST "$API/auth/login" -H 'Content-Type: application/json' -d "{\"username\":\"$NEWUSER\",\"password\":\"123456\"}")" '"code":200'
chk "重复注册被拒"   "$($C -X POST "$API/auth/register" -H 'Content-Type: application/json' -d "{\"username\":\"$NEWUSER\",\"password\":\"123456\"}")" '已被占用'
chk "用户名太短被拒" "$($C -X POST "$API/auth/register" -H 'Content-Type: application/json' -d '{"username":"ab","password":"123456"}')" '4-20'
chk "密码太短被拒"   "$($C -X POST "$API/auth/register" -H 'Content-Type: application/json' -d '{"username":"longenough","password":"123"}')" '至少 6 位'

echo "=== 7. 退出登录 ==="
chk "退出成功"       "$($C -X POST "$API/auth/logout" -H "Authorization: $TOKEN")" '"code":200'
chk "退出后令牌失效" "$($C $API/auth/profile -H "Authorization: $TOKEN")" '"code":401'

echo
echo "结果：通过 $pass 项，失败 $fail 项"
exit $fail
