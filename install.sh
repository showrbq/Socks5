#!/bin/sh
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#Check OS
if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ];then
    OS=CentOS
    [ -n "$(grep ' 7\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
    [ -n "$(grep ' 6\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release6 15' /etc/issue)" ] && CentOS_RHEL_version=6
    [ -n "$(grep ' 5\.' /etc/redhat-release)" -o -n "$(grep 'Aliyun Linux release5' /etc/issue)" ] && CentOS_RHEL_version=5
elif [ -n "$(grep 'Amazon Linux AMI release' /etc/issue)" -o -e /etc/system-release ];then
    OS=CentOS
    CentOS_RHEL_version=6
elif [ -n "$(grep bian /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Debian' ];then
    OS=Debian
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Deepin /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Deepin' ];then
    OS=Debian
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Ubuntu /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Ubuntu' -o -n "$(grep 'Linux Mint' /etc/issue)" ];then
    OS=Ubuntu
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
    [ -n "$(grep 'Linux Mint 18' /etc/issue)" ] && Ubuntu_version=16
else
    echo "Does not support this OS, Please contact the author! "
    kill -9 $$
fi

#Install Basic Tools
if [[ ${OS} == Ubuntu ]];then
	echo "*************************"
	echo "*Ubuntu is not supported*"
	echo "* Please Use CentOS     *"
	echo "*************************"
	exit 0
	apt-get install git unzip wget -y
fi

if [[ ${OS} == CentOS ]];then
	yum install git unzip wget -y
fi

if [[ ${OS} == Debian ]];then
	echo "*************************"
	echo "*Debian is not supported*"
	echo "* Please Use CentOS     *"
	echo "*************************"
	exit 0
	apt-get install git unzip wget -y
fi

#1.清理旧环境和配置新环境
Clear()
{
    unInstall
    clear
    echo "Clean environment done."
    echo ""
    echo "Installing dependencies, please wait..."
    yum -y install gcc gcc-c++ automake make pam-devel openldap-devel cyrus-sasl-devel openssl-devel
    yum update -y nss curl libcurl 

    #配置环境变量
    sed -i '$a export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin' ~/.bash_profile
    source ~/.bash_profile

    #关闭防火墙
    newVersion=`cat /etc/redhat-release|sed -r 's/.* ([0-9]+)\..*/\1/'`
    if [[ ${newVersion} = "7" ]];then
        systemctl stop firewalld
        systemctl disable firewalld
    elif [[ ${newVersion} = "6" ]];then 
        service iptables stop
        chkconfig iptables off
    else
        echo "Exception version"
    fi
}

#2.下载Socks5服务
Download()
{
    echo ""
    echo "Downloading Socks5..."
    cd /root
    git clone https://github.com/showrbq/Socks5
}

#3.安装Socks5服务程序
InstallSock5()
{
    echo ""
    echo "Unzipping..."
    cd  /root/Socks5
    tar zxvf ./ss5-3.8.9-8.tar.gz

    echo "Installing..."
    cd /root/Socks5/ss5-3.8.9
    ./configure
    make
    make install
}

#4.安装控制面板配置参数
InstallPanel()
{
    #cd  /root/Socks5
    mv /root/Socks5/service.sh /etc/opt/ss5/
    mv /root/Socks5/user.sh /etc/opt/ss5/
    mv /root/Socks5/version.txt /etc/opt/ss5/
    mv /root/Socks5/ss5 /etc/sysconfig/
    mv /root/Socks5/s5 /usr/local/bin/
    chmod +x /usr/local/bin/s5

    #设置默认用户名、默认开启帐号验证
    uname="123456"
    upasswd="654321"
    port="5555"
    confFile=/etc/opt/ss5/ss5.conf
    echo -e $uname $upasswd >> /etc/opt/ss5/ss5.passwd
    sed -i '87c auth    0.0.0.0/0               -               u' $confFile
    sed -i '203c permit u	0.0.0.0/0	-	0.0.0.0/0	-	-	-	-	-' $confFile

    #添加开机启动
    chmod +x /etc/init.d/ss5
    chkconfig --add ss5
    chkconfig --level 345 ss5 on
    confFile=/etc/rc.d/init.d/ss5
    sed -i '/echo -n "Starting ss5... "/a if [ ! -d "/var/run/ss5/" ];then mkdir /var/run/ss5/; fi' $confFile
    sed -i '54c rm -rf /var/run/ss5/' $confFile
    sed -i '18c [[ ${NETWORKING} = "no" ]] && exit 0' $confFile

    #判断ss5文件夹是否存在、
    if [ ! -d "/var/run/ss5/" ];then
        mkdir /var/run/ss5/
        echo "Create ss5 success!"
        else
        echo "/ss5/ is OK!"
    fi
}

#5.检测是否安装完整
check()
{
    cd /root
    rm -rf /root/Socks5
    rm -rf /root/install.sh
    errorMsg=""
    isError=false
    if [ ! -f "/usr/local/bin/s5" ];then
        errorMsg=${errorMsg}"001|"
        isError=true   
    fi
    if [ ! -f "/etc/opt/ss5/service.sh" ];then
        errorMsg=${errorMsg}"002|" 
        isError=true
    fi
    if [ ! -f "/etc/opt/ss5/user.sh" ];then
        errorMsg=${errorMsg}"003|"
        isError=true	
    fi
    if [ ! -f "/etc/opt/ss5/ss5.conf" ];then
        errorMsg=${errorMsg}"004|"
        isError=true	
    fi

    if [ "$isError" = "true" ];then
        unInstall
        clear
        echo ""
        echo "File missing, failed to install"
        echo "Error: "${errorMsg}
        echo "Email: wyx176@gmail.com"
        echo "Telegram: t.me/Socks55555"
        exit 0
    else
        clear
        echo ""
        #service ss5 start
        if [[ ${newVersion} = "7" ]] ; then
        systemctl daemon-reload
        fi
        service ss5 start
        echo ""
        echo "Socks5 Installed!"
        echo ""
        echo "Enter s5 to start"
        echo ""
        echo "User    : "${uname}
        echo "Password: "${upasswd}
        echo "Port    : "${port}
        echo ""
        echo "Telegram @Socks55555"
        echo ""
        exit 0
    fi
}

#6.卸载
unInstall(){
    service ss5 stop
    rm -rf /run/ss5
    rm -f  /run/lock/subsys/ss5
    rm -rf /etc/opt/ss5
    rm -f  /usr/local/bin/s5
    rm -rf /usr/lib/ss5
    rm -f  /usr/sbin/ss5
    rm -rf /usr/share/doc/ss5
    rm -rf /root/ss5-3.8.9
    rm -f  /etc/sysconfig/ss5
    rm -f  /etc/rc.d/init.d/ss5
    rm -f  /etc/pam.d/ss5
    rm -rf /var/log/ss5
}

Clear
Download
InstallSock5
InstallPanel
check
