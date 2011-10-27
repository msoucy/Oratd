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
	import_math(env);
	import_system(env);
	import_files(env);
}
