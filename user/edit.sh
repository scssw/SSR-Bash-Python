#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#Check Root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

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
echo "${CFAILURE}Does not support this OS, Please contact the author! ${CEND}"
kill -9 $$
fi
uqr(){
	username=`python3 mujson_mgr.py -l -u $uid | head -n 2 | tail -n 1 | awk -F" : " '{ print $2 }'`
	if [[ -e ~/SSRQR/$username.png ]];then
		bash /usr/local/SSR-Bash-Python/user/qrcode.sh u $uid
	fi
}
pqr(){
	username=`python3 mujson_mgr.py -l -p $uid | head -n 2 | tail -n 1 | awk -F" : " '{ print $2 }'`
	if [[ -e ~/SSRQR/$username.png ]];then
		bash /usr/local/SSR-Bash-Python/user/qrcode.sh p $uid
	fi
}

lsid=2
read -p "输入端口号： " uid
cd /usr/local/shadowsocksr
checkuid=$(python3 mujson_mgr.py -l -p $uid 2>/dev/null)
if [[ -z ${checkuid} ]];then
	echo "用户不存在！"
	bash /usr/local/SSR-Bash-Python/user/edit.sh || exit 0
else
	python3 mujson_mgr.py -l -p $uid

	# 生成带备注的SSR链接
	myipname=`cat /usr/local/shadowsocksr/myip.txt`
	host_prefix="${myipname%%.*}"
	if [[ "$myipname" == *.* ]]; then
		ipv6_myipname="${host_prefix}6${myipname#"$host_prefix"}"
	else
		ipv6_myipname="${myipname}6"
	fi
	username=`python3 mujson_mgr.py -l -p $uid | head -n 2 | tail -n 1 | awk -F" : " '{ print $2 }'`
	upass=`python3 mujson_mgr.py -l -p $uid | grep "passwd :" | awk -F" : " '{ print $2 }'`
	um1=`python3 mujson_mgr.py -l -p $uid | grep "method :" | awk -F" : " '{ print $2 }'`
	ux1=`python3 mujson_mgr.py -l -p $uid | grep "protocol :" | awk -F" : " '{ print $2 }'`
	uo1=`python3 mujson_mgr.py -l -p $uid | grep "obfs :" | awk -F" : " '{ print $2 }'`

	# 从域名中提取前缀并转换为大写
	prefix=$(echo $myipname | awk -F'.' '{print $1}' | tr '[:lower:]' '[:upper:]')

	# 从timelimit.db中提取到期时间并格式化
	expire_date=$(cat /usr/local/SSR-Bash-Python/timelimit.db | grep "${uid}:" | awk -F":" '{print $2}' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\2.\3/' | sed 's/^0//' | sed 's/\.0/./')

	# 组合备注
	remark="${prefix}:${uid}-${expire_date}"
	remark_ipv6="${prefix}6:${uid}-${expire_date}"

	# 生成带备注的加密SSR链接
	encoded_pass=$(echo -n "$upass" | base64 | tr '+/' '-_' | tr -d '=')
	encoded_remark=$(echo -n "$remark" | base64 | tr '+/' '-_' | tr -d '=')
	encoded_remark_ipv6=$(echo -n "$remark_ipv6" | base64 | tr '+/' '-_' | tr -d '=')
	server_string="${myipname}:${uid}:${ux1}:${um1}:${uo1}:${encoded_pass}/?remarks=${encoded_remark}"
	encoded_server=$(echo -n "$server_string" | base64 -w 0 | tr '+/' '-_' | tr -d '=')
	ssr_link="ssr://${encoded_server}"
	host_prefix="${myipname%%.*}"
	if [[ "$myipname" == *.* ]]; then
		ipv6_myipname="${host_prefix}6${myipname#"$host_prefix"}"
	else
		ipv6_myipname="${myipname}6"
	fi
	server_string_ipv6="${ipv6_myipname}:${uid}:${ux1}:${um1}:${uo1}:${encoded_pass}/?remarks=${encoded_remark_ipv6}"
	encoded_server_ipv6=$(echo -n "$server_string_ipv6" | base64 -w 0 | tr '+/' '-_' | tr -d '=')
	ssr_link_ipv6="ssr://${encoded_server_ipv6}"

	echo "$ssr_link"
	echo "$ssr_link_ipv6"
	echo "IPv6 Host: $ipv6_myipname"
	echo "IPv6备注: $remark_ipv6"
	echo ""
	echo "备注: $remark"
fi

echo -e "\n1.修改密码"
echo "2.修改加密"
echo "3.修改协议"
echo "4.修改混淆"
echo "5.修改协议参数"
echo "6.修改混淆参数"
echo "7.修改流量"
echo "8.修改端口限制"
echo "9.修改总端口限速"
echo "10.修改连接数限制"
echo "11.修改时限"
echo "12.修改端口号"

while :; do echo
	read -p "请选择： " ec
	if [[ ! $ec =~ ^[1-9]$ ]]; then
		if [[ $ec == 10 ]]; then
			break
		elif [[ $ec == 11 ]]; then
			break
		elif [[ $ec == 12 ]]; then
			break
		fi
		echo "输入错误! 请输入正确的数字!"
	else
		break	
	fi
done

if [[ $ec == 1 ]];then
	read -p "输入密码： " upass
	cd /usr/local/shadowsocksr
	if [[ $lsid == 1 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -u $uid -k $upass
		echo "用户名为 $uid 的用户密码已设置成 $upass"
		uqr
	fi
	if [[ $lsid == 2 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -p $uid -k $upass
		echo "端口号为 $uid 的用户密码已设置成 $upass"
		pqr
	fi
fi
if [[ $ec == 2 ]];then
	echo "加密方式"
	echo '1.none'
	echo '2.aes-128-cfb'
	echo '3.aes-256-cfb'
	echo '4.aes-128-ctr'
	echo '5.aes-256-ctr'
	echo '6.rc4-md5'
	echo '7.chacha20'
	echo '8.chacha20-ietf'
	echo '9.salsa20'
	while :; do echo
		read -p "输入新加密方式： " um
		if [[ ! $um =~ ^[1-9]$ ]]; then
			echo "输入错误! 请输入正确的数字!"
		else
			break	
		fi
	done
	
	if [[ $um == 1 ]];then
		um1="none"
	fi
	if [[ $um == 2 ]];then
		um1="aes-128-cfb"
	fi
	if [[ $um == 3 ]];then
		um1="aes-256-cfb"
	fi
	if [[ $um == 4 ]];then
		um1="aes-128-ctr"
	fi
	if [[ $um == 5 ]];then
		um1="aes-256-ctr"
	fi
	if [[ $um == 6 ]];then
		um1="rc4-md5"
	fi
	if [[ $um == 7 ]];then
		um1="chacha20"
	fi
	if [[ $um == 8 ]];then
		um1="chacha20-ietf"
	fi
	if [[ $um == 9 ]];then
		um1="salsa20"
	fi
	cd /usr/local/shadowsocksr
	if [[ $lsid == 1 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -u $uid -m $um1
		echo "用户名为 $uid 的加密方式已切换为 $um1"
		uqr
	fi
	if [[ $lsid == 2 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -p $uid -m $um1
		echo "端口号为 $uid 的加密方式已切换为 $um1"
		pqr
	fi
fi
if [[ $ec == 3 ]];then
	echo "协议方式"
	echo '1.origin'
	echo '2.auth_sha1_v4'
	echo '3.auth_aes128_md5'
	echo '4.auth_aes128_sha1'
	echo '5.verify_deflate'
	echo '6.auth_chain_a'
	echo '7.auth_chain_b'
	echo '8.auth_chain_c'
	echo '9.auth_chain_d'
	echo '10.auth_chain_e'
	while :; do echo
	read -p "输入协议方式： " ux
	if [[ ! $ux =~ ^[1-9]$ ]]; then
		if [[ $ux == 10 ]]; then
			break
		fi
		echo "输入错误! 请输入正确的数字!"
	else
		break	
	fi
	done
	
	if [[ $ux == 2 ]];then
	while :; do echo
		read -p "是否兼容原版协议（y/n）： " ifprotocolcompatible
		if [[ ! $ifprotocolcompatible =~ ^[y,n]$ ]]; then
			echo "输入错误! 请输入y或者n!"
		else
			break
		fi
	done
	fi

	if [[ $ux == 1 ]];then
	ux1="origin"
	fi
	if [[ $ux == 2 ]];then
		ux1="auth_sha1_v4"
	fi
	if [[ $ux == 3 ]];then
		ux1="auth_aes128_md5"
	fi
	if [[ $ux == 4 ]];then
		ux1="auth_aes128_sha1"
	fi
	if [[ $ux == 5 ]];then
		ux1="verify_deflate"
	fi
	if [[ $ux == 6 ]];then
		ux1="auth_chain_a"
	fi
	if [[ $ux == 7 ]];then
		ux1="auth_chain_b"
	fi
	if [[ $ux == 8 ]];then
		ux1="auth_chain_c"
	fi
	if [[ $ux == 9 ]];then
		ux1="auth_chain_d"
	fi
	if [[ $ux == 10 ]];then
		ux1="auth_chain_e"
	fi

	if [[ $ifprotocolcompatible == y ]]; then
		ux1=${ux1}"_compatible"
	fi

	cd /usr/local/shadowsocksr
	if [[ $lsid == 1 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -u $uid -O $ux1
		echo "用户名为 $uid 的协议方式已更改为 $ux1"
		uqr
	fi
	if [[ $lsid == 2 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -p $uid -O $ux1
		echo "端口号为 $uid 的协议方式已更改为 $ux1"
		pqr
	fi
fi
if [[ $ec == 4 ]];then
	echo "混淆方式"
	echo '1.plain'
	echo '2.http_simple'
	echo '3.http_post'
	echo '4.tls1.2_ticket_auth'
	while :; do echo
	read -p "输入混淆方式： " uo
	if [[ ! $uo =~ ^[1-4]$ ]]; then
		echo "输入错误! 请输入正确的数字!"
	else
		break	
	fi
	done
	
	if [[ $uo != 1 ]];then
		while :; do echo
			read -p "是否兼容原版混淆（y/n）： " ifobfscompatible
			if [[ ! $ifobfscompatible =~ ^[y,n]$ ]]; then
				echo "输入错误! 请输入y或者n!"
			else
				break
			fi
		done
	fi

	if [[ $uo == 1 ]];then
		uo1="plain"
	fi
	if [[ $uo == 2 ]];then
		uo1="http_simple"
	fi
	if [[ $uo == 3 ]];then
		uo1="http_post"
	fi
	if [[ $uo == 4 ]];then
		uo1="tls1.2_ticket_auth"
	fi
	
	if [[ $ifobfscompatible == y ]]; then
		uo1=${uo1}"_compatible"
	fi
	
	cd /usr/local/shadowsocksr
	if [[ $lsid == 1 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -u $uid -o $uo1
		echo "用户名为 $uid 的混淆方式已更改为 $uo1"
	fi
	if [[ $lsid == 2 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -p $uid -o $uo1
		echo "端口号为 $uid 的混淆方式已更改为 $uo1"
	fi
fi
if [[ $ec == 5 ]];then
	read -p "输入协议参数： " ux2
	cd /usr/local/shadowsocksr
	if [[ $lsid == 1 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -u $uid -G $ux2
		echo "用户名为 $uid 的协议参数已更改为 $ux2"
	fi
	if [[ $lsid == 2 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -p $uid -G $ux2
		echo "端口号为 $uid 的协议参数已更改为 $ux2"
	fi
fi
if [[ $ec == 6 ]];then
	read -p "输入混淆参数： " uo2
	cd /usr/local/shadowsocksr
	if [[ $lsid == 1 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -u $uid -g $uo2
		echo "用户名为 $uid 的混淆参数已更改为 $uo2"
	fi
	if [[ $lsid == 2 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -p $uid -g $uo2
		echo "端口号为 $uid 的混淆参数已更改为 $uo2"
	fi
fi
if [[ $ec == 7 ]];then	
	while :; do echo
		read -p "输入流量限制(只需输入数字，单位：GB)： " ut
		if [[ "$ut" =~ ^(-?|\+?)[0-9]+(\.?[0-9]+)?$ ]];then
			break
		else
			echo 'Input Error! Please Try Again!'
		fi
	done
	cd /usr/local/shadowsocksr
	if [[ $lsid == 1 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -u $uid -t $ut
		echo "用户名为 $uid 的流量限制已改为 $ut"
		uqr
	fi
	if [[ $lsid == 2 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -p $uid -t $ut
		echo "端口号为 $uid 的流量限制已改为 $ut"
		pqr
	fi
fi
if [[ $ec == 8 ]];then
	read -p "输入端口限制（如1~80和90~100输入"1-80,90-100"）： " ub
	cd /usr/local/shadowsocksr
	if [[ $lsid == 1 ]];then
		cd /usr/local/shadowsocksr
		#python3 mujson_mgr.py -e -u $uid -f $ub
		echo "此功能目前无法使用"
	fi
	if [[ $lsid == 2 ]];then
		cd /usr/local/shadowsocksr
		#python3 mujson_mgr.py -e -p $uid -f $ub
		echo "此功能目前无法使用"
	fi
fi

if [[ $ec == 9 ]];then
	while :; do echo
		read -p "输入端口总限速(只需输入数字，单位：KB/s)： " us
		if [[ "$us" =~ ^(-?|\+?)[0-9]+(\.?[0-9]+)?$ ]];then
	   		break
		else
	   		echo 'Input Error!'
		fi
	done
	cd /usr/local/shadowsocksr
	if [[ $lsid == 1 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -u $uid -S $us
		echo "用户名为 $uid 的用户端口限速已修改为 $us KB/s"
		uqr
	fi
	if [[ $lsid == 2 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -p $uid -S $us
		echo "端口号为 $uid 的用户端口限速已修改为 $us KB/s"
		pqr
	fi
fi
 
if [[ $ec == 10 ]];then
	while :; do echo
		echo "注意：auth_* 系列协议 不兼容原版才有效"
		read -p "输入允许的连接数(建议最少 2个)： " uparam
		if [[ "$uparam" =~ ^(-?|\+?)[0-9]+(\.?[0-9]+)?$ ]];then
	   		break
		else
	   		echo 'Input Error!'
		fi
	done
	if [[ $lsid == 1 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -u $uid -G $uparam
		echo "用户名为 $uid 的允许的连接数已修改为 $uparam "
		uqr
	fi
	if [[ $lsid == 2 ]];then
		cd /usr/local/shadowsocksr
		python3 mujson_mgr.py -e -p $uid -G $uparam
		echo "端口号为 $uid 的允许的连接数已修改为 $uparam "
		pqr
	fi
fi

if [[ $ec == 11 ]];then
	userlimit="/usr/local/SSR-Bash-Python/timelimit.db"
	if [[ ${lsid} == 1 ]];then
		port=$(python3 mujson_mgr.py -l -u ${uid} | grep "port :" | awk -F" : " '{ print $2 }')
		datelimit=$(cat ${userlimit} | grep "${port}:" | awk -F":" '{ print $2 }' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1年\2月\3日 \4:/')
		if [[ -z ${datelimit} ]];then
			datelimit="永久"
		fi
		echo -e "当前用户端口号：${port},有效期至：${datelimit}\n"
		read -p "请输入新的有效期(格式：年.月.日如25.5.12表示2025年5月12日，或月[m]日[d]小时[h]如1m表示1个月){默认：永久[a]}: " limit
		if [[ -z ${limit} ]];then
			limit="a"
		# 检测是否为年.月.日格式 (如 25.5.12)
		elif [[ $limit =~ ^[0-9]{2}\.[0-9]{1,2}\.[0-9]{1,2}$ ]]; then
			# 提取年月日
			year=$(echo $limit | cut -d. -f1)
			month=$(echo $limit | cut -d. -f2)
			day=$(echo $limit | cut -d. -f3)
			
			# 获取当前小时和分钟
			current_hour=$(date +"%H")
			current_min=$(date +"%M")
			
			# 构建完整日期字符串 (20年.月.日时分)
			full_year="20${year}"
			# 确保月和日是两位数
			month=$(printf "%02d" $month)
			day=$(printf "%02d" $day)
			
			# 直接设置为完整日期格式，不通过timelimit.sh的参数处理
			echo "${port}:${full_year}${month}${day}${current_hour}${current_min}" > /tmp/tempdate.txt
			sed -i "/^${port}:/d" ${userlimit}
			cat /tmp/tempdate.txt >> ${userlimit}
			rm -f /tmp/tempdate.txt
			limit="setok" # 标记已设置，避免再次调用timelimit.sh
		fi
		
		# 只有在未直接设置日期时才调用timelimit.sh
		if [[ $limit != "setok" ]]; then
			bash /usr/local/SSR-Bash-Python/timelimit.sh e ${port} ${limit}
		fi
	fi
	
	if [[ ${lsid} == 2 ]];then
		datelimit=$(cat ${userlimit} | grep "${uid}:" | awk -F":" '{ print $2 }' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1年\2月\3日 \4:/')
		if [[ -z ${datelimit} ]];then
			datelimit="永久"
		fi
		echo -e "当前用户端口号：${uid},有效期至：${datelimit}\n"
		read -p "请输入新的有效期(格式：年.月.日如25.5.12表示2025年5月12日，或月[m]日[d]小时[h]如1m表示1个月){默认：永久[a]}: " limit
		if [[ -z ${limit} ]];then
			limit="a"
		# 检测是否为年.月.日格式 (如 25.5.12)
		elif [[ $limit =~ ^[0-9]{2}\.[0-9]{1,2}\.[0-9]{1,2}$ ]]; then
			# 提取年月日
			year=$(echo $limit | cut -d. -f1)
			month=$(echo $limit | cut -d. -f2)
			day=$(echo $limit | cut -d. -f3)
			
			# 获取当前小时和分钟
			current_hour=$(date +"%H")
			current_min=$(date +"%M")
			
			# 构建完整日期字符串 (20年.月.日时分)
			full_year="20${year}"
			# 确保月和日是两位数
			month=$(printf "%02d" $month)
			day=$(printf "%02d" $day)
			
			# 直接设置为完整日期格式，不通过timelimit.sh的参数处理
			echo "${uid}:${full_year}${month}${day}${current_hour}${current_min}" > /tmp/tempdate.txt
			sed -i "/^${uid}:/d" ${userlimit}
			cat /tmp/tempdate.txt >> ${userlimit}
			rm -f /tmp/tempdate.txt
			limit="setok" # 标记已设置，避免再次调用timelimit.sh
		fi
		
		# 只有在未直接设置日期时才调用timelimit.sh
		if [[ $limit != "setok" ]]; then
			bash /usr/local/SSR-Bash-Python/timelimit.sh e ${uid} ${limit}
		fi
		port=${uid}
	fi
	
	datelimit=$(cat ${userlimit} | grep "${port}:" | awk -F":" '{ print $2 }' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1年\2月\3日 \4:/')
	if [[ -z ${datelimit} ]];then
		datelimit="永久"
	fi
	echo -e "修改成功!当前用户端口号：${port},新的有效期至：${datelimit}\n"
	
	# 显示用户完整信息
	cd /usr/local/shadowsocksr
	python3 mujson_mgr.py -l -p ${port}
	
	# 生成带备注的SSR链接
	myipname=`cat /usr/local/shadowsocksr/myip.txt`
	username=`python3 mujson_mgr.py -l -p ${port} | head -n 2 | tail -n 1 | awk -F" : " '{ print $2 }'`
	upass=`python3 mujson_mgr.py -l -p ${port} | grep "passwd :" | awk -F" : " '{ print $2 }'`
	um1=`python3 mujson_mgr.py -l -p ${port} | grep "method :" | awk -F" : " '{ print $2 }'`
	ux1=`python3 mujson_mgr.py -l -p ${port} | grep "protocol :" | awk -F" : " '{ print $2 }'`
	uo1=`python3 mujson_mgr.py -l -p ${port} | grep "obfs :" | awk -F" : " '{ print $2 }'`

	# 从域名中提取前缀并转换为大写
	prefix=$(echo $myipname | awk -F'.' '{print $1}' | tr '[:lower:]' '[:upper:]')

	# 从timelimit.db中提取到期时间并格式化
	expire_date=$(cat /usr/local/SSR-Bash-Python/timelimit.db | grep "${port}:" | awk -F":" '{print $2}' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\2.\3/' | sed 's/^0//' | sed 's/\.0/./')

	# 组合备注
	remark="${prefix}:${port}-${expire_date}"
	remark_ipv6="${prefix}6:${port}-${expire_date}"

	# 生成带备注的加密SSR链接
	encoded_pass=$(echo -n "$upass" | base64 | tr '+/' '-_' | tr -d '=')
	encoded_remark=$(echo -n "$remark" | base64 | tr '+/' '-_' | tr -d '=')
	encoded_remark_ipv6=$(echo -n "$remark_ipv6" | base64 | tr '+/' '-_' | tr -d '=')
	server_string="${myipname}:${port}:${ux1}:${um1}:${uo1}:${encoded_pass}/?remarks=${encoded_remark}"
	encoded_server=$(echo -n "$server_string" | base64 -w 0 | tr '+/' '-_' | tr -d '=')
	ssr_link="ssr://${encoded_server}"
	host_prefix="${myipname%%.*}"
	if [[ "$myipname" == *.* ]]; then
		ipv6_myipname="${host_prefix}6${myipname#"$host_prefix"}"
	else
		ipv6_myipname="${myipname}6"
	fi
	server_string_ipv6="${ipv6_myipname}:${port}:${ux1}:${um1}:${uo1}:${encoded_pass}/?remarks=${encoded_remark_ipv6}"
	encoded_server_ipv6=$(echo -n "$server_string_ipv6" | base64 -w 0 | tr '+/' '-_' | tr -d '=')
	ssr_link_ipv6="ssr://${encoded_server_ipv6}"

	echo ""
	echo "你可以复制以下信息给你的用户: "
	echo "===================="
	echo "$ssr_link"
	echo "$ssr_link_ipv6"
	echo "IPv6 Host: $ipv6_myipname"
	echo "IPv6备注: $remark_ipv6"
	echo ""
	echo "备注: $remark"
	echo "服务器地址: $myipname"
	echo "远程端口号: $port"
	echo "本地端口号: 1080"
	echo "密码: $upass"
	echo "加密方法: $um1"
	echo "协议: $ux1"
	echo "混淆方式: $uo1"
	echo "===================="
fi

if [[ $ec == 12 ]];then
	if [[ ${lsid} == 1 ]];then
		port=$(python3 mujson_mgr.py -l -u ${uid} | grep "port :" | awk -F" : " '{ print $2 }')
	else
		port=${uid}
	fi
	while :;do
		read -p "请输入新的端口号：" newport
		if [[ "$newport" =~ ^(-?|\+?)[0-9]+(\.?[0-9]+)?$ ]];then
			if [[ ${newport} == ${port} ]];then
				echo -e "新端口号与原端口号一致，无法被更改，退出！\n"
				exit 0
			fi
			if [[ $newport -ge "65535" || $newport -le "1" ]];then
				echo "端口范围取值[1,65535]"
			else
				checkport=$(netstat -anlt | awk '{print $4}' | sed -e '1,2d' | awk -F : '{print $NF}' | sort -n | uniq | grep "$newport")
				if [[ -z ${checkport} ]];then
					break
				else
					echo "端口号已存在，请更换！"
				fi
			fi
		else
			echo "请输入数字！"
		fi
	done
	cd /usr/local/shadowsocksr
	sed -i 's/"port": '"${port}"'/"port": '"${newport}"'/g' mudb.json
	if [[ ${OS} =~ ^Ubuntu$|^Debian$ ]];then
		iptables-restore < /etc/iptables.up.rules
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $newport -j ACCEPT
		iptables -I INPUT -m state --state NEW -m udp -p udp --dport $newport -j ACCEPT
		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport $port -j ACCEPT
		iptables -D INPUT -m state --state NEW -m udp -p udp --dport $port -j ACCEPT
		iptables-save > /etc/iptables.up.rules
	fi

	if [[ ${OS} == CentOS ]];then
		if [[ $CentOS_RHEL_version == 7 ]];then
			iptables-restore < /etc/iptables.up.rules
			iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $newport -j ACCEPT
    		iptables -I INPUT -m state --state NEW -m udp -p udp --dport $newport -j ACCEPT
    		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport $port -j ACCEPT
			iptables -D INPUT -m state --state NEW -m udp -p udp --dport $port -j ACCEPT
			iptables-save > /etc/iptables.up.rules
		else
			iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $newport -j ACCEPT
    		iptables -I INPUT -m state --state NEW -m udp -p udp --dport $newport -j ACCEPT
    		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport $port -j ACCEPT
			iptables -D INPUT -m state --state NEW -m udp -p udp --dport $port -j ACCEPT
			/etc/init.d/iptables save
			/etc/init.d/iptables restart
		fi
	fi
	uid=${newport}
	pqr

	echo -e "端口号修改成功！\n"
	echo "你可以复制以下信息给你的用户: "
	echo "===================="
	echo "SSR链接: $ssr_link"
	echo "SSR IPv6链接: $ssr_link_ipv6"
	echo "IPv6 Host: $ipv6_myipname"
	echo "IPv6备注: $remark_ipv6"
	echo "用户名: $username"
	echo "备注: $remark"
	echo "服务器地址: $myipname"
	echo "远程端口号: $uid"
	echo "本地端口号: 1080"
	echo "密码: $upass"
	echo "加密方法: $um1"
	echo "协议: $ux1"
	echo "混淆方式: $uo1"
	echo "===================="
fi
exit 0
