import token;
import environment;
import errors;
import std.process : getenv;

void import_system(ref Environment env) {
	// Janky but accurate way to get the info about the os
	// I could use std.sys, but this happens at COMPILE time
	mixin(AddFunc!("getenv"));
	env.scopes[0]["__system__"] = Token().withArray(3);
	
	version(Win32) env.scopes[0]["__system__"].arr[0] = Token("Win32");
	else version(Win64) env.scopes[0]["__system__"].arr[0] = Token("Win64");
	else version(linux) env.scopes[0]["__system__"].arr[0] = Token("Linux");
	else version(OSX) env.scopes[0]["__system__"].arr[0] = Token("OSX");
	else version(FreeBSD) env.scopes[0]["__system__"].arr[0] = Token("FreeBSD");
	else version(Solaris) env.scopes[0]["__system__"].arr[0] = Token("Solaris");
	else env.scopes[0]["__system__"].arr[0] = Token("UnknownOS");
	
	version(LittleEndian) env.scopes[0]["__system__"].arr[1] = Token("LittleEndian");
	else version(BigEndian) env.scopes[0]["__system__"].arr[1] = Token("BigEndian");
	else env.scopes[0]["__system__"].arr[1] = Token("UnknownEndianness");
	
	version(X86) env.scopes[0]["__system__"].arr[2] = Token("x86");
	else version(X86_64) env.scopes[0]["__system__"].arr[2] = Token("x64");
	else env.scopes[0]["__system__"].arr[2] = Token("UnknownArchitecture");
}

Token bi_getenv(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"getenv","1");
	}
	Token envstr = argv[0];
	envstr = env.eval(envstr);
	if(envstr.type != Token.VarType.tString) {
		throw new OratrInvalidArgumentException(vartypeToStr(envstr.type),0);
	}
	envstr.str = getenv(envstr.str);
	envstr.type = Token.VarType.tString;
	return envstr;
}
