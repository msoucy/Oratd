import environment;
import token;
import tokenize;
import errors;
import system;
import bi_math;

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
	string buf;
	while(buf != "exit") {
		dout.writef("==> "c);
		buf = to!string(din.readLine());
		try {
			printTokens(tokenize.tokenize(buf,din),0);
		} catch(OratrParseException e) {
			dout.writef("%s\n", e.msg);
		} catch(Throwable e) {
			dout.writef("%s\n", e.msg);
		}
	}
	return;
}