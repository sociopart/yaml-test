%{
#include <stdio.h>
extern int yylex();
extern int yylineno;
extern char* yytext;
extern FILE* yyin;

void yyerror(const char* message) {
    fprintf(stderr, "Parser error at line %d: %s\n", yylineno, message);

#define PRS_DBG
#ifdef PRS_DBG
  #define PRS_PRINTF(pargs)    printf pargs
#else
  #define PRS_PRINTF(pargs)    (void)(0)
#endif
}

int indent_level = 0;
int object_need_resolve = 0;
%}

%define parse.trace
%define api.pure full
%define api.push-pull push

%token TOK_YAML1_BLOCK_START TOK_YAML1_BLOCK_END
%token TOK_YAML1_INDENT TOK_YAML1_DEDENT
%token TOK_YAML1_NULL TOK_YAML1_TRUE TOK_YAML1_FALSE
%token TOK_YAML1_DASH TOK_YAML1_COLON TOK_YAML1_NEWLINE TOK_YAML1_KEY BLOCK_END
%token TOK_YAML1_STRING TOK_YAML1_NUMBER
%token TOK_YAML1_OBJ_START TOK_YAML1_ARR_START

%start yaml
%%

yaml: element

element: value

value: object | array
  | TOK_YAML1_STRING
  | TOK_YAML1_NUMBER
  | TOK_YAML1_NULL

object: TOK_YAML1_OBJ_START TOK_YAML1_DEDENT
| TOK_YAML1_OBJ_START members TOK_YAML1_DEDENT

members: member | member TOK_YAML1_NEWLINE members

member: TOK_YAML1_KEY TOK_YAML1_COLON element // ???

array: TOK_YAML1_ARR_START TOK_YAML1_DEDENT
| TOK_YAML1_ARR_START elements TOK_YAML1_DEDENT

elements: element | element TOK_YAML1_NEWLINE elements


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
