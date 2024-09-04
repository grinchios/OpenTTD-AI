function GetDate() {
    /*
    * Get the current date in the format [dd/mm/yy]
    */
    local date = AIDate.GetCurrentDate();
    local tmp = null;
    tmp = AIDate.GetDayOfMonth(date).tostring();
    local day = tmp.len() < 2 ? "0" + tmp : tmp;
    tmp = AIDate.GetMonth(date).tostring();
    local month = tmp.len() < 2 ? "0" + tmp : tmp;
    tmp = AIDate.GetYear(date).tostring();
    local year = tmp.slice(2);
    return "[" + day +"/" + month + "/" + year + "]";
}

function Info(message) {
    /*
    * Log an info message to the console
    */
    AILog.Info("[+] " + GetDate() + " - " + message);
}

function Warning(message) {
    /*
    * Log a warning message to the console
    */
    AILog.Warning("[-] " + GetDate() + " - " + message);
}

function Error(message) {
    /*
    * Log an error message to the console
    */
    AILog.Error("[*] " + GetDate() + " - " + message);
}

function OutputList(list) {
    /*
    * Output the contents of a list to the console
    */
    for (local element = list.Begin(); list.HasNext(); element = list.Next()) {
        Info("Key:" + element + " Value:" + list.GetValue(element));
    }
}

function split(message, split_on) {
    /*
    * Split a message into a list based on a character, like the Python split method
    */
	local buf = "";
	local split_message = [];
	for (local i=0; i<message.len(); i++) {
		if (message[i].tochar() != split_on) {
			buf = buf + "" + message[i].tochar();
		} else {
			split_message.append(buf);
			buf = "";
		}
	}
	split_message.append(buf);
	return split_message
}