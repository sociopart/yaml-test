%{
#include <stdio.h>
extern int yylex();
extern int yylineno;
extern char* yytext;
extern FILE* yyin;

//#define PRS_DBG
#ifdef PRS_DBG
  #define PRS_PRINTF(pargs)    printf pargs
#else
  #define PRS_PRINTF(pargs)    (void)(0)
#endif

void yyerror(const char* message) {
    fprintf(stderr, "Parser error at line %d: %s\n", yylineno, message);
}

int indent_level = 0;
%}
%union {
  char* str_val;
}
%defines
%define parse.trace
%define api.pure full
%define api.push-pull push

%token TOK_YAML1_BLOCK_START TOK_YAML1_BLOCK_END
%token TOK_YAML1_INDENT TOK_YAML1_DEDENT
%token TOK_YAML1_NULL TOK_YAML1_TRUE TOK_YAML1_FALSE
%token TOK_YAML1_DASH TOK_YAML1_COLON TOK_YAML1_NEWLINE TOK_YAML1_KEY BLOCK_END
%token TOK_YAML1_STRING TOK_YAML1_NUMBER 

%start yaml

%%

yaml: TOK_YAML1_BLOCK_START element TOK_YAML1_BLOCK_END {PRS_PRINTF(("YS-EL-YE\n"));}
    | TOK_YAML1_BLOCK_START element {PRS_PRINTF(("YS-EL\n"));}
    | element TOK_YAML1_BLOCK_END {PRS_PRINTF(("EL-YE\n"));}
    | element {PRS_PRINTF(("EL-ONLY\n"));}

element: value

value: mapping {PRS_PRINTF(("MAPPING found %s\n", yytext));}
       | sequence {PRS_PRINTF(("SEQUENCE found %s\n", yytext));}
       | TOK_YAML1_STRING {PRS_PRINTF(("STRING found %s\n", yytext));}
       | TOK_YAML1_NUMBER {PRS_PRINTF(("NUMBER found %s\n", yytext));}
       | TOK_YAML1_NULL   {PRS_PRINTF(("NULL found\n"));}

mapping: TOK_YAML1_INDENT TOK_YAML1_KEY value {PRS_PRINTF(("MAPPING found\n"));}
       | TOK_YAML1_INDENT TOK_YAML1_KEY mapping {PRS_PRINTF(("MAPPING found\n"));}
       | TOK_YAML1_INDENT TOK_YAML1_KEY sequence {PRS_PRINTF(("MAPPING found\n"));}

sequence: TOK_YAML1_INDENT TOK_YAML1_DASH value {PRS_PRINTF(("SEQUENCE found\n"));}
        | TOK_YAML1_INDENT TOK_YAML1_DASH mapping {PRS_PRINTF(("SEQUENCE found\n"));}
        | TOK_YAML1_INDENT TOK_YAML1_DASH sequence {PRS_PRINTF(("SEQUENCE found\n"));}

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
