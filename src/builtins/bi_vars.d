import token;
import environment;
import errors;
import parse;
import bi_math;
import std.cstream;

Token bi_set(ref Token[] argv, ref Environment env)
{
	Token ret;
	if(argv.length<3) {
		throw new OratrArgumentCountException(0,"set","at least 3");
	}
	if(argv[0].type != Token.VarType.tVarname) {
		throw new OratrInvalidArgumentException(vartypeToStr(argv[0].type),0);
	}
	if(argv[1].type != Token.VarType.tOpcode) {
		throw new OratrInvalidArgumentException(vartypeToStr(argv[1].type),1);
	}
	Token *orig = env.evalVarname(argv[0].str);
	if(argv.length == 3) {
		ret = argv[2];
		ret = env.eval(ret);
	} else {
		parse.parse(argv[2..$], env);
		ret = *env.evalVarname("__return__");
	}
	if(argv[1].str[0..$-1] == "") {
		*orig = ret;
	} else {
		Token[] args;
		args ~= *orig;
		args ~= Token(argv[1].str[0..$-1]);
		args[$-1].type = Token.VarType.tOpcode;
		args ~= ret;
		parse.parse(args, env);
		*orig = *env.evalVarname("__return__");
	}
	return ret;
}