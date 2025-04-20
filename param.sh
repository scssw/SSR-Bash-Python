#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# 检查Root权限
[ $(id -u) != "0" ] && { echo "错误: 必须使用root用户运行此脚本"; exit 1; }

# 数据库文件路径
DB_FILE="/usr/local/shadowsocksr/mudb.json"

# 检查数据库文件是否存在
if [ ! -f "$DB_FILE" ]; then
    echo "错误: 数据库文件不存在: $DB_FILE"
    exit 1
fi

# 备份原始数据库文件
cp "$DB_FILE" "${DB_FILE}.bak.$(date +%Y%m%d%H%M%S)"
echo "已备份原始数据库文件"

# 读取当前用户连接数设置
CURRENT_CONN=$(grep -o '"protocol_param": "[0-9]*"' "$DB_FILE" | head -n 1 | grep -o '[0-9]*')
if [ -z "$CURRENT_CONN" ]; then
    CURRENT_CONN="未设置"
fi
echo "当前连接数限制: $CURRENT_CONN"

# 提示用户输入新的连接数
echo "=========================="
echo "请输入新的连接数限制 (按回车退出):"
read new_conn

# 如果用户直接按回车，退出脚本
if [ -z "$new_conn" ]; then
    echo "未进行任何修改，退出脚本"
    exit 0
fi

# 验证输入是否为数字
if ! [[ "$new_conn" =~ ^[0-9]+$ ]]; then
    echo "错误: 请输入有效的数字"
    exit 1
fi

echo "正在修改所有用户的连接数限制为: $new_conn"

# 使用临时文件处理
TEMP_FILE=$(mktemp)
cat "$DB_FILE" > "$TEMP_FILE"

# 使用jq命令处理JSON文件 (如果可用)
if command -v jq &>/dev/null; then
    jq --argjson conn "\"$new_conn\"" '
    map(if has("protocol_param") then
        .protocol_param = $conn
    else
        . + {protocol_param: $conn}
    end)
    ' "$DB_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$DB_FILE"
else
    # 如果jq不可用，使用替代方法
    # 这是一个简化的方法，可能在复杂JSON结构中不够可靠
    # 检查是否有protocol_param字段
    if grep -q '"protocol_param": "[0-9]*"' "$DB_FILE"; then
        # 替换所有protocol_param的值
        sed -i 's/"protocol_param": "[0-9]*"/"protocol_param": "'$new_conn'"/g' "$DB_FILE"
        echo "已更新所有现有的protocol_param字段"
    else
        # 需要为每个用户添加protocol_param字段
        # 这种方法比较复杂，我们寻找每个用户记录的末尾并添加字段
        # 注意：这种基于sed的方法可能不适用于所有JSON结构
        cp "$DB_FILE" "$TEMP_FILE"
        # 在每个用户记录中的protocol字段后添加protocol_param字段
        sed -i 's/"protocol": "[^"]*"/"protocol": "&",\n        "protocol_param": "'$new_conn'"/g' "$TEMP_FILE"
        
        # 检查修改是否成功，如果文件看起来仍然是有效的JSON，则覆盖原始文件
        if grep -q '^[[:space:]]*\[' "$TEMP_FILE" && grep -q '\][[:space:]]*$' "$TEMP_FILE"; then
            mv "$TEMP_FILE" "$DB_FILE"
            echo "已为所有用户添加protocol_param字段"
        else
            echo "警告: 自动修改失败，请手动编辑文件添加protocol_param字段"
            echo "临时文件保存在: $TEMP_FILE"
            exit 1
        fi
    fi
fi

echo "============================="
echo "修改完成！所有用户的连接数已设置为: $new_conn"
echo "============================="
