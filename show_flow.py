#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json

with open("/usr/local/shadowsocksr/mudb.json", "r", encoding="utf-8") as f:
    data = json.load(f)

print("用户名\t端口\t已用流量\t流量限制")

for x in data:
    # Convert Unit To MB
    transfer_enable_int = int(x["transfer_enable"]) // 1024 // 1024
    d_int = int(x["d"]) // 1024 // 1024
    transfer_unit = "MB"
    d_unit = "MB"

    # Convert Unit To GB For Those Number Which Exceeds 1024MB
    if transfer_enable_int > 1024:
        transfer_enable_int = transfer_enable_int // 1024
        transfer_unit = "GB"
    if d_int > 1024:
        d_int = d_int // 1024
        d_unit = "GB"

    # Print In Format
    print("%s\t%s\t%d%s\t\t%d%s" % (
        x["user"], x["port"], d_int, d_unit, transfer_enable_int, transfer_unit
    ))
