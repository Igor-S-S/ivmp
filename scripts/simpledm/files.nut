//Проверка сеществования файла
function fExists(fpath)
{
  try
  {
    file(fpath, "r");
  }
  catch(e)
  {
    return false;
  }
  return true;
}

function PrintToLog(text,filen=LogFile)
{
    local logF,filename,str;
	local z=date(time());
	str = format("[%d-%d-%d %d:%d:%d]  %s",z.day,z.month,z.year,z.hour,z.min,z.sec,text)
	filename = format("files/%s/%s",SysDir,filen);
	local logF = file(filename, "a+");
	local maxSize = MaxLogSize*1024*1024;
	if(logF.len() > maxSize)
	{
	    local result = "";
	    while(!logF.eos())
	    {
	        local c = logF.readn('c');
	        result += c.tochar();
	    }
	    local filename2 = format("%s/old_%d.%d.%d_%d.%d-%s",SysDir,z.day,z.month,z.year,z.hour,z.min,filen);
		local newFile = file(filename2, "a+");
		logF = null;
		logF = file(filename, "w+");
		foreach(char in result)
	    {
	        newFile.writen(char, 'c');
	    }
		foreach(char in str)
	    {
	        logF.writen(char, 'c');
	    }
		logF.writen('\n', 'c');
	}
	foreach(char in str)
	{
	    logF.writen(char, 'c');
	}
	logF.writen('\n', 'c');
}