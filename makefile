parser: lex.yy.c y.tab.c
	gcc -o parser lex.yy.c y.tab.c -lfl
scanner: lex.yy.c
	gcc -o scanner lex.yy.c -lfl
lex.yy.c: scanner.l
	flex scanner.l
y.tab.c: hw2.y
	byacc -d hw2.y
clean:
	rm lex.yy.c y.tab.c y.tab.h
