%{
#include <stdio.h>
extern int yylex();
extern int yylineno;
extern char* yytext;
extern FILE* yyin;
#define YYDEBUG 1
void yyerror(const char* message) {
    fprintf(stderr, "Parser error at line %d: %s\n", yylineno, message);
}
#define PRS_DBG
#ifdef PRS_DBG
  #define PRS_PRINTF(pargs)    printf pargs
#else
  #define PRS_PRINTF(pargs)    (void)(0)
#endif
%}

%define parse.trace
%define api.pure full
%define api.push-pull push

%token TOK_YAML1_BLOCK_START TOK_YAML1_BLOCK_END
%token TOK_YAML1_COLON TOK_YAML1_NEWLINE
%token TOK_YAML1_NULL TOK_YAML1_STRING TOK_YAML1_NUMBER
%token TOK_YAML1_OBJ_START TOK_YAML1_OBJ_END
%token TOK_YAML1_ARR_START TOK_YAML1_ARR_END

%start yaml1

%% /* The grammar follows.  */

yaml1: TOK_YAML1_BLOCK_START element TOK_YAML1_BLOCK_END {printf("YAML parsed.\n");}
    | TOK_YAML1_BLOCK_END element {printf("YAML parsed.\n");}
    | element TOK_YAML1_BLOCK_END {printf("YAML parsed.\n");}
    | element {printf("YAML parsed.\n");}

element: value

value: object { printf("Parsed object.\n"); }
     | array { printf("Parsed array.\n"); }
     | TOK_YAML1_STRING { printf("Parsed string: %s\n", yytext); }
     | TOK_YAML1_NUMBER { printf("Parsed number: %s\n", yytext); }
     | TOK_YAML1_NULL { printf("Parsed null.\n"); }

object: TOK_YAML1_OBJ_START TOK_YAML1_OBJ_END { printf("Parsed empty object.\n"); }
      | TOK_YAML1_OBJ_START members TOK_YAML1_OBJ_END { printf("Parsed object with members.\n"); }

members: member { printf("Parsed member.\n"); }
       | members TOK_YAML1_NEWLINE member { printf("Parsed member.\n"); }

member: TOK_YAML1_STRING TOK_YAML1_COLON element { printf("Parsed key-value pair: %s\n", yytext); }

array: TOK_YAML1_ARR_START TOK_YAML1_ARR_END { printf("Parsed empty array.\n"); }
     | TOK_YAML1_ARR_START elements TOK_YAML1_ARR_END { printf("Parsed array with elements.\n"); }

elements: element { printf("Parsed array element.\n"); }
        | elements TOK_YAML1_NEWLINE element { printf("Parsed array element.\n"); }

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
