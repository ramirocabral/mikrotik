/system scheduler
add comment="send router status via telegram" interval=6h name=status \
    on-event=sendStatus policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    start-date=startup