:local routerosVersion [ /system resource get version ]
:local rbName [ /system resource get board-name ]
:local publicIPv4 [ /ip cloud get public-address ]
:local cpuLoad [ /system resource get cpu-load ]
:local temp [/system health get 1 value]
:local uptime [ /system resource get uptime ]
:local totalMemory ([ /system resource get total-memory ] / 1048576)
:local freeMemory ([ /system resource get free-memory ] /1048576)
:local totalHDD ([ /system resource get total-hdd-space ] /1048576)
:local freeHDD ([ /system resource get free-hdd-space ] /1048576)

:local text "\F0\9F\93\A1 <b>Mikrotik System Status</b>%0A \
    Board Name: $rbName%0A \
    ROS Version: $routerosVersion%0A \
    Uptime: $uptime%0A \
    IPv4: $publicIPv4%0A \
    CPU Load: $cpuLoad %%0A \
    Temp : $temp\C2\B0C%0A \
    Total Memory: $totalMemory MiB%0A \
    Free Memory: $freeMemory MiB%0A \
    Total Disk: $totalHDD MiB%0A \
    Free Disk: $freeHDD MiB";

:local sendTelegram [ :parse [/system script get sendTelegramMessage source] ];

$sendTelegram messageText=$text
