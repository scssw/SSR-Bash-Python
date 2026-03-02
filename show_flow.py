# -*- coding: utf-8 -*-
from __future__ import print_function

import io
import json


with io.open("/usr/local/shadowsocksr/mudb.json", "r", encoding="utf-8") as f:
    users = json.load(f)

print("用户名\t端口\t已用流量\t流量限制")

for item in users:
    transfer_enable_int = int(item[u"transfer_enable"]) // 1024 // 1024
    d_int = int(item[u"d"]) // 1024 // 1024
    transfer_unit = "MB"
    d_unit = "MB"

    if transfer_enable_int > 1024:
        transfer_enable_int = transfer_enable_int // 1024
        transfer_unit = "GB"
    if d_int > 1024:
        d_int = d_int // 1024
        d_unit = "GB"

    print("%s\t%s\t%d%s\t\t%d%s" % (
        item[u"user"],
        item[u"port"],
        d_int,
        d_unit,
        transfer_enable_int,
        transfer_unit,
    ))
