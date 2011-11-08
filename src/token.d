import bi_basics;
import environment;
import system;
import std.conv;
import std.cstream;
import std.string;
import std.math;

typedef Token function(ref Token[], ref Environment) Function;

struct Token {
public:
	enum VarType {
		tNone, tComment,
		tCode, tCompoundStatement, tString, tNumeric, tRawArray, tArray,
		tVarname, tTypeID,
		tType, tFunction, tOpcode, tSpecial, tBuiltin, tRecast, tVariadicFunction,
		tCommandSeperator, tArrayElementSeperator,
		tVarOffsetSeperator, tClosingParen, tClosingBrace, tClosingBracket,
		tMax
	}
	Function func = &bi_basics.bi_null;
	VarType type = VarType.tNone;
	Token[] arr;
	this(real _d=0) {
		d = _d;
		type = VarType.tNumeric;
	}
	this(string _s) {
		str = _s;
		type = VarType.tString;
	}
	string str = "";
	@property {
		real d() {
			try {
				return to!real(str);
			} catch (Exception e) {
				return real.nan;
			}
		}
		void d(real _d) {
			static if(0) str = to!(string)(_d);
			else pd = _d;
		}
		void pd(real _d) {
			if(approxEqual(_d,cast(long)_d,1e-15)) {
				str = to!(string)(_d);
			} else {
				str = format("%.15f",_d);
				if(indexOf(str,'.')!=-1) {
					auto index = indexOf(str,'.');
					bool detected = false;
					for(uint i=index+1;i<str.length && i<index+6;i++) {
						if(str[i]!='0') {
							detected=true;
							break;
						}
					}
					if(!detected) {
						str = str[0..index+6];
					}
				}
				munchEnd(str,"0");
				if(str.length && str[$-1]=='.') {str = str[0..$-1];}
			}
			if(str=="") str = "0";
		}
	}
	// Helper functions that let me do construction-time editing
	ref Token withPreciseNumeric(real _d) {
		pd = _d;
		type = VarType.tNumeric;
		return this;
	}
	ref Token withNumeric(real _d) {
		d = _d;
		type = VarType.tNumeric;
		return this;
	}
	ref Token withType(VarType t) {
		type = t;
		return this;
	}
	ref Token withArray(uint s) {
		type = VarType.tArray;
		arr.length = s;
		return this;
	}
	bool opEquals(Token b) {
		if(arr.length != b.arr.length) return false;
		for(uint i=0;i<arr.length;i++) {
			if(arr[i] != b.arr[i]) return false;
		}
		return (str == b.str && func == b.func && type == b.type); 
	}
}

string vartypeToStr(Token.VarType v)
{
	switch(v) {
		case Token.VarType.tCode:
			return "Code";
		case Token.VarType.tCompoundStatement:
			return "Compound Statement";
		case Token.VarType.tString:
			return "String";
		case Token.VarType.tNumeric:
			return "Numeric";
		case Token.VarType.tRawArray:
			return "Raw Array";
		case Token.VarType.tArray:
			return "Array";
		case Token.VarType.tVarname:
			return "Variable Name";
		case Token.VarType.tTypeID:
			return "Type ID";
		case Token.VarType.tType:
			return "";
		case Token.VarType.tFunction:
			return "Function";
		case Token.VarType.tVariadicFunction:
			return "Variadic Function";
		case Token.VarType.tOpcode:
			return "Operation Code";
		case Token.VarType.tSpecial:
			return "Special Character";
		case Token.VarType.tBuiltin:
			return "Built In Function";
		case Token.VarType.tCommandSeperator:
			return "Command Seperator";
		case Token.VarType.tRecast:
			return "Cast operator";
		case Token.VarType.tArrayElementSeperator:
			return "Array Element Seperator";
		case Token.VarType.tVarOffsetSeperator:
			return "Variable Offset Seperator";
		case Token.VarType.tClosingParen:
			return "Closing )";
		case Token.VarType.tClosingBrace:
			return "Closing }";
		case Token.VarType.tClosingBracket:
			return "Closing ]";
		case Token.VarType.tMax:
			return "Maximum";
		case Token.VarType.tNone:
		default:
			return "None";
	}
}