all:
	flex lexer.l && bison -d parser.y && gcc -o parser parser.tab.c -lfl && ./parser yaml_test.yml
