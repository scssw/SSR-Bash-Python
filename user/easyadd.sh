#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Check OS
if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ];then
  OS=CentOS
  [ -n "$(grep ' 7\\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
  [ -n "$(grep ' 6\\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && CentOS_RHEL_version=6
  [ -n "$(grep ' 5\\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && CentOS_RHEL_version=5
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

# Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

rand(){  
    min=$1  
    max=$(($2-$min+1))  
    num=$(cat /dev/urandom | head -n 10 | cksum | awk -F ' ' '{print $1}')  
    echo $(($num%$max+$min))  
}

source /usr/local/SSR-Bash-Python/easyadd.conf

# 自动生成用户名和密码
uname=$(date +%Y%m%d%H%M)
upass=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)

echo "自动添加用户，用户名: $uname, 密码: $upass"

# 从端口段配置文件中随机选择一个可用端口
while :; do
  if [[ ! -f /usr/local/SSR-Bash-Python/port_ranges.conf ]] || [[ ! -s /usr/local/SSR-Bash-Python/port_ranges.conf ]]; then
    # 如果没有配置端口段，使用默认范围
    uport=$(rand 1000 65535)
  else
    # 随机选择一个端口段
    port_range=$(grep -v '^#' /usr/local/SSR-Bash-Python/port_ranges.conf | shuf -n 1)
    start_port=$(echo $port_range | cut -d'-' -f1)
    end_port=$(echo $port_range | cut -d'-' -f2)
    uport=$(rand $start_port $end_port)
  fi
  # 检查端口是否已被使用
  port=`ss -ntl | awk '{print $4}' | awk -F : '{print $NF}' | sort -nu | grep "$uport"`
  if [[ -z ${port} ]]; then
    break
  fi
done

while :; do echo
  read -p "输入流量限制(只需输入数字，单位：GB)： " ut
  if [[ "$ut" =~ ^(-?|\+?)[0-9]+(\.?[0-9]+)?$ ]];then
     break
  else
     echo 'Input Error!'
  fi
done

# 询问是否需要设置帐号有效期
iflimittime="y"
echo "是否需要限制帐号有效期(y/n) [默认: y]: y"

if [[ ${iflimittime} == y ]]; then
    read -p "请输入有效期(格式：年.月.日如25.5.12表示2025年5月12日，或月[m]日[d]小时[h]如1m表示1个月){默认：一个月}: " limit
    if [[ -z ${limit} ]]; then
        limit="1m"
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
        echo "${uport}:${full_year}${month}${day}${current_hour}${current_min}" > /tmp/tempdate.txt
        sed -i "/^${uport}:/d" /usr/local/SSR-Bash-Python/timelimit.db
        cat /tmp/tempdate.txt >> /usr/local/SSR-Bash-Python/timelimit.db
        rm -f /tmp/tempdate.txt
        limit="setok" # 标记已设置，避免再次调用timelimit.sh
    fi
    
    # 只有在未直接设置日期时才调用timelimit.sh
    if [[ $limit != "setok" ]]; then
        bash /usr/local/SSR-Bash-Python/timelimit.sh a ${uport} ${limit}
    fi
    
    datelimit=$(cat /usr/local/SSR-Bash-Python/timelimit.db | grep "${uport}:" | awk -F":" '{ print $2 }' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1年\2月\3日 \4:/')
fi

if [[ -z ${datelimit} ]]; then
    datelimit="永久"
fi

if [[ ${OS} =~ ^Ubuntu$|^Debian$ ]];then
  iptables-restore < /etc/iptables.up.rules
  clear
  iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $uport -j ACCEPT
  iptables -I INPUT -m state --state NEW -m udp -p udp --dport $uport -j ACCEPT
  iptables-save > /etc/iptables.up.rules
fi

if [[ ${OS} == CentOS ]];then
  if [[ $CentOS_RHEL_version == 7 ]];then
    iptables-restore < /etc/iptables.up.rules
    iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $uport -j ACCEPT
    iptables -I INPUT -m state --state NEW -m udp -p udp --dport $uport -j ACCEPT
    iptables-save > /etc/iptables.up.rules
  else
    iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $uport -j ACCEPT
    iptables -I INPUT -m state --state NEW -m udp -p udp --dport $uport -j ACCEPT
    /etc/init.d/iptables save
    /etc/init.d/iptables restart
  fi
fi

# Run ShadowsocksR
echo "用户添加成功！用户信息如下："
cd /usr/local/shadowsocksr

# 检查 Python 版本并使用合适的命令
if command -v python &>/dev/null; then
    PYTHON_CMD="python"
elif command -v python2 &>/dev/null; then
    PYTHON_CMD="python2"
elif command -v python3 &>/dev/null; then
    PYTHON_CMD="python3"
else
    echo "错误：未找到 Python 命令"
    exit 1
fi

if [[ $iflimitspeed == y ]]; then
  $PYTHON_CMD mujson_mgr.py -a -u $uname -p $uport -k $upass -m $um1 -O $ux1 -o $uo1 -t $ut -S $us
else
  $PYTHON_CMD mujson_mgr.py -a -u $uname -p $uport -k $upass -m $um1 -O $ux1 -o $uo1 -t $ut
fi

SSRPID=$(ps -ef | grep 'server.py m' | grep -v grep | awk '{print $2}')
if [[ $SSRPID == "" ]]; then
  if [[ ${OS} =~ ^Ubuntu$|^Debian$ ]];then
    iptables-restore < /etc/iptables.up.rules
  fi
  bash /usr/local/shadowsocksr/logrun.sh
  echo "ShadowsocksR服务器已启动"
fi

myipname=`cat /usr/local/shadowsocksr/myip.txt`

# 生成备注信息
# 从域名中提取前缀并转换为大写
prefix=$(echo $myipname | awk -F'.' '{print $1}' | tr '[:lower:]' '[:upper:]')

# 从timelimit.db中提取到期时间并格式化
expire_date=$(cat /usr/local/SSR-Bash-Python/timelimit.db | grep "${uport}:" | awk -F":" '{print $2}' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\2.\3/' | sed 's/^0//' | sed 's/\.0/./')

# 组合备注
remark="${prefix}:${uport}-${expire_date}"

# 生成带备注的加密SSR链接
# 修复密码编码逻辑（原始密码只需base64编码一次）
raw_pass_base64=$(echo -n "$upass" | base64 -w 0)
encoded_remark=$(echo -n "$remark" | base64 -w 0 | tr '+/' '-_' | tr -d '=')
server_string="${myipname}:${uport}:${ux1}:${um1}:${uo1}:${raw_pass_base64}/?remarks=${encoded_remark}"

# 生成最终SSR链接（整个字符串做一次URL安全base64编码）
encoded_server=$(echo -n "$server_string" | base64 -w 0 | tr '+/' '-_' | tr -d '=')
ssr_link="ssr://${encoded_server}"

echo "你可以复制以下信息给你的用户: "
echo -e "\e[1;36m====================\e[0m"
echo -e "\033[1;32m$ssr_link\033[0m"  # 修改此处行号
echo ""
echo "用户名: $uname"
echo "备注: $remark"
echo "服务器地址: $myipname"
echo "远程端口号: $uport"
echo "本地端口号: 1080"
echo "密码: $upass"
echo "加密方法: $um1"
echo "协议: $ux1"
echo "混淆方式: $uo1"
echo "流量: $ut GB"
echo "允许连接数: 不限"
echo "帐号有效期: $datelimit"
echo "===================="
