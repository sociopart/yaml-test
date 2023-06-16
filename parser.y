%{
#include <stdio.h>
extern int yylex();
extern int yylineno;
extern char* yytext;
extern FILE* yyin;

void yyerror(const char* message) {
    fprintf(stderr, "Parser error at line %d: %s\n", yylineno, message);
}

int indent_level = 0;
%}

%define parse.trace
%define api.pure full
%define api.push-pull push

%token TOK_YAML1_BLOCK_START TOK_YAML1_BLOCK_END
%token TOK_YAML1_INDENT TOK_YAML1_DEDENT
%token TOK_YAML1_NULL TOK_YAML1_TRUE TOK_YAML1_FALSE
%token TOK_YAML1_DASH TOK_YAML1_COLON TOK_YAML1_NEWLINE TOK_YAML1_KEY BLOCK_END
%token TOK_YAML1_STR TOK_YAML1_INT TOK_YAML1_FLOAT 

%start start

%%

start:
    | start statement { printf("--Start of new statement--\n"); }
    ;

statement:
    TOK_YAML1_BLOCK_START { printf("Token: TOK_YAML1_BLOCK_START\n"); }
    | TOK_YAML1_BLOCK_END { printf("Token: TOK_YAML1_BLOCK_END\n"); }
    | TOK_YAML1_DASH { printf("Token: TOK_YAML1_DASH\n"); }
    | TOK_YAML1_COLON { printf("Token: TOK_YAML1_COLON\n"); }
    | TOK_YAML1_NULL { printf("Token: TOK_YAML1_NULL\n"); }
    | TOK_YAML1_TRUE { printf("Token: TOK_YAML1_TRUE\n"); }
    | TOK_YAML1_FALSE { printf("Token: TOK_YAML1_FALSE\n"); }
    | TOK_YAML1_STR { printf("Token: TOK_YAML1_STR\n"); }
    | TOK_YAML1_INT { printf("Token: TOK_YAML1_INT\n"); }
    | TOK_YAML1_FLOAT { printf("Token: TOK_YAML1_FLOAT\n"); }
    | TOK_YAML1_NEWLINE { printf("Token: TOK_YAML1_NEWLINE\n"); }
    | TOK_YAML1_KEY { printf("Token: TOK_YAML1_KEY\n"); }
    | TOK_YAML1_INDENT { printf("Token: TOK_YAML1_INDENT\n"); }
    | TOK_YAML1_DEDENT { printf("Token: TOK_YAML1_DEDENT\n"); }
    ;

%%

int main() {

  FILE* input_file = fopen("yaml_test.yml", "r");
  if (!input_file) {
    fprintf(stderr, "Failed to open input file\n");
    return 1;
  }
  yyin = input_file;
  while (yylex());
  fclose(input_file);
  return 0;
}
