import errors;
import std.conv;
import std.stdio;
import std.string;
import std.array;

struct Token {
private:
	string _str = "";
public:
	enum VarType {
		tNone,
		tCode,
		tCompoundStatement,
		tString,
		tNumeric,
		tRawArray,
		tArray,
		tVarname,
		tType,
		tFunction,
		tOpcode,
		tSpecial,
		tCommandSeperator,
		tArrayElementSeperator,
		tVarOffsetSeperator,
		tClosingParen,
		tClosingBrace,
		tClosingBracket,
		tMax
	}
	VarType type = VarType.tNone;
	Token[] arr;
	this(real _d=0) {
		d = _d;
	}
	this(string _s) {
		str = _s;
	}
	@property string str() {
		return _str;
	}
	@property void str(string nval) {
		_str = nval;
	}
	@property real d() {
		try {
			return to!real(str);
		} catch (Exception e) {
			return 0;
		}
	}
	@property void d(real _d) {
		_str = to!(string)(_d);
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
		case Token.VarType.tType:
			return "Data Type";
		case Token.VarType.tFunction:
			return "Function";
		case Token.VarType.tOpcode:
			return "Operation Code";
		case Token.VarType.tSpecial:
			return "Special Character";
		case Token.VarType.tCommandSeperator:
			return "Command Seperator";
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