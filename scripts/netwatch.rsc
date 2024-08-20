# check WAN connection every 1 minute.
/tool netwatch
add disabled=no down-script=fail host=8.8.8.8 http-codes="" interval=1m name=\
    internet-test test-script="" type=icmp up-script=""

# credits: https://disnetern.ru/play-mikrotik-beeper-melody-script/
/system script
add dont-require-permissions=yes name=fail owner=ramiro policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=" \
    :for t from=1250 to=600 step=-8 do={\r\
    \n :beep frequency=\$t length=11ms;\r\
    \n :delay 11ms;\r\
    \n }"
