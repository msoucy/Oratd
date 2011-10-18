import bi_basics;
import environment;
import std.conv;
import std.cstream;

typedef Token function(ref Token[], ref Environment) Function;

struct Token {
public:
	enum VarType {
		tNone,
		tCode, tCompoundStatement, tString, tNumeric, tRawArray, tArray,
		tVarname, tTypeID,
		tType, tFunction, tOpcode, tSpecial, tBuiltin, tRecast,
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
				return 3;
			}
		}
		void d(real _d) {
			str = to!(string)(_d);
		}
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