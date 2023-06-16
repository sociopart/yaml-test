%{
#include <stdio.h>
extern int yylex();
extern int yylineno;
extern char* yytext;
extern FILE* yyin;

void yyerror(const char* message) {
    fprintf(stderr, "Parser error at line %d: %s\n", yylineno, message);
}
#define PRS_DBG
#ifdef PRS_DBG
  #define PRS_PRINTF(pargs)    printf pargs
#else
  #define PRS_PRINTF(pargs)    (void)(0)
#endif
void output_token(const char* nonTerminal, const char* tokenType, const char* value) {
    printf("Non-terminal: %s, Token type: %s, Value: %s\n", nonTerminal, tokenType, value);
}

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
%token TOK_YAML1_OBJ_END TOK_YAML1_ARR_END

%start yaml1

%% /* The grammar follows.  */

yaml1: element { printf("Parsing completed successfully.\n"); }

element: value

value: object { printf("Parsed object.\n"); }
     | array { printf("Parsed array.\n"); }
     | TOK_YAML1_STRING { printf("Parsed string: %s\n", yytext); }
     | TOK_YAML1_NUMBER { printf("Parsed number: %s\n", yytext); }
     | TOK_YAML1_NULL { printf("Parsed null.\n"); }

object: TOK_YAML1_OBJ_START TOK_YAML1_OBJ_END { printf("Parsed empty object.\n"); }
      | TOK_YAML1_OBJ_START members TOK_YAML1_OBJ_END { printf("Parsed object with members.\n"); }

members: member TOK_YAML1_NEWLINE { printf("Parsed member.\n"); }
       | member TOK_YAML1_NEWLINE members { printf("Parsed member.\n"); }

member: TOK_YAML1_KEY element { printf("Parsed key-value pair: %s\n", yytext); }

array: TOK_YAML1_ARR_START TOK_YAML1_ARR_END { printf("Parsed empty array.\n"); }
     | TOK_YAML1_ARR_START elements TOK_YAML1_ARR_END { printf("Parsed array with elements.\n"); }

elements: element { printf("Parsed array element.\n"); }
        | element TOK_YAML1_NEWLINE elements { printf("Parsed array element.\n"); }



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
