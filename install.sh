#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

if [[ -e "/usr/local/SSR-Bash-Python/update.txt" ]];then
	echo ""
	cat /usr/local/SSR-Bash-Python/update.txt
	read -n 1 -p "任意键退出" any
	if [[ -e /usr/local/SSR-Bash-Python/oldupdate.txt ]];then
		rm -f /usr/local/SSR-Bash-Python/oldupdate.txt
	fi
	mv /usr/local/SSR-Bash-Python/update.txt /usr/local/SSR-Bash-Python/oldupdate.txt
fi
PID=$(ps -ef |grep -v grep | grep "bash" | grep "servercheck.sh" | grep "run" | awk '{print $2}')
if [[ -z $PID ]];then
	if [[ -e /usr/local/SSR-Bash-Python/check.log ]];then
		nohup bash /usr/local/SSR-Bash-Python/servercheck.sh run 2>/dev/null &
	fi
fi

#Check log
if [[ -e /usr/local/shadowsocksr/ssserver.log ]];then
log_max=$((10*1024))
log_filesize=$(du /usr/local/shadowsocksr/ssserver.log | awk -F' ' '{ print $1 }')
if [[ ${log_filesize} -ge ${log_max} ]];then
    sed -i -n '1,198N;$p;N;D' /usr/local/shadowsocksr/ssserver.log
fi
fi
yiyan(){
nowdate=$(date +%Y-%m-%d)
if [[ ! -e /tmp/yiyan.tmp || ! -e /tmp/yiyan.date ]];then
    echo "${nowdate}" > /tmp/yiyan.date
    #echo "$(curl -L -s https://sslapi.hitokoto.cn/?encode=text)" >> /tmp/yiyan.tmp
    echo "$(curl -L -s --connect-timeout 3 https://cn.fdos.me/yiyan/ || curl -L -s https://sslapi.hitokoto.cn/?encode=text)" >> /tmp/yiyan.tmp
    tail -n 1 /tmp/yiyan.tmp
else
    if [[ ${nowdate} == $(cat /tmp/yiyan.date) ]];then
        tail -n 1 /tmp/yiyan.tmp
    else
        echo "${nowdate}" > /tmp/yiyan.date
        #echo "$(curl -L -s https://sslapi.hitokoto.cn/?encode=text)" >> /tmp/yiyan.tmp
	echo "$(curl -L -s --connect-timeout 3 https://us.fdos.me/yiyan/ || curl -L -s --connect-timeout 3 https://sslapi.hitokoto.cn/?encode=text || echo '无法连接到远程数据库!')" >> /tmp/yiyan.tmp
        tail -n 1 /tmp/yiyan.tmp
    fi
fi
}

echo
echo "*******************"
echo ""
echo -e "欢迎使用 AR (Python Base) Beta\n"
echo -e "每日一言：霉运退散"
echo "输入数字选择功能："
echo ""
echo "1.服务器控制"
echo "2.用户管理"
echo "3.全局流量管理"
echo "4.域名绑定"
echo "5.程序管理"
echo "6.一键添加用户(使用最优配置)"
echo "0.退出程序"
while :; do echo
	read -p "请选择： " choice
	if [[ ! $choice =~ ^[0-6]$ ]]; then
		echo "输入错误! 请输入正确的数字!"
	else
		echo 
		echo 
		break	
	fi
done

if [[ $choice == 0 ]];then
	exit 0
fi

if [[ $choice == 1 ]];then
	bash /usr/local/SSR-Bash-Python/server.sh
fi

if [[ $choice == 2 ]];then
	bash /usr/local/SSR-Bash-Python/user.sh
fi

if [[ $choice == 3 ]];then
	bash /usr/local/SSR-Bash-Python/traffic.sh
fi

if [[ $choice == 4 ]];then
	clear
	current_ip=$(cat /usr/local/shadowsocksr/myip.txt)
	echo -e "当前绑定域名/IP: \e[32m$current_ip\e[0m"
	read -p "请输入新域名/IP（直接回车使用自动检测IP）： " domain
	
	if [[ -z "$domain" ]]; then
		domain=$(curl -s https://ipinfo.io/ip)
		echo "已自动获取IP: $domain"
	fi
	
	# 简单域名格式验证
	# 修正后的域名验证逻辑
	if [[ "$domain" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]] || [[ "$domain" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
	echo "$domain" > /usr/local/shadowsocksr/myip.txt
	echo -e "\e[32m绑定成功！\e[0m"
	else
	echo -e "\e[31m格式错误！有效格式：\n1. IPv4地址（如1.1.1.1）\n2. 域名（如example.com或sub.domain.net）\e[0m"
	fi
	
	read -n 1 -p "按任意键返回主菜单..."
	ssr
fi	

if [[ $choice == 5 ]];then
	bash /usr/local/SSR-Bash-Python/self.sh
fi

if [[ $choice == 6 ]];then
	bash /usr/local/SSR-Bash-Python/user/easyadd.sh
	ssr
fi
