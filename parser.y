%{
#include <stdio.h>
extern int yylex();
extern int yylineno;
extern char* yytext;
extern FILE* yyin;
extern int indent_level;
#define INDENTED_PRINTF(indent_level, format, ...) do { \
    printf("%*s", (indent_level) * 4, ""); \
    printf(format, ##__VA_ARGS__); \
} while(0)
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
%token TOK_YAML1_COLON TOK_YAML1_NEWLINE
%token TOK_YAML1_OBJ_START TOK_YAML1_OBJ_END
%token TOK_YAML1_ARR_START TOK_YAML1_ARR_END
%token TOK_YAML1_NULL TOK_YAML1_KEY TOK_YAML1_STRING TOK_YAML1_NUMBER

%%
statement: content

content: element
| content element

element: 
  TOK_YAML1_COLON       { printf(":"); }
| TOK_YAML1_NULL        { printf("[%s]\n", yytext); }
| TOK_YAML1_STRING      { printf("[%s]\n", yytext); }
| TOK_YAML1_NUMBER      { printf("[%s]\n", yytext); }
| TOK_YAML1_NEWLINE     { INDENTED_PRINTF(indent_level, ",\n"); }
| TOK_YAML1_KEY         { INDENTED_PRINTF(indent_level, "[%s]", yytext); }
| TOK_YAML1_OBJ_START   { INDENTED_PRINTF(indent_level, "{\n"); }
| TOK_YAML1_OBJ_END     { INDENTED_PRINTF(indent_level, "}\n"); }
| TOK_YAML1_ARR_START   { INDENTED_PRINTF(indent_level, "[\n"); }
| TOK_YAML1_ARR_END     { INDENTED_PRINTF(indent_level, "]\n"); }
| TOK_YAML1_BLOCK_START { INDENTED_PRINTF(indent_level, "---\n"); }
| TOK_YAML1_BLOCK_END   { INDENTED_PRINTF(indent_level, "...\n"); }

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
