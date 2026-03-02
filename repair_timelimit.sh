#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

mudb="/usr/local/shadowsocksr/mudb.json"
userlimit="/usr/local/SSR-Bash-Python/timelimit.db"
backup="${userlimit}.bak.$(date +%Y%m%d%H%M%S)"
tmpfile="/tmp/timelimit.repair.$$"

if [[ ! -f "${mudb}" ]]; then
	echo "错误：未找到 ${mudb}"
	exit 1
fi

if command -v python >/dev/null 2>&1; then
	PYTHON_CMD="python"
elif command -v python2 >/dev/null 2>&1; then
	PYTHON_CMD="python2"
elif command -v python3 >/dev/null 2>&1; then
	PYTHON_CMD="python3"
else
	echo "错误：未找到 Python 命令"
	exit 1
fi

echo "警告：此操作会根据 ${mudb} 重建到期时间，并覆盖 ${userlimit}"
echo "执行前会自动备份现有文件，但仍可能修复出错。"
read -p "确认继续吗？输入 YES 继续，其它任意键取消： " confirm_repair
if [[ "${confirm_repair}" != "YES" ]]; then
	echo "已取消修复"
	exit 0
fi

cleanup() {
	rm -f "${tmpfile}"
}
trap cleanup EXIT

"${PYTHON_CMD}" - "${mudb}" > "${tmpfile}" <<'PY'
# -*- coding: utf-8 -*-
from __future__ import print_function

import calendar
import datetime
import io
import json
import sys


def add_months(dt, months):
    month_index = dt.month - 1 + months
    year = dt.year + month_index // 12
    month = month_index % 12 + 1
    day = min(dt.day, calendar.monthrange(year, month)[1])
    return dt.replace(year=year, month=month, day=day)


mudb_path = sys.argv[1]
flow_months = {
    50: 1,
    150: 3,
    300: 6,
    600: 12,
}

try:
    with io.open(mudb_path, 'r', encoding='utf-8') as fh:
        users = json.load(fh)
except Exception as exc:
    sys.stderr.write("读取 mudb.json 失败: %s\n" % exc)
    sys.exit(1)

restored = []
skipped = []

for item in users:
    username = item.get('user', '')
    port = item.get('port', '')

    try:
        username_text = str(username)
        port_text = str(port)
        total_gb = int(item.get('transfer_enable', 0)) // 1024 // 1024 // 1024
    except Exception:
        skipped.append(str(username))
        continue

    if total_gb not in flow_months:
        skipped.append(username_text)
        continue

    if len(username_text) != 12 or not username_text.isdigit():
        skipped.append(username_text)
        continue

    try:
        start_at = datetime.datetime.strptime(username_text, '%Y%m%d%H%M')
    except ValueError:
        skipped.append(username_text)
        continue

    expire_at = add_months(start_at, flow_months[total_gb])
    restored.append('%s:%s' % (port_text, expire_at.strftime('%Y%m%d%H%M')))

for line in restored:
    print(line)

sys.stderr.write("可自动恢复 %d 条到期时间记录\n" % len(restored))
if skipped:
    sys.stderr.write(
        "已跳过 %d 个用户（用户名不是 12 位日期或流量限制不是 50/150/300/600GB）\n" % len(skipped)
    )
PY

if [[ $? -ne 0 ]]; then
	echo "修复失败"
	exit 1
fi

if [[ -f "${userlimit}" ]]; then
	cp "${userlimit}" "${backup}"
	echo "已备份原文件到 ${backup}"
fi

cat "${tmpfile}" > "${userlimit}"

record_count=$(grep -c . "${userlimit}" 2>/dev/null)
echo "已写入 ${record_count} 条记录到 ${userlimit}"

if [[ ${record_count} -eq 0 ]]; then
	echo "没有匹配到可自动恢复的用户"
fi

exit 0
