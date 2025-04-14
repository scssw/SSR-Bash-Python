#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

#Check OS
if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ];then
OS=CentOS
[ -n "$(grep ' 7\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
[ -n "$(grep ' 6\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && CentOS_RHEL_version=6
[ -n "$(grep ' 5\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && CentOS_RHEL_version=5
elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" -o -e /etc/system-release ];then
OS=CentOS
CentOS_RHEL_version=6
elif [ -n "$(grep bian /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Debian' ];then
OS=Debian
[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Deepin /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Deepin' ];then
OS=Debian
[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Ubuntu /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Ubuntu' -o -n "$(grep 'Linux Mint' /etc/issue)" ];then
OS=Ubuntu
[ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
[ -n "$(grep 'Linux Mint 18' /etc/issue)" ] && Ubuntu_version=16
else
echo "Does not support this OS, Please contact the author! "
kill -9 $$
fi

#Main
updateme(){
	cd ~
	if [[ -e ~/version.txt ]];then
		rm -f ~/version.txt
	fi
	wget -q https://git.fdos.me/stack/AR-B-P-B/raw/develop/version.txt
	version1=`cat ~/version.txt`
	version2=`cat /usr/local/SSR-Bash-Python/version.txt`
	if [[ "$version1" == "$version2" ]];then
		echo "你当前已是最新版"
		sleep 2s
		ssr
	else
		echo "当前最新版本为$version1,输入y进行更新，其它按键退出"
		read -n 1 yn
		if [[ $yn == [Yy] ]];then
			export yn=n
			wget -q -N --no-check-certificate https://git.fdos.me/stack/AR-B-P-B/raw/master/install.sh && bash install.sh develop
			sleep 3s
			clear
			ssr || exit 0
		else
			echo "输入错误，退出"
			bash /usr/local/SSR-Bash-Python/self.sh
		fi
	fi
}
sumdc(){
	sum1=`cat /proc/sys/kernel/random/uuid| cksum | cut -f1 -d" "|head -c 2`
	sum2=`cat /proc/sys/kernel/random/uuid| cksum | cut -f1 -d" "|head -c 1`
	solve=`echo "$sum1-$sum2"|bc`
	echo -e "请输入\e[32;49m $sum1-$sum2 \e[0m的运算结果,表示你已经确认,输入错误将退出"
	read sv
}
# 修改备份功能中的端口检测命令（约第80行）
backup(){
    echo "开始备份!"
    mkdir -p ${HOME}/backup/tmp
    cd ${HOME}/backup/tmp
    cp /usr/local/shadowsocksr/mudb.json ./
    if [[ -e /usr/local/SSR-Bash-Python/check.log ]];then
        cp /usr/local/SSR-Bash-Python/check.log ./
    fi
    if [[ -e /usr/local/SSR-Bash-Python/timelimit.db ]];then
        cp /usr/local/SSR-Bash-Python/timelimit.db ./
    fi
    # 使用ss命令替代netstat
    ss -nlt | awk '/LISTEN/{print $4}' | awk -F: '{print $NF}' | sort -nu >> ./port.conf
    wf=`ls | wc -l`
    if [[ $wf -ge 2 ]];then
        tar -zcvf ../ssr-conf.tar.gz ./*
    fi
    cd ..
    if [[ -e ./ssr-conf.tar.gz ]];then
        rm -rf ./tmp
        echo "备份成功,文件位于${HOME}/backup/ssr-conf.tar.gz"
    else
        echo "备份失败"
    fi
}
recover(){
mkdir -p ${HOME}/backup 
echo "这将会导致你现有的配置被覆盖"
sumdc
if [[ "$sv" == "$solve" ]];then
    # 新增：彻底清理端口规则
    iptables-save | awk '!/dport/' > /tmp/iptables.clean
    iptables-restore < /tmp/iptables.clean
    iptables-save > /etc/iptables.up.rules
    bakf=$(ls ${HOME}/backup | wc -l)
    if [[ ${bakf} != 1 ]];then
        cd /usr/local/SSR-Bash-Python/Explorer 
        # 移除gcc编译步骤，改用shell内置sleep
        if [[ ! -e /bin/usleep ]];then
            echo -e "#!/bin/sh\nsleep 0.1" > /bin/usleep  # 创建替代脚本
            chmod +x /bin/usleep
        fi
        read -p "未发现备份文件或者存在多个备份文件，请手动选择（按Y键将打开一个文件管理器）" yn
        if [[ ${yn} == [Yy] ]];then
            chmod +x /usr/local/SSR-Bash-Python/Explorer/*
            bash ./Explorer.sh "${HOME}/backup"
	    chmod -x /usr/local/SSR-Bash-Python/Explorer/*
            bakfile=$(cat /tmp/BakFilename.tmp)
            if [[ ! -e ${bakfile} ]];then
                echo "无效!"
            fi
        fi
    fi
	if [[ -z ${bakfile} ]];then
		bakfile=${HOME}/backup/ssr-conf.tar.gz 
	fi
	if [[ -e ${bakfile} ]];then
        cd ${HOME}/backup
		tar -zxvf ${bakfile} -C ./
		if [[ -e ./check.log ]];then
			mv ./check.log /usr/local/SSR-Bash-Python/check.log
		fi
		if [[ -e /usr/local/SSR-Bash-Python/timelimit.db ]];then
			mv ./timelimit.db /usr/local/SSR-Bash-Python/timelimit.db
		fi
		if [[ ${OS} =~ ^Ubuntu$|^Debian$ ]];then
			iptables-restore < /etc/iptables.up.rules
			for port in `cat ./port.conf`; do iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $port -j ACCEPT ; done
			for port in `cat ./port.conf`; do iptables -I INPUT -m state --state NEW -m udp -p udp --dport $port -j ACCEPT ; done
			iptables-save > /etc/iptables.up.rules
			iptables -vnL
		fi
		if [[ ${OS} == CentOS ]];then
			if [[ $CentOS_RHEL_version == 7 ]];then
				iptables-restore < /etc/iptables.up.rules
				for port in `cat ./port.conf`; do iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $port -j ACCEPT ; done
				for port in `cat ./port.conf`; do iptables -I INPUT -m state --state NEW -m udp -p udp --dport $port -j ACCEPT ; done
				iptables-save > /etc/iptables.up.rules
				iptables -vnL
			else
				for port in `cat ./port.conf`; do iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $port -j ACCEPT ; done 
				for port in `cat ./port.conf`; do iptables -I INPUT -m state --state NEW -m udp -p udp --dport $port -j ACCEPT ; done
				/etc/init.d/iptables save
				/etc/init.d/iptables restart
				iptables -vnL && sed -i '5a#tcp port rule' /etc/sysconfig/iptables
			fi
		fi
		rm -f /usr/local/shadowsocksr/mudb.json
		mv ./mudb.json /usr/local/shadowsocksr/mudb.json
		rm -f ./port.conf
		echo "还原操作已完成，开始检测是否已生效!"
		bash /usr/local/SSR-Bash-Python/servercheck.sh test
		if [[ -z ${SSRcheck} ]];then
			echo "配置已生效，还原成功"
		else
			echo "配置未生效，还原失败，请联系作者解决"
		fi
		rm /tmp/BakFilename.tmp
	else
		echo "备份文件不存在，请检查！"
	fi
else
	echo "计算错误，正确结果为$solve"
fi
}
#Show
echo "输入数字选择功能："
echo ""
echo "3.端口段设置"
echo "4.卸载程序"
echo "5.备份配置"
echo "6.还原配置"
echo "7.设置所有用户限速"
echo "8.去除所有用户限速"
echo "9.设置主机限速"
echo "10.查看主机限速"
echo "11.设置开机自启动主机限速"
while :; do echo
	read -p "请选择： " choice
	if [[ ! $choice =~ ^([3-9]|10|11)$ ]]; then
		[ -z "$choice" ] && ssr && break
		echo "输入错误! 请输入正确的数字!"
	else
		break	
	fi
done
if [[ $choice == 3 ]];then
	echo "端口段设置："
	echo "1.添加端口段"
	echo "2.删除端口段"
	read -p "请选择： " subchoice
	if [[ $subchoice == 1 ]];then
		read -p "请输入起始端口(1000-65535)：" start_port
		read -p "请输入结束端口(1000-65535)：" end_port
		if [[ $start_port =~ ^[0-9]+$ ]] && [[ $end_port =~ ^[0-9]+$ ]] && \
		   [[ $start_port -ge 1000 ]] && [[ $start_port -le 65535 ]] && \
		   [[ $end_port -ge 1000 ]] && [[ $end_port -le 65535 ]] && \
		   [[ $start_port -le $end_port ]]; then
			echo "$start_port-$end_port" >> /usr/local/SSR-Bash-Python/port_ranges.conf
			echo "端口段添加成功！"
		else
			echo "输入错误！端口范围必须在1000-65535之间，且起始端口不能大于结束端口！"
		fi
	elif [[ $subchoice == 2 ]];then
		if [[ ! -f /usr/local/SSR-Bash-Python/port_ranges.conf ]]; then
			echo "暂无端口段配置"
		else
			echo "当前端口段列表："
			cat /usr/local/SSR-Bash-Python/port_ranges.conf | grep -v '^#' | nl -s ". "
			read -p "请输入要删除的端口段序号：" del_num
			if [[ $del_num =~ ^[0-9]+$ ]]; then
				sed -i "${del_num}d" /usr/local/SSR-Bash-Python/port_ranges.conf
				echo "删除成功！"
			else
				echo "输入错误！请输入正确的序号！"
			fi
		fi
	else
		echo "输入错误！请输入正确的选项！"
	fi
	bash /usr/local/SSR-Bash-Python/self.sh
fi

if [[ $choice == 4 ]];then
	echo "你在做什么？你真的这么狠心吗？"
	sumdc
	if [[ "$sv" == "$solve" ]];then
		wget -q -N --no-check-certificate https://raw.githubusercontent.com/scssw/SSR-Bash-Python/master/install.sh  && bash install.sh uninstall
		exit 0
	else
		echo "计算错误，正确结果为$solve"
		bash /usr/local/SSR-Bash-Python/self.sh
	fi
fi
if [[ $choice == 5 ]];then
	if [[ ! -e ${HOME}/backup/ssr-conf.tar.gz ]];then
		backup
	else
		cd ${HOME}/backup
		mv ./ssr-conf.tar.gz ./ssr-conf-`date +%Y-%m-%d_%H:%M:%S`.tar.gz
		backup
	fi
	bash /usr/local/SSR-Bash-Python/self.sh
fi
if [[ $choice == 6 ]];then
	recover
	bash /usr/local/SSR-Bash-Python/self.sh
fi
if [[ $choice == 7 ]];then
	read -p "请输入限速值(单位：Mbps)：" speed_limit
	if [[ ! $speed_limit =~ ^[0-9]+$ ]]; then
		echo "输入错误！请输入数字！"
		bash /usr/local/SSR-Bash-Python/self.sh
	else
		speed_limit_kbps=$(($speed_limit * 128))
		python /usr/local/SSR-Bash-Python/speed.py $speed_limit_kbps
		echo "已成功设置所有用户限速为 ${speed_limit} Mbps"
		bash /usr/local/SSR-Bash-Python/self.sh
	fi
fi
if [[ $choice == 8 ]];then
	python /usr/local/SSR-Bash-Python/speed.py 0
	echo "已去除所有用户节点限速"
	bash /usr/local/SSR-Bash-Python/self.sh
fi
if [[ $choice == 9 ]];then
	read -p "请输入限速值(单位：Mbps)：" speed_limit
	if [[ ! $speed_limit =~ ^[0-9]+$ ]]; then
		echo "输入错误！请输入数字！"
		bash /usr/local/SSR-Bash-Python/self.sh
	else
		# 获取主网卡名称
		main_interface=$(ip route | grep default | awk '{print $5}')
		if [[ -z $main_interface ]]; then
			echo "无法获取主网卡名称，请手动设置"
			bash /usr/local/SSR-Bash-Python/self.sh
			exit 1
		fi
		# 清除已有的限速规则
		tc qdisc del dev $main_interface root 2>/dev/null
		# 添加新的限速规则
		tc qdisc add dev $main_interface root tbf rate ${speed_limit}mbit burst 32kbit latency 400ms
		echo "已成功设置主机限速为 ${speed_limit} Mbps"
		bash /usr/local/SSR-Bash-Python/self.sh
	fi
fi
if [[ $choice == 10 ]];then
	# 获取主网卡名称
	main_interface=$(ip route | grep default | awk '{print $5}')
	if [[ -z $main_interface ]]; then
		echo "无法获取主网卡名称"
		bash /usr/local/SSR-Bash-Python/self.sh
		exit 1
	fi
	# 查看当前限速规则
	current_limit=$(tc qdisc show dev $main_interface | grep "tbf" | grep -oP "rate \K[0-9]+[a-zA-Z]+")
	if [[ -z $current_limit ]]; then
		echo "当前未设置主机限速"
	else
		echo "当前主机限速为：$current_limit"
	fi
	echo ""
	read -n 1 -p "按任意键继续..." any_key
	bash /usr/local/SSR-Bash-Python/self.sh
fi
if [[ $choice == 11 ]];then
	read -p "请输入限速值(单位：Mbps)：" speed_limit
	if [[ ! $speed_limit =~ ^[0-9]+$ ]]; then
		echo "输入错误！请输入数字！"
		bash /usr/local/SSR-Bash-Python/self.sh
	else
		# 获取主网卡名称
		main_interface=$(ip route | grep default | awk '{print $5}')
		if [[ -z $main_interface ]]; then
			echo "无法获取主网卡名称，请手动设置"
			bash /usr/local/SSR-Bash-Python/self.sh
			exit 1
		fi
		
		# 创建限速脚本
		cat > /usr/local/SSR-Bash-Python/tc_limit.sh << EOF
#!/bin/bash
# 清除已有的限速规则
tc qdisc del dev ${main_interface} root 2>/dev/null
# 添加新的限速规则
tc qdisc add dev ${main_interface} root tbf rate ${speed_limit}mbit burst 32kbit latency 400ms
EOF
		chmod +x /usr/local/SSR-Bash-Python/tc_limit.sh
		
		# 设置开机自启动
		if [ -d "/etc/systemd/system" ]; then
			# 对于使用systemd的系统
			cat > /etc/systemd/system/tc-limit.service << EOF
[Unit]
Description=TC Speed Limit
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/SSR-Bash-Python/tc_limit.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
			systemctl daemon-reload
			systemctl enable tc-limit.service
			systemctl start tc-limit.service
			echo "已成功设置主机限速为 ${speed_limit} Mbps 并设置开机自启动（systemd服务）"
		elif [ -f "/etc/rc.local" ]; then
			# 对于使用rc.local的系统
			if ! grep -q "/usr/local/SSR-Bash-Python/tc_limit.sh" /etc/rc.local; then
				sed -i '/exit 0/i\/usr/local/SSR-Bash-Python/tc_limit.sh' /etc/rc.local
			fi
			# 立即应用限速
			bash /usr/local/SSR-Bash-Python/tc_limit.sh
			echo "已成功设置主机限速为 ${speed_limit} Mbps 并设置开机自启动（rc.local）"
		else
			# 如果以上方法都不适用，创建crontab
			(crontab -l 2>/dev/null; echo "@reboot /usr/local/SSR-Bash-Python/tc_limit.sh") | crontab -
			# 立即应用限速
			bash /usr/local/SSR-Bash-Python/tc_limit.sh
			echo "已成功设置主机限速为 ${speed_limit} Mbps 并设置开机自启动（crontab）"
		fi
		
		bash /usr/local/SSR-Bash-Python/self.sh
	fi
fi
if [[ $choice == 12 ]];then
	# 创建web面板启动脚本
	cat > /usr/local/SSR-Bash-Python/web_panel_start.sh << EOF
#!/bin/bash
cd /usr/local/shadowsocksr
python server.py
EOF
	chmod +x /usr/local/SSR-Bash-Python/web_panel_start.sh
	
	# 设置开机自启动
	if [ -d "/etc/systemd/system" ]; then
		# 对于使用systemd的系统
		cat > /etc/systemd/system/ssr-web-panel.service << EOF
[Unit]
Description=SSR Web Panel
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python /usr/local/shadowsocksr/server.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
		systemctl daemon-reload
		systemctl enable ssr-web-panel.service
		systemctl start ssr-web-panel.service
		echo "已成功设置Web面板开机自启动（systemd服务）"
	elif [ -f "/etc/rc.local" ]; then
		# 对于使用rc.local的系统
		if ! grep -q "cd /usr/local/shadowsocksr && nohup python server.py > /dev/null 2>&1 &" /etc/rc.local; then
			sed -i '/exit 0/i\cd /usr/local/shadowsocksr && nohup python server.py > /dev/null 2>&1 &' /etc/rc.local
		fi
		# 立即启动web面板
		cd /usr/local/shadowsocksr && nohup python server.py > /dev/null 2>&1 &
		echo "已成功设置Web面板开机自启动（rc.local）"
	else
		# 如果以上方法都不适用，使用crontab
		(crontab -l 2>/dev/null; echo "@reboot cd /usr/local/shadowsocksr && python server.py > /dev/null 2>&1 &") | crontab -
		# 立即启动web面板
		cd /usr/local/shadowsocksr && nohup python server.py > /dev/null 2>&1 &
		echo "已成功设置Web面板开机自启动（crontab）"
	fi
	
	echo "Web面板已启动并设置开机自启动"
	bash /usr/local/SSR-Bash-Python/self.sh
fi
exit 0
