import std.file;
import std.math;
import std.stdio;
import std.string;

const string FILEXT = ".or";

int charToInt(char c) {
	if(c >= '0' && c <= '9') return (c-'0');
	if(c == 'a' || c == 'A') return 10;
	if(c == 'b' || c == 'B') return 11;
	if(c == 'c' || c == 'C') return 12;
	if(c == 'd' || c == 'D') return 13;
	if(c == 'e' || c == 'E') return 14;
	if(c == 'f' || c == 'F') return 15;
	return 0;
}

real strToDouble(string str, int base)
{
	// Assume that the input string is well-formed
	// The lexer will handle that.
	if(base != 10 && base != 2 && base != 8 && base != 16) return 0;
	real ret = 0;
	real mantissa = 0;
	
	
	for(uint i=0;i<str.length;i++) {
		if(str[i] == '.') {
			mantissa = 1;
		} else {
			if(mantissa != 0) {
				// We're "below" the mantissa
				ret += charToInt(str[i]) * (base ^^ (-mantissa));
				mantissa++;
			} else {
				// We're still "above" the mantissa
				ret *= base;
				ret += charToInt(str[i]);
			}
		}
	}
			
	return ret;
}

S1 munchEnd(S1,S2)(ref S1 s, S2 pattern)
{
	S1 ret;
	while(s.length && inPattern(s[$-1],pattern)) {
		ret = s[$-1]~ret;
		s = s[0..$-1];
	}
	return ret;
}