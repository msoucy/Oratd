import token;
import environment;

void import_system(ref Environment env) {
	// Janky but accurate way to get the info about the os
	// I could use std.sys, but this happens at COMPILE time
	env.scopes[0]["SYSTEM"] = Token().withArray(3);
	
	version(Win32) env.scopes[0]["SYSTEM"].arr[0] = Token("Win32");
	else version(Win64) env.scopes[0]["SYSTEM"].arr[0] = Token("Win64");
	else version(linux) env.scopes[0]["SYSTEM"].arr[0] = Token("Linux");
	else version(OSX) env.scopes[0]["SYSTEM"].arr[0] = Token("OSX");
	else version(FreeBSD) env.scopes[0]["SYSTEM"].arr[0] = Token("FreeBSD");
	else version(Solaris) env.scopes[0]["SYSTEM"].arr[0] = Token("Solaris");
	else env.scopes[0]["SYSTEM"].arr[0] = Token("UnknownOS");
	
	version(LittleEndian) env.scopes[0]["SYSTEM"].arr[1] = Token("LittleEndian");
	else version(BigEndian) env.scopes[0]["SYSTEM"].arr[1] = Token("BigEndian");
	else env.scopes[0]["SYSTEM"].arr[1] = Token("UnknownEndianness");
	
	version(X86) env.scopes[0]["SYSTEM"].arr[2] = Token("x86");
	else version(X86_64) env.scopes[0]["SYSTEM"].arr[2] = Token("x64");
	else env.scopes[0]["SYSTEM"].arr[2] = Token("UnknownArchitecture");
}
