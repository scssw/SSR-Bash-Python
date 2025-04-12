#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# 检查是否为root用户
[ $(id -u) != "0" ] && { echo "错误：必须使用root权限运行此脚本"; exit 1; }

# 显示菜单
echo "快速添加SSR用户"
echo "================="
echo "1. 月"
echo "2. 季度"
echo "3. 半年"
echo "6. 年"
echo "================="

# 读取用户输入
read -p "请选择套餐编号: " choice

# 根据选择设置流量和有效期
case $choice in
    1)
        ut=50
        limit="1m"
        ;;
    2)
        ut=150
        limit="3m"
        ;;
    3)
        ut=300
        limit="6m"
        ;;
    6)
        ut=600
        limit="12m"
        ;;
    *)
        echo "无效的选择！"
        exit 1
        ;;
esac

# 调用easyadd.sh并传入参数
bash /usr/local/SSR-Bash-Python/user/easyadd.sh $ut $limit 