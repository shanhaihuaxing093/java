#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""静态检查 .bat：跳转标签是否齐全、括号是否配平、引号是否成对。

它不能代替真实执行，但能揪出绝大多数手写 bat 的低级错误
（漏标签、块没闭合、括号数不对）。改完脚本建议跑一次。

用法：
    python tools/check-bat.py                    # 检查本文件所在项目根目录的 .bat
    python tools/check-bat.py <另一个目录>        # 顺便检查那个目录的 .bat
"""
import glob
import os
import re
import sys


def check(path, out):
    name = os.path.basename(path)
    raw = open(path, 'rb').read()
    try:
        text = raw.decode('gbk')
    except UnicodeDecodeError:
        text = raw.decode('utf-8', 'replace')
        out.append('%s: 不是 GBK，可能是 UTF-8（cmd 里中文会乱码），'
                   '跑一下 tools/bat-to-gbk.py' % name)
    if raw.startswith(b'\xef\xbb\xbf'):
        out.append('%s: 带 UTF-8 BOM，cmd 会读坏第一行，必须去掉' % name)

    lines = text.split('\r\n')
    labels = set()
    refs = []
    stack = []
    issues = []

    for i, raw_line in enumerate(lines, 1):
        stripped = raw_line.strip()

        m = re.match(r'^:([A-Za-z0-9_]+)\s*$', stripped)
        if m:
            labels.add(m.group(1).lower())

        for m in re.finditer(r'\b(?:goto|call)\s+:([A-Za-z0-9_]+)', stripped):
            refs.append((i, m.group(1)))

        code = stripped
        if re.match(r'^(rem\b|::)', code, re.I):
            code = ''

        # 去掉双引号内的内容再统计括号，避免 %ProgramFiles(x86)% 这种误报
        code_nq = re.sub(r'"[^"]*"', '""', code)
        opens = code_nq.count('(') - code_nq.count('^(')
        closes = code_nq.count(')') - code_nq.count('^)')

        if code.count('"') % 2 != 0 and not re.search(r'%\w+%$', code):
            if not code.lower().startswith('echo'):
                issues.append('第%d行 引号数量是奇数: %s' % (i, stripped[:70]))

        balance = opens - closes
        if balance > 0:
            stack.append((i, balance))
        elif balance < 0:
            need = -balance
            while need > 0 and stack:
                ln, cnt = stack[-1]
                if cnt <= need:
                    need -= cnt
                    stack.pop()
                else:
                    stack[-1] = (ln, cnt - need)
                    need = 0
            if need > 0:
                issues.append('第%d行 多余的右括号: %s' % (i, stripped[:70]))

    for ln, cnt in stack:
        issues.append('第%d行 有 %d 个左括号没闭合: %s' % (ln, cnt, lines[ln - 1].strip()[:70]))

    label_set = {l.lower() for l in labels}
    for ln, target in refs:
        if target.lower() not in label_set:
            issues.append('第%d行 跳到不存在的标签 :%s' % (ln, target))

    flag = 'OK' if not issues else '有 %d 处可疑' % len(issues)
    out.append('%-18s 标签 %-3d 跳转 %-3d  %s' % (name, len(labels), len(refs), flag))
    for it in issues:
        out.append('    ! ' + it)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    dirs = [root] + sys.argv[1:]
    files = []
    for d in dirs:
        files.extend(sorted(glob.glob(os.path.join(d, '*.bat'))))
    if not files:
        print('没有找到 .bat 文件')
        return 0
    out = []
    for f in files:
        check(f, out)
    print('\n'.join(out))
    bad = sum(1 for l in out if l.strip().startswith('!') or ': ' in l and '可疑' in l)
    return 0 if bad == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
