function GetDate() {
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
    AILog.Info("[+] " + GetDate() + " - " + message);
}

function Warning(message) {
    AILog.Warning("[-] " + GetDate() + " - " + message);
}

function Error(message) {
    AILog.Error("[*] " + GetDate() + " - " + message);
}

function OutputList(list) {
    for (local element = list.Begin(); list.HasNext(); element = list.Next()) {
        Info("Key:" + element + " Value:" + list.GetValue(element));
    }
}