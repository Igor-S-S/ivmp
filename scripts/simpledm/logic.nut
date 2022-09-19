//Типы переменных
//integer
function is_int(var)
{
    try
	{
	    var.tointeger()
	}
	catch(e)
	{
	    return false;
	}
	return true;
}

//случайный вывод
function roundingoff(val){
    local p,c,idx;
	p = ((val*1000).tointeger()).tofloat()/10;
	c = p.tointeger();
	p = ((p - c.tofloat())*10).tointeger();
	if(p >= 5) idx = 0.01;
	else idx = 0;
	val = ((val*100).tointeger()).tofloat()/100;
	val = val + idx;
	return val;
}

function mrand(max){
    return rand()*(max+1)/32767;
}

function random(min = 0, max = RAND_MAX)
{
	return (rand() % ((max + 1) - min)) + min; 
}