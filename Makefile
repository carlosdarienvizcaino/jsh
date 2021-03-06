all: y.tab.o lex.yy.o main.o queue.o utils.o env.o aliastable.o builtins.o ast.o
	cc lex.yy.o y.tab.o main.o queue.o utils.o env.o aliastable.o builtins.o ast.o -o main -g

y.tab.h: ast.h defines.h grammar.y
	yacc -dv grammar.y

y.tab.c: ast.h defines.h grammar.y
	yacc -dv grammar.y

y.tab.o: y.tab.h y.tab.c
	cc -c y.tab.c -g

lex.yy.c: ast.h env.h y.tab.h lexxer.l
	lex lexxer.l

lex.yy.o: lex.yy.c
	cc -c lex.yy.c -g

builtins.o: defines.h utils.h aliastable.h env.h builtins.h builtins.c
	cc -c builtins.c -g

queue.o: queue.h queue.c
	cc -c queue.c -g

ast.o: defines.h builtins.h queue.h utils.h ast.h ast.c
	cc -c ast.c -g

aliastable.o: defines.h aliastable.h aliastable.c
	cc -c aliastable.c -g

env.o: defines.h env.h env.c
	cc -c env.c -g

utils.o: defines.h utils.h utils.c
	cc -c utils.c -g

main.o: ast.h defines.h utils.h main.c
	cc -c main.c -g

clean:
	rm -rf lex.yy.c y.tab.c y.tab.h main *.o *.output *.gch
