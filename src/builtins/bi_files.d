import environment;
import parse;
import tokenize;
import token;
import errors;
import system;
import bi_init;
import dictionary;

import std.cstream;
import std.path;
import std.file;

void import_imports(ref Environment env) {
	mixin(AddFunc!"import");
	mixin(AddFunc!"run");
	mixin(AddFunc!"source");
}

Token _bi_run_code(ref Token[] argv, ref Environment env, string name, ushort scopeIn)
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
		if(exists(filename) && isFile(filename)) {
			parsetest = new File(filename, FileMode.In);
		} else {
			filename = defaultExtension(filename,FILEXT);
			if(exists(filename) && isFile(filename)) {
				parsetest = new File(filename, FileMode.In);
			}
		}
		if(!parsetest.isOpen()) {
			delete parsetest;
		}
	} else {
		foreach(ref p;env.evalVarname("__path__").arr) {
			auto path = absolutePath(filename,p.str);
			if(exists(path) && isFile(path)) {
				parsetest = new File(path,FileMode.In);
				break;
			} else {
				path = defaultExtension(path,FILEXT);
				if(exists(path) && isFile(path)) {
					parsetest = new File(path, FileMode.In);
					break;
				}
			}
		}
	}
	if(!parsetest || !parsetest.isOpen()) {
		throw new OratrMissingFileException(filename);
	}
	if(scopeIn) {
		env.inscope();
	}
	string oldName = env.evalVarname("__name__").str;
	if(oldName != "__init__") env.evalVarname("__name__").str = baseName(filename, FILEXT);
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
	env.evalVarname("__name__").str = oldName;
	if(scopeIn) {
		if(scopeIn >= 2) {
			auto lastScope = env.scopes[$-1];
			env.outscope();
			*env.evalVarname(baseName(filename, FILEXT)) = Token().withType(Token.VarType.tDictionary);
			// Turn the variables into a Module
			auto mod = Dictionary(*env.evalVarname(baseName(filename,FILEXT)));
			foreach(string index, ref var;lastScope) {
				mod[index] = var;
			}
			*env.evalVarname(baseName(filename, FILEXT)) = *mod._tok;
		} else {
			env.outscope();
		}
	}
	delete parsetest;
	return *env.evalVarname("__return__");
}

Token bi_import(ref Token[] argv, ref Environment env)
{
	return _bi_run_code(argv,env,"import",2);
}

Token bi_run(ref Token[] argv, ref Environment env)
{
	return _bi_run_code(argv,env,"run",1);
}

Token bi_source(ref Token[] argv, ref Environment env)
{
	return _bi_run_code(argv,env,"source",0);
}