all: clean main
clean:
	rm -rf lex.yy.c parser.tab.c parser.tab.h flex-output.txt parser
main:
	flex lexer.l && bison -d parser.y && gcc -o parser parser.tab.c lex.yy.c -lfl 
	./parser yaml_test.yml > flex-output.txt
