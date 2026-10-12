#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 .bat / .cmd 转成 cmd 能正确显示中文的编码：GBK + CRLF。

为什么需要它：
    cmd 默认代码页是 936（GBK），脚本存成 UTF-8 时里面的中文会变乱码。
    而且带 UTF-8 BOM 的 .bat 会让 cmd 把第一行 `@echo off` 读坏。

用法：
    python tools/bat-to-gbk.py                  # 转本文件所在项目根目录的全部 .bat
    python tools/bat-to-gbk.py 启动全部.bat      # 只转指定文件

改完脚本记得跑一次。已经是 GBK 的文件再跑也没事（幂等）。
"""
import glob
import os
import sys


def convert(path):
    with open(path, 'rb') as f:
        raw = f.read()

    if raw.startswith(b'\xef\xbb\xbf'):      # 去掉 UTF-8 BOM
        raw = raw[3:]

    try:
        text = raw.decode('utf-8')
    except UnicodeDecodeError:
        text = raw.decode('gbk')             # 本来就是 GBK，原样读回

    text = text.replace('\r\n', '\n').replace('\r', '\n')
    data = text.replace('\n', '\r\n').encode('gbk')

    with open(path, 'wb') as f:
        f.write(data)
    return len(data)


def main():
    args = sys.argv[1:]
    if args:
        targets = args
    else:
        root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        targets = sorted(glob.glob(os.path.join(root, '*.bat')))

    if not targets:
        print('没有找到 .bat 文件')
        return 0

    for t in targets:
        size = convert(t)
        print('GBK + CRLF  {:>7} bytes  {}'.format(size, os.path.basename(t)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
