import environment;
import token;
import errors;
import system;
import bi_math : bi_int;
import std.string;
import std.cstream;

void import_casts(ref Environment env)
{
	mixin(AddFunc!("cast"));
	
	// ALL the built in conversions...
	env.conversions["code"]["array"] = function Token(Token t) {
		return t.withType(Token.VarType.tArray);
	};
	env.conversions["string"]["numeric"] = function Token(Token t) {
		return t.withType(Token.VarType.tNumeric).withNumeric(strToDouble(t.str));
	};
	env.conversions["string"]["int"] = function Token(Token t) {
		return t.withType(Token.VarType.tNumeric).withNumeric(cast(long)strToDouble(t.str));
	};
	env.conversions["numeric"]["string"] = function Token(Token t) {
		return t.withType(Token.VarType.tString).withString(realToString(t.d));
	};
	env.conversions["numeric"]["hex"] = function Token(Token t) {
		return t.withType(Token.VarType.tString).withString(realToString!16(t.d));
	};
	env.conversions["numeric"]["oct"] = function Token(Token t) {
		return t.withType(Token.VarType.tString).withString(realToString!8(t.d));
	};
	env.conversions["numeric"]["bin"] = function Token(Token t) {
		return t.withType(Token.VarType.tString).withString(realToString!2(t.d));
	};
	env.conversions["array"]["numeric"] = env.conversions["array"]["length"] = function Token(Token t) {
		return Token(t.arr.length);
	};
}

string getType(Token t)
{
	switch(t.type) {
		case Token.VarType.tCode:
			return "code";
		case Token.VarType.tString:
			return "string";
		case Token.VarType.tNumeric:
			return "numeric";
		case Token.VarType.tArray:
			return "array";
		case Token.VarType.tTypeID:
			return "typeid";
		case Token.VarType.tDictionary:
			return "dict";
		case Token.VarType.tType:
			return t.str;
		/////////////////////////////////////////////////////
		case Token.VarType.tFunction:
			return format("function<%s>",t.arr[0].arr.length);
		case Token.VarType.tVariadicFunction:
			return format("vfunction<%s>",t.arr[0].arr.length);
		/////////////////////////////////////////////////////
		case Token.VarType.tOpcode:
			return "opcode";
		case Token.VarType.tSpecial:
			return "special";
		case Token.VarType.tBuiltin:
			return "builtin";
		default:
			return "";
	}
}

Token bi_cast(ref Token[] argv, ref Environment env)
{
	if(argv.length != 2) throw new OratrArgumentCountException(argv.length,"cast","2");
	Token newType = argv[0];
	if(newType.type != Token.VarType.tVarname && newType.type != Token.VarType.tString) {
		throw new OratrInvalidArgumentException(vartypeToStr(newType.type),0);
	}
	Token oldData = env.eval(argv[1]);
	string oldType = getType(oldData);
	if(!oldType.length || oldType !in env.conversions) {
		throw new OratrInvalidConversionFromException(oldType);
	}
	if(!newType.str.length || newType.str !in env.conversions[oldType]) {
		throw new OratrInvalidConversionToException(newType.str);
	}
	return env.conversions[oldType][newType.str](oldData);
}
