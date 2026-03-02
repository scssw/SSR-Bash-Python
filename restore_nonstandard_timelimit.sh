#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

mudb="/usr/local/shadowsocksr/mudb.json"
userlimit="/usr/local/SSR-Bash-Python/timelimit.db"
backup="${userlimit}.bak.$(date +%Y%m%d%H%M%S)"
paste_file="/tmp/timelimit.restore.input.$$"
result_file="/tmp/timelimit.restore.result.$$"

if [[ ! -f "${mudb}" ]]; then
	echo "错误：未找到 ${mudb}"
	exit 1
fi

if command -v python3 >/dev/null 2>&1; then
	PYTHON_CMD="python3"
elif command -v python3 >/dev/null 2>&1; then
	PYTHON_CMD="python3"
elif command -v python3 >/dev/null 2>&1; then
	PYTHON_CMD="python3"
else
	echo "错误：未找到 Python 命令"
	exit 1
fi

cleanup() {
	rm -f "${paste_file}" "${result_file}"
}
trap cleanup EXIT

echo "请粘贴备份里的到期时间数据，格式为 端口:到期时间"
echo "例如：42311:202603030917"
echo "直接回车结束输入并开始恢复"
echo ""

> "${paste_file}"
while IFS= read -r line; do
	[[ -z "${line}" ]] && break
	printf '%s\n' "${line}" >> "${paste_file}"
done

if [[ ! -s "${paste_file}" ]]; then
	echo "未输入任何数据，已取消"
	exit 0
fi

"${PYTHON_CMD}" - "${mudb}" "${userlimit}" "${paste_file}" "${result_file}" <<'PY'
# -*- coding: utf-8 -*-
from __future__ import print_function

import io
import json
import os
import re
import sys


mudb_path = sys.argv[1]
timelimit_path = sys.argv[2]
paste_path = sys.argv[3]
result_path = sys.argv[4]
flow_months = set([50, 150, 300, 600])
entry_pattern = re.compile(r'^(\d+):(\d{12})$')


def read_lines(path):
    if not os.path.exists(path):
        return []
    with io.open(path, 'r', encoding='utf-8') as fh:
        return [line.rstrip('\n') for line in fh]


with io.open(mudb_path, 'r', encoding='utf-8') as fh:
    users = json.load(fh)

existing_lines = read_lines(timelimit_path)
existing_ports = set()
for line in existing_lines:
    match = entry_pattern.match(line.strip())
    if match:
        existing_ports.add(match.group(1))

pasted_map = {}
for raw_line in read_lines(paste_path):
    line = raw_line.strip()
    match = entry_pattern.match(line)
    if match:
        pasted_map[match.group(1)] = match.group(2)

nonstandard_ports = []
for item in users:
    try:
        username = str(item.get('user', ''))
        port = str(item.get('port', ''))
        total_gb = int(item.get('transfer_enable', 0)) // 1024 // 1024 // 1024
    except Exception:
        continue

    is_standard_name = len(username) == 12 and username.isdigit()
    is_standard_flow = total_gb in flow_months
    if not (is_standard_name and is_standard_flow):
        nonstandard_ports.append(port)

added_lines = []
for port in nonstandard_ports:
    if port in existing_ports:
        continue
    if port in pasted_map:
        line = '%s:%s' % (port, pasted_map[port])
        added_lines.append(line)
        existing_ports.add(port)

missing_ports = []
for port in nonstandard_ports:
    if port not in existing_ports:
        missing_ports.append(port)

with open(result_path, 'w') as fh:
    for line in added_lines:
        fh.write(line + '\n')
    fh.write('---\n')
    for port in missing_ports:
        fh.write(port + '\n')

sys.stderr.write("识别到 %d 个非标用户端口\n" % len(nonstandard_ports))
sys.stderr.write("本次可补写 %d 条记录\n" % len(added_lines))
sys.stderr.write("恢复后仍缺失 %d 个端口\n" % len(missing_ports))
PY

if [[ $? -ne 0 ]]; then
	echo "恢复失败"
	exit 1
fi

added_count=$(awk 'BEGIN{n=0} $0=="---"{print n; exit} {n++}' "${result_file}")

if [[ "${added_count}" -gt 0 ]]; then
	if [[ -f "${userlimit}" ]]; then
		cp "${userlimit}" "${backup}"
		echo "已备份原文件到 ${backup}"
	else
		> "${userlimit}"
	fi
	awk 'flag==0 && $0=="---"{flag=1; exit} flag==0{print}' "${result_file}" >> "${userlimit}"
	echo "已补写 ${added_count} 条非标到期时间到 ${userlimit}"
else
	echo "没有匹配到可补写的非标到期时间"
fi

missing_ports=$(awk 'flag==1{print} $0=="---"{flag=1; next}' "${result_file}")
if [[ -n "${missing_ports}" ]]; then
	echo ""
	echo "以下非标端口仍缺少到期时间："
	printf '%s\n' "${missing_ports}"
else
	echo ""
	echo "非标端口已全部补齐"
fi

exit 0
