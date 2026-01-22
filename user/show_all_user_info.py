#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json

with open("/usr/local/shadowsocksr/mudb.json", "r", encoding="utf-8") as f:
    data = json.load(f)

print("用户名\t端口\t加密方式\t密码")

for x in data:
    print("%s\t%s\t%s\t%s" % (x["user"], x["port"], x["method"], x["passwd"]))
