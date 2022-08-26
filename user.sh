#!/bin/bash
#Set PATH
userfile=/etc/opt/ss5/user.sh
passwdFile=/etc/opt/ss5/ss5.passwd
confFile=/etc/opt/ss5/ss5.conf
portFile=/etc/sysconfig/ss5

echo ""
echo "*******************************"
cat $confFile | while read line
do
if  [[ $line =~ "permit u	0.0.0.0/0	-	0.0.0.0/0	-	-	-	-	-" ]] ;then
    echo  "@Account Verification: Enabled@"
    break
fi

if  [[ $line =~ "permit -	0.0.0.0/0	-	0.0.0.0/0	-	-	-	-	-" ]] ;then
    echo "@Account Verification: Disabled@"
    break
fi

done
echo "*******************************"
echo "1.List Accounts"
echo "2.Add Account"
echo "3.Delete Account"
echo "4.Enable Account Verification"
echo "5.Disable Account Verification"
echo "6.Edit Port Number"
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
    echo "User	Password"
    cat $passwdFile | while read line
    do
        echo "$line" #输出整行内容
        #echo "$line" | awk '{print $1}' #输出每行第一个字
    done
    bash $userfile
fi

if [[ $choice == 2 ]];then
    clear
    cd /etc/opt/ss5

    read -p "Enter User Name: " uname
    echo ""
    read -p "Enter Password: " upasswd
    echo ""
    echo -e $uname $upasswd >> ss5.passwd
    echo "*Success!*"
    bash $userfile
fi

if [[ $choice == 3 ]];then
    clear
    read -p "Enter User Name: " uname
    echo ""
    sed -i -e "/$uname/d" $passwdFile
    echo "*Success! Work after restart s5.*"
    bash $userfile
fi

if [[ $choice == 4 ]];then
    clear
    sed -i '87c auth    0.0.0.0/0               -               u' $confFile
    sed -i '203c permit u	0.0.0.0/0	-	0.0.0.0/0	-	-	-	-	-' $confFile
    echo ""
    var=`service ss5 restart`
    if [[ $var =~ "OK" ]] ;then
        echo "Enable Verification: Success!"
        else
        echo "Enable Verification: Failed!"
    fi
    bash $userfile
fi

if [[ $choice == 5 ]];then
    clear
    sed -i '87c auth    0.0.0.0/0               -               -' $confFile
    sed -i '203c permit -	0.0.0.0/0	-	0.0.0.0/0	-	-	-	-	-' $confFile
    echo ""
    var=`service ss5 restart`
    if [[ $var =~ "OK" ]] ;then
        echo "Disable Verification: Success!"
        else
        echo "Disable Verification: Failed!"
    fi
    bash $userfile
fi

if [[ $choice == 6 ]];then
    clear
    read -p "Enter A New Port: " port
    sed -i '2c SS5_OPTS="-u root -b 0.0.0.0:' $portFile
    sed -i "/0.0.0:/ s/$/$port\"/" $portFile
    echo ""
    var=`service ss5 restart`
    if [[ $var =~ "OK" ]] ;then
        echo "Edit Port: Success!"
        else
        echo "Edit Port: Failed!"
    fi
    bash $userfile
fi
