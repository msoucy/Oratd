import environment;
import token;
import tokenize;
import errors;
import system;
import parse;
import bi_init;

import std.stdio;
import std.string;
import std.algorithm;
import std.cstream;
import std.process;
import std.file : getcwd;
version(Posix) import std.path : absolutePath, dirName, buildNormalizedPath;

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

void main(string[] argv)
{
	environment.Environment env;
	env.init();
	{
		// Add the important locations to the path
		env.scopes[0]["__path__"] = Token().withType(Token.VarType.tArray);
		env.scopes[0]["__path__"].arr ~= Token(getcwd()).withType(Token.VarType.tString);
		version(Posix) {
			// Get the directory of the program
			// This will probably fail for symlinks, but std.path.readLink is erroring for me
			auto execPath = absolutePath(argv[0]);
			auto pathTok = Token(buildNormalizedPath(dirName(execPath),"include"));
			env.scopes[0]["__path__"].arr ~= pathTok;
			env.scopes[0]["__include__"] = pathTok;
		}
	}
	env.scopes[0]["__name__"] = Token("__init__");
	init_builtins(env);
	try {
		Token[] tempargs = [Token("source").withType(Token.VarType.tVarname),
							Token("~/.oratrc")];
		parse.parse(tempargs,env);
	} catch(OratrMissingFileException e) {
		// Do nothing, they just don't have an oratrc file
	}
	env.scopes[0]["__name__"] = Token("__main__");
	string buf;
	while(1) {
		dout.writef(env.evalVarname("__prompt__").str);
		buf = cast(string)din.readLine();
		try {
			auto toks = tokenize.tokenize(buf,din);
			parse.parse(toks,env);
		} catch(OratrBaseException e) {
			dout.writef("%s\n", e.msg);
		}
	}
}