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
%token TOK_YAML1_STR TOK_YAML1_INT TOK_YAML1_FLOAT
%token TOK_YAML1_OBJ_START TOK_YAML1_ARR_START

%%
statement: TOK_YAML1_BLOCK_START content TOK_YAML1_BLOCK_END { PRS_PRINTF(("YAML started\n")); }

content: element
| content element

element: TOK_YAML1_DASH { PRS_PRINTF(("Token: TOK_YAML1_DASH\n")); }
| TOK_YAML1_COLON { PRS_PRINTF(("Token: TOK_YAML1_COLON\n")); }
| TOK_YAML1_NULL { PRS_PRINTF(("Token: TOK_YAML1_NULL\n")); }
| TOK_YAML1_TRUE { PRS_PRINTF(("Token: TOK_YAML1_TRUE\n")); }
| TOK_YAML1_FALSE { PRS_PRINTF(("Token: TOK_YAML1_FALSE\n")); }
| TOK_YAML1_STR { PRS_PRINTF(("Token: TOK_YAML1_STR\n")); }
| TOK_YAML1_INT { PRS_PRINTF(("Token: TOK_YAML1_INT\n")); }
| TOK_YAML1_FLOAT { PRS_PRINTF(("Token: TOK_YAML1_FLOAT\n")); }
| TOK_YAML1_NEWLINE { PRS_PRINTF(("Token: TOK_YAML1_NEWLINE\n")); }
| TOK_YAML1_KEY { PRS_PRINTF(("Token: TOK_YAML1_KEY\n")); }
| TOK_YAML1_INDENT { PRS_PRINTF(("Token: TOK_YAML1_INDENT\n")); }
| TOK_YAML1_DEDENT { PRS_PRINTF(("Token: TOK_YAML1_DEDENT\n")); }
| TOK_YAML1_ARR_START { PRS_PRINTF(("Token: TOK_YAML1_ARR_START\n")); }
| TOK_YAML1_OBJ_START { PRS_PRINTF(("Token: TOK_YAML1_OBJ_START\n")); }

%%
const char* token_name(int t) {
    return yytname[YYTRANSLATE(t)];
}

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
