// DMD: http://www.digitalmars.com/d/
// GDC: http://dgcc.sourceforge.net/

private import std.stdio, std.process, std.c.stdlib, std.path, std.file, std.string;

int main(char[][] args) {
	if (args.length < 2) {
		throw(new Exception("Se debe indicar el nombre del proyecto a ejecutar"));
	}

	char[][] files;
	char[] projectpath, name = args[1];

	chdir(getDirName(args[0]));

	if (!exists(projectpath = format("projects\\%s", name))) {
		throw(new Exception(format("No existe el proyecto '%s'", name)));
	}

	char[] newpath = format("%s\\dll;%s", toString(getenv("PATH")), getcwd());
	//setenv("PATH", toStringz(newpath), 1);
	//printf("%s", toStringz(newpath));

	//return 0;

	//setenv("PATH", getenv() ~ ";", true);

	chdir(projectpath);

	char[] gamelibc;
	char[] projectc;

	foreach (fname; listdir("..\\..\\gamelib", "*.c")) files ~= fname;
	foreach (fname; listdir("src", "*.c")) files ~= fname;

	//char[] command = " -lopengl32 -lglu32 -lglut32 " ~ std.string.join(files, " ") ~ " -run ..\\..\\tcc\\void.c";
	//..\\..\\tcc\\tcc.exe

	char[][] params = [
		"-Isrc",
		"-I..\\..\\gamelib",
		"-I..\\..\\tcc\\include",
		"-L..\\..\\tcc\\lib",
		"-lsdl",
		"-lsdl_image",
		"-lsdl_mixer",
		"-lsdl_ttf",
		"-lsdl_net",
		"-lopengl32",
		"-lglu32",
		"-lglut32"
	];

	foreach (file; files) params ~= "\"" ~ file ~ "\"";

	params ~= "-run";
	params ~= "..\\..\\tcc\\void.c";

	write("run.bat", std.string.format("@echo off\r\nPATH=%%PATH%%;%%CD%%\\..\\..\\dll;\r\n..\\..\\tcc\\tcc.exe %s", std.string.join(params, " ")));
	//printf("%s", toStringz(cast(char[])read("run.bat")));
	std.process.system("run.bat");
	unlink("run.bat");

	//std.process.execvp("..\\..\\tcc\\tcc.exe", params);

	//writefln(command);

	//system(toStringz(command));

	//tcc\tcc.exe -Isrc -lsdl -lsdl_image -lsdl_mixer -lsdl_ttf -lsdl_net -lopengl32 -lglu32 -lglut32 src\gamelib.c %1 src\main.c -o oproject.exe

	return 0;
}