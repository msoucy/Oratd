import environment;
import token;
import tokenize;
import errors;
import system;
import parse;
import bi_init;

import std.stdio;
import std.algorithm;
import std.cstream;
import std.conv;

void printTokens(Token[] t, int s) {
	foreach(tok;t) {
		for(int i=0;i<s;i++) {
			dout.writef("  ");
		}
		if(tok.str != "") {
			dout.writef("%s\n", tok.str);
		} else {
			printTokens(tok.arr,s+1);
		}
	}
}

void main()
{
	Environment env;
	env.init();
	init_builtins(env);
	{
		Token tmp = "a";
		tmp.type = Token.VarType.tVarname;
		env.eval(tmp).arr.length = 3;
		env.eval(tmp).type = Token.VarType.tArray;
		env.eval(tmp).arr[0].d = 9;
		env.eval(tmp).arr[0].type = Token.VarType.tNumeric;
		env.eval(tmp).arr[1].d = 3;
		env.eval(tmp).arr[1].type = Token.VarType.tNumeric;
		env.eval(tmp).arr[2].d = 2;
		env.eval(tmp).arr[2].type = Token.VarType.tNumeric;
	}
	string buf;
	while(buf != "exit") {
		dout.writef("==> "c);
		buf = to!string(din.readLine());
		try {
			auto toks = tokenize.tokenize(buf,din);
			parse.parse(toks,env);
		} catch(OratrBaseException e) {
			dout.writef("%s\n", e.msg);
		}/* catch(Throwable e) {
			dout.writef("%s\n", e.msg);
		}/**/
	}
	return;
}