all: clean main
clean:
	rm -rf lex.yy.c parser.tab.c parser.tab.h
main:
	flex lexer.l && bison -d parser.y && gcc -o parser parser.tab.c -lfl 
	./parser yaml_test.yml > flex-output.txt
