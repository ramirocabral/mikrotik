:local botToken "XXXXX"
:local chatID "XXXXX"
:local sendText $messageText;

/tool fetch url="https://api.telegram.org/bot$botToken/sendMessage\?chat_id=$chatID&parse_mode=HTML&text=$sendText" keep-result=no;
