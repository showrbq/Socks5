#!/bin/bash
#Set PATH

resName="showrbq"
serviceFile=/etc/opt/ss5/service.sh
newVersionMsg=`curl -s -L  https://raw.githubusercontent.com/${resName}/Socks5/master/update.txt`

echo ""
echo "1.Start"
echo "2.Stop"
echo "3.Restart"
echo "4.Status"
echo "5.Update"
echo "6.Uninstall"
echo "0.Exit"
while :; do echo
	read -p "Enter: " choice
	if [[ ! $choice =~ ^[0-6]$ ]]; then
		echo "Unknown choice!"
	else
		break
	fi
done

if [[ $choice == 0 ]];then
	s5
fi

if [[ $choice == 1 ]];then
    clear
    if [ ! -d "/var/run/ss5/" ];then
        mkdir /var/run/ss5
    fi
    service ss5 start
    bash $serviceFile
fi

if [[ $choice == 2 ]];then
	clear
	service ss5 stop
	bash $serviceFile
fi

if [[ $choice == 3 ]];then
	clear
	service ss5 restart
	bash $serviceFile
fi

if [[ $choice == 4 ]];then
	clear
	service ss5 status
	bash $serviceFile
fi

if [[ $choice == 5 ]];then
	clear
	echo "You will lose all the program data after update, please backup first!"
	echo " "
	echo "New Version: "
	echo -e ${newVersionMsg}
	echo " "
	read -p "Enter 123 to continue: " c
	if [[ "$c" == "123" ]];then
	wget -q -N --no-check-certificate https://raw.githubusercontent.com/${resName}/Socks5/master/install.sh && bash install.sh
	exit 0
	else
		clear
		bash $serviceFile
	fi
fi

if [[ $choice == 6 ]];then
	clear
	echo "Are you sure you want to uninstall the program?"
	read -p "Enter 886 to continue: " c
	if [[ "$c" == "886" ]];then
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
        clear
        echo "Uninstall Fininshed."
        exit 0
	else
		bash $serviceFile
	fi
fi
