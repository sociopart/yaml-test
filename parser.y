%{
#include <stdio.h>
#include "lex.yy.c"
extern int yylex();
extern int yylineno;
extern char* yytext;

void yyerror(const char* message) {
    fprintf(stderr, "Parser error at line %d: %s\n", yylineno, message);
}

int indent_level = 0;

%}

%token TOK_YAML1_BLOCK_START TOK_YAML1_BLOCK_END
%token TOK_YAML1_INDENT TOK_YAML1_DEDENT
%token TOK_YAML1_NULL TOK_YAML1_TRUE TOK_YAML1_FALSE
%token TOK_YAML1_DASH TOK_YAML1_COLON TOK_YAML1_NEWLINE TOK_YAML1_KEY BLOCK_END
%token TOK_YAML1_STR TOK_YAML1_INT TOK_YAML1_FLOAT 

%%
start: TOK_YAML1_BLOCK_START document TOK_YAML1_BLOCK_END { printf("Parsing complete.\n"); }
      | document TOK_YAML1_BLOCK_END { printf("Parsing complete.\n"); }
     ;

document: block { printf("Document parsed.\n"); }
        ;

block: sequence { printf("Block is a sequence.\n"); }
     | mapping { printf("Block is a mapping.\n"); }
     ;

sequence: TOK_YAML1_DASH items { printf("Sequence item.\n"); }
        ;

items: item { printf("Items parsed.\n"); }
     | items item { printf("Items parsed.\n"); }
     ;

item: block { printf("Item is a block.\n"); }
    | TOK_YAML1_STR { printf("Item is a string value: %s\n", $1); }
    | TOK_YAML1_INT { printf("Item is an integer value: %s\n", $1); }
    | TOK_YAML1_FLOAT { printf("Item is a float value: %s\n", $1); }
    ;

mapping: TOK_YAML1_KEY TOK_YAML1_COLON block { printf("Mapping key: %s\n", $1); }
       ;

block: TOK_YAML1_INDENT sequence TOK_YAML1_DEDENT { printf("Nested block with sequence.\n"); }
     | TOK_YAML1_INDENT mapping TOK_YAML1_DEDENT { printf("Nested block with mapping.\n"); }
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
