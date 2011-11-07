import environment;
import parse;
import tokenize;
import token;
import errors;
import system;
import bi_init;

import std.cstream;
import std.path;
import std.file;

void import_imports(ref Environment env) {
	mixin(AddFunc!("run"));
	mixin(AddFunc!("source"));
}

Token _bi_run_code(ref Token[] argv, ref Environment env, string name, bool scopeIn)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,name,"1");
	}
	InputStream parsetest;
	if(argv[0].type != Token.VarType.tString) {
		throw new OratrInvalidArgumentException(vartypeToStr(argv[0].type),0);
	}
	string filename = expandTilde(argv[0].str);
	void function(ref Environment)[string] funcs = createImports();
	if(filename in funcs) {
		funcs[filename](env);
		return *env.evalVarname("__return__");
	} else if(isAbsolute(filename)) {
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
	if(scopeIn) env.inscope();
	string full="";
	do {
		full = cast(string)parsetest.readLine();
		try {
			auto args = tokenize.tokenize(full,parsetest);
			parse.parse(args,env);
		} catch(OratrBaseException e) {
			dout.writef("%s\n", e.msg);
		}
	} while(!parsetest.eof());
	if(scopeIn) env.outscope();
	delete parsetest;
	return *env.evalVarname("__return__");
}

Token bi_run(ref Token[] argv, ref Environment env)
{
	return _bi_run_code(argv,env,"run",1);
}

Token bi_source(ref Token[] argv, ref Environment env)
{
	return _bi_run_code(argv,env,"source",0);
}