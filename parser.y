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

%%
statement: content

content: element
| content element

element: TOK_YAML1_DASH { PRS_PRINTF(("Token: TOK_YAML1_DASH\n")); }
| TOK_YAML1_COLON       { PRS_PRINTF(("Token: TOK_YAML1_COLON\n")); }
| TOK_YAML1_NULL        { PRS_PRINTF(("Token: TOK_YAML1_NULL\n")); }
| TOK_YAML1_STRING      { PRS_PRINTF(("Token: TOK_YAML1_STRING\n")); }
| TOK_YAML1_NUMBER      { PRS_PRINTF(("Token: TOK_YAML1_NUMBER\n")); }
| TOK_YAML1_NEWLINE     { PRS_PRINTF(("Token: TOK_YAML1_NEWLINE\n")); }
| TOK_YAML1_KEY         { PRS_PRINTF(("Token: TOK_YAML1_KEY\n")); }
| TOK_YAML1_OBJ_START   { PRS_PRINTF(("Token: TOK_YAML1_OBJ_START\n")); }
| TOK_YAML1_OBJ_END     { PRS_PRINTF(("Token: TOK_YAML1_OBJ_END\n")); }
| TOK_YAML1_ARR_START   { PRS_PRINTF(("Token: TOK_YAML1_ARR_START\n")); }
| TOK_YAML1_ARR_END     { PRS_PRINTF(("Token: TOK_YAML1_ARR_END\n")); }
| TOK_YAML1_BLOCK_START { PRS_PRINTF(("Token: TOK_YAML1_BLOCK_START\n")); }
| TOK_YAML1_BLOCK_END   { PRS_PRINTF(("Token: TOK_YAML1_BLOCK_END\n")); }

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
