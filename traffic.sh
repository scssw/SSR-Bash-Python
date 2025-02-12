#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

echo "1.显示所有用户流量信息"
echo "2.清空指定用户流量"
echo "直接回车返回上级菜单"

while :; do echo
	read -p "请选择： " tc
	[ -z "$tc" ] && ssr && break
	if [[ ! $tc =~ ^[1-3]$ ]]; then
		echo "输入错误! 请输入正确的数字!"
	else
		break
	fi
done

if [[ $tc == 1 ]];then
	P_V=`python -V 2>&1 | awk '{print $2}'`
	P_V1=`python -V 2>&1 | awk '{print $2}' | awk -F '.' '{print $1}'`
	if [[ ${P_V1} == 3 ]];then
		echo "你当前的python版本不支持此功能"
		echo "当前版本：${P_V} ,请降级至2.x版本"
	else
		python /usr/local/SSR-Bash-Python/show_flow.py
	fi
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

