#/bin/sh
#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
echo "##################################
      AR-B-P-B 自检系统
             V1.0 Alpha
##################################"
report_path="/usr/local/SSR-Bash-Python/report.json"
rm -f "${report_path}"
#List /usr/local
echo "############Filelist of /usr/local" >> "${report_path}"
cd /usr/local
ls >> "${report_path}"
#List /usr/local/ssr-bash-python3
echo "############Filelist of /usr/local/SSR-Bash-Python" >> "${report_path}"
cd /usr/local/SSR-Bash-Python
ls >> "${report_path}"
#List /usr/local/shadowsockr
echo "############Filelist of /usr/local/shadowsockr" >> "${report_path}"
cd /usr/local/shadowsocksr
ls >> "${report_path}"
echo "############File test" >> "${report_path}"
#Check File Exist
if [ ! -f "/usr/local/bin/ssr" ]; then
  echo "SSR-Bash-Python主文件缺失，请确认服务器是否成功连接至Github"
  echo "SSR Miss" >> "${report_path}"
  exit
fi
if [ ! -f "/usr/local/SSR-Bash-Python/server.sh" ]; then
  echo "SSR-Bash-Python主文件缺失，请确认服务器是否成功连接至Github"
  echo "SSR Miss" >> "${report_path}"
  exit
fi
if [ ! -f "/usr/local/shadowsocksr/stop.sh" ]; then
  echo "SSR主文件缺失，请确认服务器是否成功连接至Github"
  echo "SSR Miss" >> "${report_path}"
  exit
fi

#Firewall
echo "############Firewall test" >> "${report_path}"
iptables -L >> "${report_path}"

echo "检测完成，未发现严重问题，如仍有任何问题请提交report.json"
