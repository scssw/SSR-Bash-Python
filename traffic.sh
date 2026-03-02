#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

echo "1.显示所有用户流量信息"
echo "2.清空指定用户流量"
echo "3.一键修复到期时间"
echo "4.从备份中恢复非标到期时间"
echo "直接回车返回上级菜单"

while :; do echo
	read -p "请选择： " tc
	[ -z "$tc" ] && ssr && break
	if [[ ! $tc =~ ^[1-4]$ ]]; then
		echo "输入错误! 请输入正确的数字!"
	else
		break
	fi
done

if [[ $tc == 1 ]];then
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
	${PYTHON_CMD} /usr/local/SSR-Bash-Python/show_flow.py
	echo ""
	bash /usr/local/SSR-Bash-Python/traffic.sh
fi

if [[ $tc == 2 ]];then
	echo "1.使用用户名"
	echo "2.使用端口"
	echo ""
	while :; do echo
		read -p "请选择： " lsid
		if [[ ! $lsid =~ ^[1-2]$ ]]; then
			echo "输入错误! 请输入正确的数字!"
		else
			break	
		fi
	done

	if [[ $lsid == 1 ]];then
		read -p "输入用户名： " uid
		cd /usr/local/shadowsocksr
		python mujson_mgr.py -c -u $uid
		echo "已清空用户名为 ${uid} 的用户流量"
	fi
	
	if [[ $lsid == 2 ]];then
		read -p "输入端口号： " uid
		cd /usr/local/shadowsocksr
		python mujson_mgr.py -c -p $uid
		echo "已清空端口号为${uid} 的用户流量"
	fi
	echo ""
	bash /usr/local/SSR-Bash-Python/traffic.sh
fi

if [[ $tc == 3 ]];then
	bash /usr/local/SSR-Bash-Python/repair_timelimit.sh
	echo ""
	bash /usr/local/SSR-Bash-Python/traffic.sh
fi

if [[ $tc == 4 ]];then
	bash /usr/local/SSR-Bash-Python/restore_nonstandard_timelimit.sh
	echo ""
	bash /usr/local/SSR-Bash-Python/traffic.sh
fi
