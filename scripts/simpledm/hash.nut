//Хэш функции
function hash(str){
	local s1 = 1;
	local s2 = 0;		
	for (local n=0; n<str.len(); n++)
	{
		s1 = (s1 + str[n]) % 65521;
		s2 = (s2 + s1)     % 65521;
	}
	return (s2 << 16) + s1;
}