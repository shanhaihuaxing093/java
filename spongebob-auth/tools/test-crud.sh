#!/usr/bin/env bash
# 后端增删改验收脚本（Agent 自动化验证用，不属于交付物）
# 跑之前后端必须活着；脚本会自己造测试用户并在结束时物理清理
API="http://localhost:8081/api"
export no_proxy="localhost,127.0.0.1"
export NO_PROXY="localhost,127.0.0.1"
C="curl -s -m 5"

pass=0; fail=0
chk() {
  if echo "$2" | grep -q "$3"; then echo "  [OK]   $1"; pass=$((pass+1));
  else echo "  [FAIL] $1"; echo "         实际: $2"; echo "         期望含: $3"; fail=$((fail+1)); fi
}

login() { $C -X POST "$API/auth/login" -H 'Content-Type: application/json' \
  -d "{\"username\":\"$1\",\"password\":\"$2\"}" | grep -o '"token":"[^"]*"' | head -1 | sed 's/"token":"//;s/"//'; }

TK=$(login spongebob 123456)
[ -z "$TK" ] && { echo "登录失败，后端没起？"; exit 1; }

echo "=== 1. 未登录保护 ==="
chk "未登录列表 -> 401" "$($C "$API/user/page?page=1&size=5")" '"code":401'
chk "未登录改昵称 -> 401" "$($C -X PUT "$API/user/2/nickname" -H 'Content-Type: application/json' -d '{"nickname":"x"}')" '"code":401'
chk "未登录删除 -> 401" "$($C -X DELETE "$API/user/2")" '"code":401'

echo "=== 2. 改昵称 ==="
chk "改自己昵称 -> 200" "$($C -X PUT "$API/user/1/nickname" -H "Authorization: $TK" -H 'Content-Type: application/json' -d '{"nickname":"海绵宝宝"}')" '"code":200'
chk "越权改别人 -> 403" "$($C -X PUT "$API/user/2/nickname" -H "Authorization: $TK" -H 'Content-Type: application/json' -d '{"nickname":"hack"}')" '"code":403'
chk "空昵称被拒 -> 400" "$($C -X PUT "$API/user/1/nickname" -H "Authorization: $TK" -H 'Content-Type: application/json' -d '{"nickname":"  "}')" '"code":400'

echo "=== 3. 启用 / 禁用 ==="
chk "禁自己 -> 403" "$($C -X PUT "$API/user/1/status?status=0" -H "Authorization: $TK")" '"code":403'
chk "禁用 patrick -> 200" "$($C -X PUT "$API/user/2/status?status=0" -H "Authorization: $TK")" '"code":200'
chk "禁用后不能登录" "$($C -X POST "$API/auth/login" -H 'Content-Type: application/json' -d '{"username":"patrick","password":"123456"}')" '已被禁用'
chk "恢复 patrick -> 200" "$($C -X PUT "$API/user/2/status?status=1" -H "Authorization: $TK")" '"code":200'
chk "恢复后可登录" "$($C -X POST "$API/auth/login" -H 'Content-Type: application/json' -d '{"username":"patrick","password":"123456"}')" '"code":200'
chk "非法状态值被拒" "$($C -X PUT "$API/user/2/status?status=9" -H "Authorization: $TK")" '"code":400'

echo "=== 4. 改密码 ==="
NEWUSER="crud$(date +%H%M%S)"
$C -X POST "$API/auth/register" -H 'Content-Type: application/json' \
  -d "{\"username\":\"$NEWUSER\",\"password\":\"123456\",\"nickname\":\"临时\"}" > /dev/null
NTK=$(login "$NEWUSER" 123456)
chk "新用户登录成功" "$NTK" '.'
UID2=$($C "$API/user/page?page=1&size=10&keyword=$NEWUSER" -H "Authorization: $NTK" | grep -o '"id":[0-9]*' | head -1 | sed 's/"id"://')
chk "原密码错误被拒" "$($C -X PUT "$API/user/$UID2/password" -H "Authorization: $NTK" -H 'Content-Type: application/json' -d '{"oldPassword":"bad","newPassword":"654321"}')" '原密码不正确'
chk "改密码成功" "$($C -X PUT "$API/user/$UID2/password" -H "Authorization: $NTK" -H 'Content-Type: application/json' -d '{"oldPassword":"123456","newPassword":"654321"}')" '"code":200'
chk "改密后旧令牌失效" "$($C "$API/auth/profile" -H "Authorization: $NTK")" '"code":401'
chk "新密码可登录" "$(login "$NEWUSER" 654321)" '.'

echo "=== 5. 删除 ==="
TK=$(login spongebob 123456)
chk "删自己 -> 403" "$($C -X DELETE "$API/user/1" -H "Authorization: $TK")" '"code":403'
chk "删测试用户 -> 200" "$($C -X DELETE "$API/user/$UID2" -H "Authorization: $TK")" '"code":200'
chk "删后列表搜不到" "$($C "$API/user/page?page=1&size=10&keyword=$NEWUSER" -H "Authorization: $TK")" '"total":0'
chk "删后不能登录" "$($C -X POST "$API/auth/login" -H 'Content-Type: application/json' -d "{\"username\":\"$NEWUSER\",\"password\":\"654321\"}")" '用户名或密码错误'

echo "=== 6. 数据清理 ==="
"/c/Program Files/MySQL/MySQL Server 8.0/bin/mysql.exe" -uroot -p123456 \
  -e "delete from spongebob_auth.sys_user where username like 'crud%' or username like 'bubble%';" 2>/dev/null
LEFT=$("/c/Program Files/MySQL/MySQL Server 8.0/bin/mysql.exe" -uroot -p123456 -N -B \
  -e "select count(*) from spongebob_auth.sys_user;" 2>/dev/null)
chk "sys_user 只剩 3 个内置账号" "$LEFT" '^3$'

echo
echo "结果：通过 $pass 项，失败 $fail 项"
exit $fail
