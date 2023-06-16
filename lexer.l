%{
#include <stdio.h>
#include "parser.tab.h"  // Include the parser header file

extern int indent_level;
YYSTYPE yylval;
%}

%option noyywrap

DASH              "-"
COLON             ":"
SPACE             " "
INDENT            "  "
NULL              "null"
TRUE              "true"
FALSE             "false"
NEWLINE           "\n"
YAML_BLOCK_START  {DASH}{DASH}{DASH}{NEWLINE}
YAML_BLOCK_END    "..."
STRING            "\""([^\"\\]|\\.)*"\""
INT_NUMBER        [+-]?[[:digit:]]+
FLOAT_NAN         [+-]?[Nn][Aa][Nn]
FLOAT_INF         [+-]?[Ii][Nn][Ff]
FLOAT_NUMBER      {FLOAT_NAN}|{FLOAT_INF}|{INT_NUMBER}("."[[:digit:]]*)?([eE]{INT_NUMBER})?
KEY               [a-zA-Z_][a-zA-Z0-9_\-]*

%%

{YAML_BLOCK_START}  { printf("YAML_START\n"); return TOK_YAML1_BLOCK_START; }
{DASH}              { printf("DASH\n"); return TOK_YAML1_DASH; }
{COLON}             { printf("COLON\n"); return TOK_YAML1_COLON; }
{NULL}              { printf("VOID_VALUE: %s\n", yytext); return TOK_YAML1_NULL; }
{TRUE}              { printf("BOOL_VALUE: %s\n", yytext); return TOK_YAML1_TRUE; }
{FALSE}             { printf("BOOL_VALUE: %s\n", yytext); return TOK_YAML1_FALSE; }
{STRING}            { printf("STR_VALUE: %s\n", yytext); return TOK_YAML1_STR; }
{INT_NUMBER}        { printf("INT_VALUE: %s\n", yytext); return TOK_YAML1_INT; }
{FLOAT_NUMBER}      { printf("FLT_VALUE: %s\n", yytext); return TOK_YAML1_FLOAT; }
{NEWLINE}           { printf("NEWLINE\n"); return TOK_YAML1_NEWLINE; }
{KEY}{COLON}        {
                      yytext[yyleng - 1] = '\0';  // Set the last symbol to null terminator
                      printf("KEY: %s\n", yytext);
                      return TOK_YAML1_KEY;
                    }
{INDENT}+           {  
                        yypstate* pstate = yypstate_new();
                        int new_indent_level = yyleng / 2;
                        int diff = new_indent_level - indent_level;
                        if (diff > 0) {
                            for (int i = 0; i < diff; i++) {
                                yypush_parse(pstate, TOK_YAML1_INDENT, &yylval);
                                printf("INDENT \n");
                            }
                        } else if (diff < 0) {
                            for (int i = 0; i < -diff; i++) {
                                yypush_parse(pstate, TOK_YAML1_DEDENT, &yylval);
                                printf("DEDENT\n");
                            }
                        }
                        indent_level = new_indent_level;
                        yypstate_delete(pstate);
                    }
{YAML_BLOCK_END}    { 
                      yypstate* pstate = yypstate_new();
                      while (indent_level > 0)
                      {
                        yypush_parse(pstate, TOK_YAML1_DEDENT, &yylval);
                        printf("DEDENT\n");
                        indent_level--;
                      }
                      yypstate_delete(pstate); 
                      return TOK_YAML1_BLOCK_END; 
                    }
<<EOF>>             {  
                      yypstate* pstate = yypstate_new();
                      while (indent_level > 0)
                      {
                        yypush_parse(pstate, TOK_YAML1_DEDENT, &yylval);
                        printf("DEDENT\n");
                        indent_level--;
                      }
                      yypush_parse(pstate, TOK_YAML1_BLOCK_END, &yylval);
                      yypstate_delete(pstate); 
                      return 0;  
                    }
.                   { /* Ignore all other characters */ }

%%