#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
import cgi

with open("/usr/local/shadowsocksr/mudb.json", "r", encoding="utf-8") as f:
    data = json.load(f)

# 接受表达提交的数据
form = cgi.FieldStorage()

# 解析处理提交的数据
getport = form['port'].value

# 判断端口是否找到
portexist = 0

# 循环查找端口
for x in data:
    # 当输入的端口与json端口一样时视为找到
    if str(x["port"]) == str(getport):
        portexist = 1
        transfer_enable_int = int(x["transfer_enable"]) // 1024 // 1024
        d_int = int(x["d"]) // 1024 // 1024
        transfer_unit = "MB"
        d_unit = "MB"

        # 流量单位转换
        if transfer_enable_int > 1024:
            transfer_enable_int = transfer_enable_int // 1024
            transfer_unit = "GB"
        if transfer_enable_int > 1024:
            d_int = d_int // 1024
            d_unit = "GB"
        break

if portexist == 0:
    getport = "未找到此端口，请检查是否输入错误！"
    d_int = ""
    d_unit = ""
    transfer_enable_int = ""
    transfer_unit = ""

header = '''
<!DOCTYPE html>
<html lang="en">
<head>
\t<meta charset="utf-8">
\t<meta content="IE=edge" http-equiv="X-UA-Compatible">
\t<meta content="initial-scale=1.0, width=device-width" name="viewport">
\t<title>流量查询</title>
\t<!-- css -->
\t<link href="../css/base.min.css" rel="stylesheet">

\t<!-- favicon -->
\t<!-- ... -->

\t<!-- ie -->
    <!--[if lt IE 9]>
        <script src="../js/html5shiv.js" type="text/javascript"></script>
        <script src="../js/respond.js" type="text/javascript"></script>
    <![endif]-->
    
</head>
<body>
    <div class="content">
        <div class="content-heading">
            <div class="container">
                <h1 class="heading">&nbsp;&nbsp;流量查询</h1>
            </div>
        </div>
        <div class="content-inner">
            <div class="container">
'''

footer = '''
</div>
        </div>
    </div>
\t<footer class="footer">
\t\t<div class="container">
\t\t\t<p>Function Club</p>
\t\t</div>
\t</footer>

\t<script src="../js/base.min.js" type="text/javascript"></script>
</body>
</html>
'''

# 打印返回的内容
print(header)
formhtml = '''

<div class="card-wrap">
\t\t\t\t\t<div class="row">
\t\t\t\t\t\t<div class="col-lg-3 col-md-4 col-sm-6">
\t\t\t\t\t\t\t<div class="card card-alt card-alt-bg">
\t\t\t\t\t\t\t\t<div class="card-main">
\t\t\t\t\t\t\t\t\t<div class="card-inner">
\t\t\t\t\t\t\t\t\t\t<p class="card-heading">端口：%s</p>
\t\t\t\t\t\t\t\t\t\t<p>
\t\t\t\t\t\t\t\t\t\t\t已使用流量：%s %s <br>
\t\t\t\t\t\t\t\t\t\t\t总流量限制：%s %s </br></br>
\t\t\t\t\t\t\t\t\t\t\t<a href="../index.html"><button class="btn" type="button">返回</button></a>
\t\t\t\t\t\t\t\t\t\t</p>
\t\t\t\t\t\t\t\t\t</div>
\t\t\t\t\t\t\t\t</div>
\t\t\t\t\t\t\t</div>
\t\t\t\t\t\t</div>
\t\t\t\t\t\t
\t\t\t\t\t</div>
\t\t\t\t\t\t
\t\t\t\t\t\t
\t\t\t\t</div>



'''
print(formhtml % (getport, d_int, d_unit, transfer_enable_int, transfer_unit))

print(footer)
