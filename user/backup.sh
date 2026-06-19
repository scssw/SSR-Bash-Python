#!/bin/bash
backup(){
    echo "开始备份!"
    mkdir -p ${HOME}/backup/tmp
    cd ${HOME}/backup/tmp
    rm -f ./port.conf
    cp /usr/local/shadowsocksr/mudb.json ./
    if [[ -e /usr/local/SSR-Bash-Python/check.log ]];then
        cp /usr/local/SSR-Bash-Python/check.log ./
    fi
    if [[ -e /usr/local/SSR-Bash-Python/timelimit.db ]];then
        cp /usr/local/SSR-Bash-Python/timelimit.db ./
    fi
    if command -v python3 >/dev/null 2>&1;then
        python3 - <<'PY' >> ./port.conf
import json

with open('/usr/local/shadowsocksr/mudb.json') as f:
    for user in json.load(f):
        port = user.get('port')
        if isinstance(port, int) and 1 <= port <= 65535:
            print(port)
PY
    elif command -v python >/dev/null 2>&1;then
        python - <<'PY' >> ./port.conf
import json

with open('/usr/local/shadowsocksr/mudb.json') as f:
    for user in json.load(f):
        port = user.get('port')
        if isinstance(port, int) and 1 <= port <= 65535:
            print(port)
PY
    fi
    if command -v ss >/dev/null 2>&1;then
        ss -nlt 2>/dev/null | awk '/LISTEN/{print $4}' | awk -F: '{print $NF}' >> ./port.conf
    elif command -v netstat >/dev/null 2>&1;then
        netstat -anlt 2>/dev/null | awk '{print $4}' | sed -e '1,2d' | awk -F : '{print $NF}' >> ./port.conf
    fi
    awk '/^[0-9]+$/ && $1 >= 1 && $1 <= 65535' ./port.conf | sort -n | uniq > ./port.conf.tmp
    mv ./port.conf.tmp ./port.conf
    wf=`ls | wc -l`
    if [[ $wf -ge 2 ]];then
        tar -zcvf ../ssr-conf.tar.gz ./*
    fi
    cd ..
    if [[ -e ./ssr-conf.tar.gz ]];then
        rm -rf ./tmp
        echo "备份成功,文件位于${HOME}/backup/ssr-conf.tar.gz"
    else
		cd ${HOME}/backup
		mv ./ssr-conf.tar.gz ./ssr-conf-`date +%Y-%m-%d_%H:%M:%S`.tar.gz
		backup
    fi
}

# 调用备份函数
backup
