function getPlayerAmount()
{
   local count = 0;
   for(local i = 0; i < getPlayerSlots(); i++)
   {
       if(isPlayerConnected(i))
	   {
	      count++;
	   }
   }
   return count;
}

function checkname(name){	
	/*if (MODE_NAME_CHECK!=1) return 1;
	local reg;
	if (MODE_NAME_CHECK_MODE==2){
		reg="[-_a-zA-Z0-9]+";
	}
	else if (MODE_NAME_CHECK_MODE==3){
		reg="[a-zA-Z0-9]+_[a-zA-Z0-9]+";
	}
	else {
		reg="[a-zA-Z]+";
	}
	local ex = regexp("^"+reg+"$");*/
	//local ex = regexp(@"^([-_0-9a-zA-Z\[\]]+)$"); // С РАЗРЕШЕННЫМ ТЕГОМ
	local ex = regexp(@"^([-_0-9a-zA-Z]+)$"); // тег клана запрещен
	return ex.match(name);		
}