#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

# 显示菜单
show_menu() {
    clear
    echo "========== SSR 流控管理 =========="
    echo "1.设置流量超额限速"
    echo "2.取消流控限制"
    echo "3.手动执行流量监控"
    echo "4.查看流控日志"
    echo "5.查看限速端口"
    echo "0.返回主菜单"
    echo "=================================="
}

# 设置流量超额限速
set_traffic_limit() {
    read -p "请输入流量阈值(单位：MB)：" traffic_limit
    if [[ ! $traffic_limit =~ ^[0-9]+$ ]]; then
        echo "输入错误！请输入数字！"
        return
    fi

    echo "检测到新的流控阈值，先重置旧的流控限制和流量记录..."
    cancel_traffic_limit >/dev/null 2>&1
    echo "{}" > /usr/local/SSR-Bash-Python/traffic_record.json
    echo "{}" > /usr/local/SSR-Bash-Python/limit_record.json
    echo "已重建 traffic_record.json 和 limit_record.json"
    
    # 创建流量监控脚本
    cat > /usr/local/SSR-Bash-Python/traffic_monitor.sh << EOF
#!/bin/bash
# 获取当日流量函数
get_daily_traffic() {
    local port=\$1
    # 从mudb.json获取端口流量
    python3 -c "
import json
import time
import os

# 流量记录文件路径
TRAFFIC_RECORD = '/usr/local/SSR-Bash-Python/traffic_record.json'
# 限速记录文件路径
LIMIT_RECORD = '/usr/local/SSR-Bash-Python/limit_record.json'
# 获取当前日期
current_date = time.strftime('%Y-%m-%d')

# 读取流量记录
if os.path.exists(TRAFFIC_RECORD):
    with open(TRAFFIC_RECORD, 'r') as f:
        traffic_record = json.load(f)
else:
    traffic_record = {}

# 读取限速记录
if os.path.exists(LIMIT_RECORD):
    with open(LIMIT_RECORD, 'r') as f:
        limit_record = json.load(f)
else:
    limit_record = {}

# 读取mudb.json
with open('/usr/local/shadowsocksr/mudb.json', 'r') as f:
    data = json.load(f)

# 查找端口
for user in data:
    if user['port'] == \$port:
        # 获取当前总流量
        current_total = user['u'] + user['d']
        
        # 如果是新的一天，重置记录
        if current_date not in traffic_record:
            traffic_record[current_date] = {}
        
        # 获取该端口当天的起始流量
        if str(\$port) not in traffic_record[current_date]:
            traffic_record[current_date][str(\$port)] = current_total
            daily_traffic = 0
        else:
            # 计算当日流量（转换为MB）
            daily_traffic = (current_total - traffic_record[current_date][str(\$port)]) / (1024 * 1024)
        
        # 保存记录
        with open(TRAFFIC_RECORD, 'w') as f:
            json.dump(traffic_record, f, indent=4)
        
        print('{:.2f}'.format(daily_traffic))  # 输出两位小数的MB值
        break
"
}

# 修改端口限速函数
limit_port_speed() {
    local port=\$1
    local speed=\$2
    echo "正在修改端口 \$port 的限速为 \$speed..."
    # 使用python修改mudb.json
    python3 -c "
import json
import time
import os

# 限速记录文件路径
LIMIT_RECORD = '/usr/local/SSR-Bash-Python/limit_record.json'
# 获取当前时间戳
current_time = time.time()

# 读取限速记录
if os.path.exists(LIMIT_RECORD):
    with open(LIMIT_RECORD, 'r') as f:
        limit_record = json.load(f)
else:
    limit_record = {}

# 读取mudb.json
with open('/usr/local/shadowsocksr/mudb.json', 'r') as f:
    data = json.load(f)

# 查找端口
for user in data:
    if user['port'] == \$port:
        # 设置限速
        user['speed_limit_per_user'] = \$speed
        # 记录限速时间
        limit_record[str(\$port)] = current_time
        # 保存记录
        with open(LIMIT_RECORD, 'w') as f:
            json.dump(limit_record, f, indent=4)
with open('/usr/local/shadowsocksr/mudb.json', 'w') as f:
    json.dump(data, f, indent=4)
" > /dev/null 2>&1

    # 设置自动恢复速度
    (
        sleep 86400  # 24小时
        echo "24小时到，开始恢复端口 \$port 的速度..."
        restore_port_speed \$port
        echo "\$(date '+%Y-%m-%d %H:%M:%S') - 端口 \$port 已恢复正常速度"
    ) &
}

# 恢复端口速度函数（用于每日0点重置）
restore_port_speed() {
    local port=\$1
    echo "正在恢复端口 \$port 的速度..."
    python3 -c "
import json
with open('/usr/local/shadowsocksr/mudb.json', 'r') as f:
    data = json.load(f)
for user in data:
    if user['port'] == \$port:
        user['speed_limit_per_user'] = 6200
with open('/usr/local/shadowsocksr/mudb.json', 'w') as f:
    json.dump(data, f, indent=4)
" > /dev/null 2>&1
}

# 检查是否需要限速
check_limit_needed() {
    local port=\$1
    python3 -c "
import json
import time
import os

# 限速记录文件路径
LIMIT_RECORD = '/usr/local/SSR-Bash-Python/limit_record.json'
# 24小时的时间戳
day_in_seconds = 24 * 60 * 60
current_time = time.time()

# 读取限速记录
if os.path.exists(LIMIT_RECORD):
    with open(LIMIT_RECORD, 'r') as f:
        limit_record = json.load(f)
    # 检查是否在24小时内限速过
    if str(\$port) in limit_record:
        last_limit_time = limit_record[str(\$port)]
        if current_time - last_limit_time < day_in_seconds:
            print('no')
            exit(0)
print('yes')
"
}

# 主循环
is_manual=\$1

while true; do
    # 获取所有端口
    ports=\$(ss -nlt | awk '/LISTEN/{print \$4}' | awk -F: '{print \$NF}' | sort -nu)
    for port in \$ports; do
        echo "检查端口 \$port..."
        # 获取端口当日流量
        traffic_mb=\$(get_daily_traffic \$port)
        if [[ -n "\$traffic_mb" ]]; then
            echo "端口 \$port 当日流量: \$traffic_mb MB"
            
            # 比较流量（使用bc进行浮点数比较）
            if (( \$(echo "\$traffic_mb > $traffic_limit" | bc -l) )); then
                # 检查是否需要限速
                need_limit=\$(check_limit_needed \$port)
                if [[ "\$need_limit" == "yes" ]]; then
                    echo "端口 \$port 当日流量(\$traffic_mb MB)超过阈值($traffic_limit MB)，开始限速..."
                    # 设置限速
                    limit_port_speed \$port 2000
                    echo "\$(date '+%Y-%m-%d %H:%M:%S') - 端口 \$port 已限速，24小时后自动恢复"
                else
                    echo "端口 \$port 在24小时内已被限速过，跳过限速"
                fi
            fi
        else
            echo "端口 \$port 未找到流量数据"
        fi
    done
    
    # 如果是手动执行，询问是否继续
    if [[ "\$is_manual" == "manual" ]]; then
        echo -n "按q退出，其他键继续: "
        read -n 1 input
        if [[ "\$input" == "q" ]]; then
            echo "退出监控"
            exit 0
        fi
    else
        sleep 10800  # 每3h检查一次
    fi
done
EOF
    chmod +x /usr/local/SSR-Bash-Python/traffic_monitor.sh
    
    # 设置开机自启动
    if [ -d "/etc/systemd/system" ]; then
        cat > /etc/systemd/system/traffic-monitor.service << EOF
[Unit]
Description=Traffic Monitor Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/SSR-Bash-Python/traffic_monitor.sh
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=traffic-monitor

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable traffic-monitor.service
        systemctl restart traffic-monitor.service
        echo "已成功设置流量监控，当日流量超过${traffic_limit}MB的端口将被限速20Mbps"
    else
        # 使用crontab
        (crontab -l 2>/dev/null; echo "@reboot /usr/local/SSR-Bash-Python/traffic_monitor.sh") | crontab -
        # 创建日志目录
        mkdir -p /var/log/traffic-monitor
        # 启动监控脚本并记录日志
        nohup /usr/local/SSR-Bash-Python/traffic_monitor.sh > /var/log/traffic-monitor/monitor.log 2>&1 &
        echo "已成功设置流量监控，当日流量超过${traffic_limit}MB的端口将被限速20Mbps"
        echo "监控日志保存在 /var/log/traffic-monitor/monitor.log"
    fi
}

# 取消流控限制
cancel_traffic_limit() {
    # 停止流量监控服务
    if [ -d "/etc/systemd/system" ]; then
        systemctl stop traffic-monitor.service
        systemctl disable traffic-monitor.service
        rm -f /etc/systemd/system/traffic-monitor.service
    fi
    
    # 删除crontab中的任务
    crontab -l | grep -v "traffic_monitor.sh" | crontab -
    
    # 只恢复limit_record.json中的端口速度
    if [ -f "/usr/local/SSR-Bash-Python/limit_record.json" ]; then
        python3 -c "
import json

# 读取限速记录
try:
    with open('/usr/local/SSR-Bash-Python/limit_record.json', 'r') as f:
        limit_record = json.load(f)
    
    # 读取mudb.json
    with open('/usr/local/shadowsocksr/mudb.json', 'r') as f:
        data = json.load(f)
    
    # 只重置被限速的端口
    limited_ports = []
    for port_str in limit_record.keys():
        port = int(port_str)
        limited_ports.append(port)
        for user in data:
            if user['port'] == port:
                user['speed_limit_per_user'] = 6200
                print('端口 {} 已重置速度为默认值'.format(port))
    
    # 保存修改后的配置
    with open('/usr/local/shadowsocksr/mudb.json', 'w') as f:
        json.dump(data, f, indent=4)
    
    # 清空限速记录
    with open('/usr/local/SSR-Bash-Python/limit_record.json', 'w') as f:
        json.dump({}, f)
        
    if not limited_ports:
        print('没有发现被限速的端口')
    
except Exception as e:
    print('处理限速记录时出错: {}'.format(e))
"
    else
        echo "没有找到限速记录文件，无需重置"
    fi
    
    # 删除流量记录和限速记录文件
    if [ -f "/usr/local/SSR-Bash-Python/limit_record.json" ]; then
        rm -f /usr/local/SSR-Bash-Python/limit_record.json
        echo "已删除限速记录文件"
    fi
    
    if [ -f "/usr/local/SSR-Bash-Python/traffic_record.json" ]; then
        rm -f /usr/local/SSR-Bash-Python/traffic_record.json
        echo "已删除流量记录文件"
    fi
    
    # 清理进程
    pkill -f traffic_monitor.sh
    echo "已取消流控限制，被限速的端口已恢复默认速度"
}

# 手动执行流量监控
manual_traffic_monitor() {
    echo "开始手动执行流量监控..."
    bash /usr/local/SSR-Bash-Python/traffic_monitor.sh manual
}

# 查看流控日志
view_traffic_logs() {
    echo "查看流控日志："
    if [ -d "/etc/systemd/system" ] && [ -f "/etc/systemd/system/traffic-monitor.service" ]; then
        echo "按Ctrl+C退出日志查看"
        sleep 2
        journalctl -u traffic-monitor.service -f
    elif [ -f "/var/log/traffic-monitor/monitor.log" ]; then
        echo "按Ctrl+C退出日志查看"
        sleep 2
        tail -f /var/log/traffic-monitor/monitor.log
    else
        echo "未找到日志文件，请先设置流量超额限速"
    fi
}

# 查看限速端口
view_limited_ports() {
    if [ -f "/usr/local/SSR-Bash-Python/limit_record.json" ]; then
        python3 -c "
import json
import time
import math
import os

try:
    # 确保限速记录文件存在且格式正确
    limit_record = {}
    try:
        if os.path.exists('/usr/local/SSR-Bash-Python/limit_record.json') and os.path.getsize('/usr/local/SSR-Bash-Python/limit_record.json') > 0:
            with open('/usr/local/SSR-Bash-Python/limit_record.json', 'r') as f:
                content = f.read().strip()
                if content:  # 确保文件不为空
                    limit_record = json.loads(content)
    except ValueError:
        # 如果JSON解析失败，创建一个新的空记录
        limit_record = {}
        # 重写文件，确保格式正确
        with open('/usr/local/SSR-Bash-Python/limit_record.json', 'w') as f:
            json.dump(limit_record, f)
    
    # 读取mudb.json获取速率信息
    data = []
    try:
        if os.path.exists('/usr/local/shadowsocksr/mudb.json'):
            with open('/usr/local/shadowsocksr/mudb.json', 'r') as f:
                data = json.load(f)
    except ValueError:
        print('错误: mudb.json格式不正确')
        data = []
        
    # 获取当前时间
    current_time = time.time()
    
    # 创建端口信息映射
    port_speed_map = {}
    for user in data:
        # 安全地获取speed_limit_per_user字段，如果不存在则使用'未设置'
        if 'port' in user:
            port_speed_map[user['port']] = user.get('speed_limit_per_user', '未设置')
    
    # 过滤已过期的限速记录（超过24小时的）
    expired_ports = []
    for port_str, start_time in list(limit_record.items()):
        try:
            elapsed_seconds = current_time - float(start_time)
            if elapsed_seconds >= 24 * 3600:  # 已过24小时
                expired_ports.append(port_str)
                del limit_record[port_str]
        except (ValueError, TypeError):
            pass
    
    # 如果有过期端口，更新限速记录文件
    if expired_ports:
        print('以下端口已超过24小时限速期，已自动移除：{}'.format(', '.join(expired_ports)))
        with open('/usr/local/SSR-Bash-Python/limit_record.json', 'w') as f:
            json.dump(limit_record, f, indent=4)
    
    # 打印表头
    print('================================================================================')
    print('| {:<10}   | {:<20}       | {:<15} | {:<20} |'.format('端口 ', '限速开始时间', '当前速率 (Kbps)', '剩余时间'))
    print('================================================================================')
    
    # 如果没有限速记录
    if not limit_record:
        print('| {:<74} |'.format('当前没有被限速的端口'))
        print('================================================================================')
    else:
        # 遍历所有限速端口
        for port_str, start_time in limit_record.items():
            try:
                port = int(port_str)
                
                # 格式化开始时间
                time_str = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(float(start_time)))
                
                # 计算剩余时间（24小时后自动恢复）
                elapsed_seconds = current_time - float(start_time)
                remaining_seconds = 24 * 3600 - elapsed_seconds
                
                if remaining_seconds <= 0:
                    remaining = '即将自动恢复'  # 这种情况不应该再发生，因为已经过滤了过期记录
                else:
                    hours = int(remaining_seconds // 3600)
                    minutes = int((remaining_seconds % 3600) // 60)
                    remaining = '{}小时{}分钟'.format(hours, minutes)
                
                # 获取当前速率，确保键存在
                speed = port_speed_map.get(port, '未知')
                
                # 打印一行数据
                print('| {:<10} | {:<20} | {:<15} | {:<20} |'.format(port, time_str, speed, remaining))
            except (ValueError, TypeError) as e:
                print('| {:<10} | {:<20} | {:<15} | {:<20} |'.format(port_str, '数据格式错误', '未知', '未知'))
        
        print('================================================================================')
    
except Exception as e:
    print('处理限速记录时出错: {}'.format(e))
    import traceback
    traceback.print_exc()
"
    else
        echo "没有找到限速记录文件，目前没有被限速的端口"
        # 创建空的限速记录文件
        echo "{}" > /usr/local/SSR-Bash-Python/limit_record.json
        echo "已创建空的限速记录文件"
    fi
}

# 主程序
while true; do
    show_menu
    read -p "请选择选项 [0-5]: " option
    case $option in
        0)
            echo "返回主菜单..."
            bash /usr/local/SSR-Bash-Python/self.sh
            exit 0
            ;;
        1)
            set_traffic_limit
            ;;
        2)
            cancel_traffic_limit
            ;;
        3)
            manual_traffic_monitor
            ;;
        4)
            view_traffic_logs
            ;;
        5)
            view_limited_ports
            ;;
        *)
            echo "无效选项！请重新选择"
            bash /usr/local/SSR-Bash-Python/self.sh
            ;;
    esac
    echo ""
    read -n 1 -p "按任意键继续..." any_key
done 
