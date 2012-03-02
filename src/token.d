import bi_basics;
import environment;
import system;
import std.conv;
import std.cstream;
import std.string;
import std.math;

alias Token function(ref Token[], ref Environment) Function;

struct Token {
public:
	enum VarType {
		tNone, tComment,
		tCode, tCompoundStatement, tString, tNumeric, tRawArray, tArray,
		tRawDictionary, tDictionary, tVarname, tTypeID,
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
	@property ref real d() {
		str.length = real.sizeof;
		return *cast(real*)str.ptr;
	}
	// Helper functions that let me do construction-time editing
	Token withNumeric(real _d) {
		d = _d;
		type = VarType.tNumeric;
		return this;
	}
	Token withType(VarType t) {
		type = t;
		return this;
	}
	Token withString(string _str) {
		str = _str;
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
	bool opCast(T:bool)() {
		return ((type==VarType.tNumeric && d != 0) ||
				(type==VarType.tString && str != "") ||
				(type==VarType.tArray && arr != []));
	}
}

bool iterableType(Token.VarType t) {
	return (t == Token.VarType.tArray ||
			t == Token.VarType.tDictionary ||
			t == Token.VarType.tCode ||
			t == Token.VarType.tFunction ||
			t == Token.VarType.tVariadicFunction
	);
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
		case Token.VarType.tDictionary:
			return "Dictionary";
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