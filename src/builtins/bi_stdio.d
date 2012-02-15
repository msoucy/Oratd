import token;
import tokenize;
import environment;
import errors;
import dictionary;
import std.cstream;
import std.string;

void import_stdio(ref Environment env) {
	// I/O
	mixin(AddFunc!"echo");
	mixin(AddFunc!"print");
	mixin(AddFunc!"echo");
	mixin(AddFunc!"get");
	mixin(AddFunc!"getch");
	
	env.scopes[0]["__endl__"] = Token("\n");
	env.scopes[0]["__tab__"] = Token("\t");
}

string makeString(ref Token tok, ref Environment env)
{
	string ret;
	switch(tok.type) {
		case Token.VarType.tNumeric: {
			ret = format("%s",tok.d);
			break;
		}
		case Token.VarType.tOpcode:
		case Token.VarType.tString:
		case Token.VarType.tTypeID:
		case Token.VarType.tSpecial: {
			ret = tok.str;
			break;
		}
		case Token.VarType.tArray: {
			ret = "[";
			foreach(i,arg;tok.arr) {
				if(arg.type == Token.VarType.tString) {
					ret ~= '"'~tokenize.unevalStr(arg.str)~'"';
				} else {
					ret ~= makeString(arg,env);
				}
				if(i != tok.arr.length-1) {
					ret ~= ", ";
				}
			}
			ret ~= "]";
			break;
		}
		case Token.VarType.tDictionary: {
			ret = "[|";
			auto d = Dictionary(tok);
			foreach(i,key,val;d) {
				ret ~= key ~ ":" ~ makeString(val,env);
				if(i != d.length-1) {
					ret ~= ", ";
				}
			}
			ret ~= "|]";
			break;
		}
		case Token.VarType.tType: {
			ret = format("<type \"%s\">", tok.str);
			break;
		}
		case Token.VarType.tVarname: {
			ret = format("<variable \"%s\">", tok.str);
			break;
		}
		case Token.VarType.tBuiltin: {
			ret = format("<built-in function \"%s\">", tok.str);
			break;
		}
		case Token.VarType.tRawArray:
		case Token.VarType.tRecast:
		case Token.VarType.tClosingParen:
		case Token.VarType.tClosingBrace:
		case Token.VarType.tClosingBracket:
		case Token.VarType.tCommandSeperator:
		case Token.VarType.tArrayElementSeperator:
		case Token.VarType.tVarOffsetSeperator: {
			// OK, how the heck did they GET one of these to print?
			ret = "<special token \""~vartypeToStr(tok.type)~"\">";
			break;
		}
		case Token.VarType.tCompoundStatement:
			ret = format("(argument list)");
			break;
		case Token.VarType.tCode:
			ret = format("<code>");
			break;
		case Token.VarType.tFunction:
		case Token.VarType.tVariadicFunction:
			ret = format("<function>");
			break;
		case Token.VarType.tNone:
			ret = format("<none>");
			break;
		default:
			ret = format("<invalid token>");
			break;
	}
	return ret;
}

Token _bi_printto(ref Token[] argv, ref Environment env, OutputStream ostr)
{
	Token retval;
	foreach(ref ret;argv) {
		// Crashes below
		ret = env.eval(ret);
		ostr.writef("%s", makeString(ret,env));
		retval = ret;
	}
	return retval;
}

Token bi_echo(ref Token[] argv, ref Environment env)
{
	return _bi_printto(argv,env,dout);
}

Token bi_print(ref Token[] argv, ref Environment env)
{
	Token ret = bi_echo(argv,env);
	if (argv.length) {
		dout.writef("\n");
	}
	return ret;
}

Token bi_get(ref Token[] argv, ref Environment env)
{
	Token ret;
	if(argv.length) {
		throw new OratrArgumentCountException(argv.length,"get","0");
	}
	char[] str;
	do{
		str = din.readLine();
	}while(str=="");
	ret = Token(cast(string)str);
	return ret;
}

Token bi_getch(ref Token[] argv, ref Environment env)
{
	if(argv.length) {
		throw new OratrArgumentCountException(argv.length,"getch","0");
	}
	char ch = din.getc();
	return Token(ch~"");
}