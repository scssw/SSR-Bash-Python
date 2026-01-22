#!/usr/bin/python3
# -*- coding: utf-8 -*-
import json
import sys

def set_speed_limit(speed_limit_kbps):
    config_file = '/usr/local/shadowsocksr/mudb.json'
    
    try:
        with open(config_file, 'r') as f:
            data = json.load(f)
            
        for user in data:
            user['speed_limit_per_user'] = int(speed_limit_kbps)
            
        with open(config_file, 'w') as f:
            json.dump(data, f, indent=4)
            
        return True
    except Exception as e:
        print("设置限速时发生错误：", str(e))
        return False

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("使用方法: python3 speed.py <速度限制(KBps)>")
        sys.exit(1)
        
    try:
        speed_limit = int(sys.argv[1])
        if set_speed_limit(speed_limit):
            sys.exit(0)
        else:
            sys.exit(1)
    except ValueError:
        print("速度限制必须是一个整数")
        sys.exit(1) 
