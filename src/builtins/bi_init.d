import environment;
import bi_basics;
import bi_math;
import bi_stdio;
import bi_vars;
import bi_system;
import bi_files;

void init_builtins(ref Environment env) {
	import_basics(env);
	import_stdio(env);
	import_varops(env);
	import_manipulations(env);
	import_math(env);
	import_system(env);
	import_imports(env);
}

void function(ref Environment)[string] createImports() {
	void function(ref Environment)[string] ret;
	ret["bi_flow"] = &import_basics;
	ret["bi_stdio"] = &import_stdio;
	ret["bi_varops"] = &import_varops;
	ret["bi_manipulations"] = &import_manipulations;
	ret["bi_math"] = &import_math;
	ret["bi_system"] = &import_system;
	ret["bi_imports"] = &import_imports;
	return ret;
}