#! /usr/bin/env python3
# -*- coding: utf-8 -*-
import json
import cgi
import urllib.request

# 取得本机外网IP
with urllib.request.urlopen('http://members.3322.org/dyndns/getip') as resp:
    myip = resp.read().decode('utf-8').strip()

# 加载SSR JSON文件
with open("/usr/local/shadowsocksr/mudb.json", "r", encoding="utf-8") as f:
    data = json.load(f)

# 接受表达提交的数据
form = cgi.FieldStorage()

# 解析处理提交的数据
getport = form['port'].value
getpasswd = form['passwd'].value

# 判断端口是否找到
portexist = 0
passwdcorrect = 0

# 循环查找端口
for x in data:
    # 当输入的端口与json端口一样时视为找到
    if str(x["port"]) == str(getport):
        portexist = 1
        if str(x["passwd"]) == str(getpasswd):
            passwdcorrect = 1
            jsonmethod = str(x["method"])
            jsonobfs = str(x["obfs"])
            jsonprotocol = str(x["protocol"])
        break

if portexist == 0:
    getport = "未找到此端口，请检查是否输入错误！"
    myip = ""
    getpasswd = ""
    jsonmethod = ""
    jsonprotocol = ""
    jsonobfs = ""

if portexist != 0 and passwdcorrect == 0:
    getport = "连接密码输入错误，请重试"
    myip = ""
    getpasswd = ""
    jsonmethod = ""
    jsonprotocol = ""
    jsonobfs = ""

header = '''
<!DOCTYPE html>
<html lang="en">
<head>
\t<meta charset="utf-8">
\t<meta content="IE=edge" http-equiv="X-UA-Compatible">
\t<meta content="initial-scale=1.0, width=device-width" name="viewport">
\t<title>连接信息</title>
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
                <h1 class="heading">&nbsp;&nbsp;连接信息</h1>
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
\t\t\t\t\t\t
\t\t\t\t\t\t
\t\t\t\t\t\t<div class="col-lg-4 col-sm-6">
\t\t\t\t\t\t\t<div class="card card-green">
\t\t\t\t\t\t\t\t<a class="card-side" href="/"><span class="card-heading">连接信息</span></a>
\t\t\t\t\t\t\t\t<div class="card-main">
\t\t\t\t\t\t\t\t\t<div class="card-inner">
\t\t\t\t\t\t\t\t\t<p>
\t\t\t\t\t\t\t\t\t\t<strong>服务器地址：</strong> %s </br></br>
\t\t\t\t\t\t\t\t\t\t<strong>连接端口：</strong> %s </br></br>
\t\t\t\t\t\t\t\t\t\t<strong>连接密码：</strong> %s </br></br>
\t\t\t\t\t\t\t\t\t\t<strong>加密方式： </strong> %s </br></br>
\t\t\t\t\t\t\t\t\t\t<strong>协议方式： </strong> </br>%s </br></br>
\t\t\t\t\t\t\t\t\t\t<strong>混淆方式：</strong> </br>%s 
\t\t\t\t\t\t\t\t\t\t</p>
\t\t\t\t\t\t\t\t\t</div>
\t\t\t\t\t\t\t\t\t<div class="card-action">
\t\t\t\t\t\t\t\t\t\t<ul class="nav nav-list pull-left">
\t\t\t\t\t\t\t\t\t\t\t<li>
\t\t\t\t\t\t\t\t\t\t\t\t<a href="../index.html"><span class="icon icon-check"></span>&nbsp;返回</a>
\t\t\t\t\t\t\t\t\t\t\t</li>
\t\t\t\t\t\t\t\t\t\t</ul>
\t\t\t\t\t\t\t\t\t</div>
\t\t\t\t\t\t\t\t</div>
\t\t\t\t\t\t\t</div>
\t\t\t\t\t\t</div>
\t\t\t\t\t\t
\t\t\t\t\t\t
\t\t\t\t\t</div>
\t\t\t\t\t\t
\t\t\t\t\t\t
\t\t\t\t</div>




'''

print(formhtml % (myip, getport, getpasswd, jsonmethod, jsonprotocol, jsonobfs))
print(footer)
