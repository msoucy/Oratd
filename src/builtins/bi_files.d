import environment;
import parse;
import tokenize;
import token;
import errors;
import system;

import std.cstream;
import std.path;
import std.file;

void import_files(ref Environment env) {
	// Basic constructs and functions
	mixin(AddFunc!("run"));
}

Token bi_run(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"run","1");
	}
	InputStream parsetest;
	if(argv[0].type != Token.VarType.tVarname) {
		throw new OratrInvalidArgumentException(vartypeToStr(argv[0].type),0);
	}
	string filename = expandTilde(argv[0].str);
	if(isAbsolute(filename)) {
		parsetest = new File(filename, FileMode.In);
		if(!parsetest.isOpen()) {
			delete parsetest;
			defaultExtension(filename,FILEXT);
			parsetest = new File(filename, FileMode.In);
		}
	} else {
		foreach(ref p;env.evalVarname("__path__").arr) {
			auto path = absolutePath(filename,p.str);
			if(isFile(path)) {
				parsetest = new File(path,FileMode.In);
				break;
			} else if(isFile(defaultExtension(path,FILEXT))) {
				parsetest = new File(defaultExtension(path,FILEXT));
			}
		}
	}
	if(!parsetest.isOpen()) {
		throw new OratrMissingFileException(filename);
	}
	env.inscope();
	string full="";
	do{
		full = cast(string)parsetest.readLine();
		try {
			auto args = tokenize.tokenize(full,parsetest);
			parse.parse(args,env);
		} catch(OratrBaseException e) {
			dout.writef("%s\n", e.msg);
		}
	}while(!parsetest.eof());
	env.outscope();
	delete parsetest;
	return *env.evalVarname("__return__");
}