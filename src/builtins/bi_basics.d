import token;
import environment;
import errors;
import std.cstream;
import std.string;
import core.stdc.stdlib : exit;

void import_basics(ref Environment env) {
	// Basic constructs and functions
	mixin(AddFunc!("null"));
	mixin(AddFunc!("about"));
	mixin(AddFunc!("exit"));
}

Token bi_null(ref Token[] argv, ref Environment env) {
	Token ret = "__return__";
	ret.type=Token.VarType.tVarname;
	ret = env.eval(ret);
	return ret;
}

Token bi_exit(ref Token[] argv, ref Environment env) {
	exit(0);
	assert(0);
}

Token bi_about(ref Token[] argv, ref Environment env)
{
	string name = "Oratd";
	Token[] dev; {
		dev ~= Token("demosthenes2k8");
		dev ~= Token("bot190");
		dev ~= Token("dysxqer");
		dev ~= Token("cgcat93");
		dev ~= Token("asterios");
	}
	string or_version = "20111020-dev";
	
	Token ret;
	if(argv.length>1) {
		throw new OratrArgumentCountException(argv.length,"about","0-1");
	}
	if(argv.length==0) {
		dout.writef("\t\t+------------------+\n"~
					"\t\t|      ORATR       |\n"~
					"\t\t+------------------+\n");
		dout.writef("\thttp://oratr.googlecode.com\n"~
					"\thttp://demosthenes2k8.endoftheinternet.org/oratr/\n"~
					"Implementation:\n"~
					"\tName: " ~ name ~ "\n"~
					"\tVersion: " ~ or_version ~ "\n");
		static if(0) {
			dout.writef("Developers:\n");
			foreach(d;dev) {
				dout.writef("\t%s\n",d.str);
			}
		}
		ret = Token("");
	} else {
		string dat = argv[0].str;
		ret.type=Token.VarType.tString;
		switch(toLower(dat)) {
		case "name":
		case "oratr":
		case "implementation":
			ret = Token(name);
			break;
		case "dev":
		case "devs":
		case "developer":
		case "developers":
			ret.type = Token.VarType.tArray;
			ret.str = "";
			ret.arr = dev;
			break;
		case "version":
			ret = Token(or_version);
			break;
		default:
			throw new OratrInvalidArgumentException(dat,0);
		}
	}
	return ret;
}
