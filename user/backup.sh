#!/bin/bash
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
    netstat -anlt | awk '{print $4}' | sed -e '1,2d' | awk -F : '{print $NF}' | sort -n | uniq >> ./port.conf
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
