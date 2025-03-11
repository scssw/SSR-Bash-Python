#!/bin/bash
#Set PATH
export PATH="/usr/local/bin:$PATH"

#Check Root
[ $(id -u) != "0" ] && { echo "错误: 必须使用root用户运行此脚本"; exit 1; }

#Check OS
if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ];then
    OS=CentOS
    [ -n "$(grep ' 7\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
    [ -n "$(grep ' 6\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && CentOS_RHEL_version=6
elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" -o -e /etc/system-release ];then
    OS=CentOS
    CentOS_RHEL_version=6
elif [ -n "$(grep bian /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Debian' ];then
    OS=Debian
    Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Ubuntu /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Ubuntu' -o -n "$(grep 'Linux Mint' /etc/issue)" ];then
    OS=Ubuntu
    Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
else
    echo "不支持此操作系统，请联系作者!"
    exit 1
fi

# 安装基础工具函数
install_base_tools() {
    echo "正在安装基础工具..."
    if [[ ${OS} == Ubuntu ]];then
        apt-get update -y > /dev/null 2>&1
        DEBIAN_FRONTEND=noninteractive apt-get install -y python python-pip git language-pack-zh-hans vnstat bc net-tools build-essential screen curl cron > /dev/null 2>&1
    elif [[ ${OS} == CentOS ]];then
        yum -y install epel-release > /dev/null 2>&1
        yum -y install python screen curl python-setuptools git bc vnstat net-tools "Development Tools" vixie-cron crontabs > /dev/null 2>&1
        easy_install pip > /dev/null 2>&1
    elif [[ ${OS} == Debian ]];then
        apt-get update -y > /dev/null 2>&1
        DEBIAN_FRONTEND=noninteractive apt-get install -y python python-pip git net-tools bc vnstat build-essential screen curl cron iptables > /dev/null 2>&1
        
        # 特别处理 Debian 11
        if [[ ${Debian_version} -ge 11 ]];then
            apt-get install -y iptables-persistent > /dev/null 2>&1
        fi
    fi
}

# 安装 libsodium
install_libsodium() {
    if [[ ! -e /usr/local/lib/libsodium.so && ! -e /usr/lib/libsodium.so ]];then
        echo "正在安装 libsodium..."
        export LIBSODIUM_VER=1.0.18
        wget -q https://github.com/jedisct1/libsodium/releases/download/${LIBSODIUM_VER}/libsodium-$LIBSODIUM_VER.tar.gz
        tar xf libsodium-$LIBSODIUM_VER.tar.gz
        cd libsodium-$LIBSODIUM_VER
        ./configure --prefix=/usr > /dev/null 2>&1 && make -j$(nproc) > /dev/null 2>&1 && make install > /dev/null 2>&1
        cd .. && rm -rf libsodium-$LIBSODIUM_VER*
        ldconfig
    fi
}

# 安装 SSR
install_ssr() {
    echo "正在安装 SSR..."
    cd /usr/local
    if [ ! -d shadowsocksr ]; then
        git clone https://github.com/scssw/shadowsocksr > /dev/null 2>&1
        cd shadowsocksr
        git checkout manyuser > /dev/null 2>&1
        git pull > /dev/null 2>&1
    fi
}

# 安装 SSR-Bash
install_ssr_bash() {
    echo "正在安装 SSR-Bash..."
    cd /usr/local
    if [ ! -d SSR-Bash-Python ]; then
        git clone https://github.com/scssw/SSR-Bash-Python.git > /dev/null 2>&1
        cd SSR-Bash-Python
        git checkout master > /dev/null 2>&1
    fi
}

# 配置防火墙
setup_firewall() {
    if [[ ${OS} == CentOS && ${CentOS_RHEL_version} == 7 ]];then
        systemctl stop firewalld.service
        yum install iptables-services -y > /dev/null 2>&1
        systemctl enable iptables.service
        systemctl disable firewalld.service
    fi
    
    if [[ ${OS} == Debian && ${Debian_version} -ge 11 ]];then
        if ! command -v iptables &> /dev/null; then
            apt-get install -y iptables iptables-persistent > /dev/null 2>&1
        fi
    fi
}

# 主安装流程
main_install() {
    trap 'echo -e "\n安装被中断，清理文件..."; exit 1' 2
    
    # 1. 安装基础工具
    install_base_tools
    
    # 2. 安装 libsodium
    install_libsodium
    
    # 3. 安装 SSR
    install_ssr
    
    # 4. 安装 SSR-Bash
    install_ssr_bash
    
    # 5. 配置防火墙
    setup_firewall
    
    # 6. 配置自动启动
    if [[ ${OS} == Ubuntu || ${OS} == Debian ]];then
        cat > /etc/init.d/ssr-bash-python << EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:          SSR-Bash_python
# Required-Start:    \$local_fs \$remote_fs
# Required-Stop:     \$local_fs \$remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: SSR-Bash-Python
### END INIT INFO
iptables-restore < /etc/iptables.up.rules
bash /usr/local/shadowsocksr/logrun.sh
EOF
        chmod 755 /etc/init.d/ssr-bash-python
        update-rc.d ssr-bash-python defaults
    fi
    
    # 7. 配置定时任务
    (crontab -l 2>/dev/null; echo "0 */6 * * * systemctl restart ssr-bash-python.service") | crontab -
    (crontab -l 2>/dev/null; echo "0 */1 * * * /bin/bash /usr/local/SSR-Bash-Python/user/backup.sh") | crontab -
    (crontab -l 2>/dev/null; echo "*/6 * * * * /bin/bash /usr/local/SSR-Bash-Python/timelimit.sh c > /dev/null 2>&1") | crontab -
    
    # 8. 完成安装
    bash /usr/local/SSR-Bash-Python/self-check.sh
    echo '安装完成！输入 ssr 即可使用本程序'
}

# 执行安装
main_install

