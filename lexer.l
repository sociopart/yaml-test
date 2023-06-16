%{
#include <stdio.h>
#include "parser.tab.h"  // Include the parser header file

extern int indent_level;
YYSTYPE yylval;
yypstate* pstate = NULL;

#define SEND_N_TOKENS(token, amount) do {               \
  pstate = yypstate_new();                              \
  int status = 0;                                       \
  for (int i = 0; i < amount; ++i) {                    \
    status = yypush_parse(pstate, token, &yylval);      \
    if (status != YYPUSH_MORE) {                        \
      yypstate_delete(pstate);                          \
      return status;                                    \
    }                                                   \
  }                                                     \
  yypstate_delete(pstate);                              \
  return status;                                        \
} while (0)

#define SEND_TOKEN(token) SEND_N_TOKENS(token, 1)
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

{YAML_BLOCK_START}  { printf("YAML_START\n"); SEND_TOKEN(TOK_YAML1_BLOCK_START); }
{DASH}              { printf("DASH\n"); SEND_TOKEN(TOK_YAML1_DASH); }
{COLON}             { printf("COLON\n"); SEND_TOKEN(TOK_YAML1_COLON); }
{NULL}              { printf("VOID_VALUE: %s\n", yytext); SEND_TOKEN(TOK_YAML1_NULL); }
{TRUE}              { printf("BOOL_VALUE: %s\n", yytext); SEND_TOKEN(TOK_YAML1_TRUE); }
{FALSE}             { printf("BOOL_VALUE: %s\n", yytext); SEND_TOKEN(TOK_YAML1_FALSE); }
{STRING}            { printf("STR_VALUE: %s\n", yytext); SEND_TOKEN(TOK_YAML1_STR); }
{INT_NUMBER}        { printf("INT_VALUE: %s\n", yytext); SEND_TOKEN(TOK_YAML1_INT); }
{FLOAT_NUMBER}      { printf("FLT_VALUE: %s\n", yytext); SEND_TOKEN(TOK_YAML1_FLOAT); }
{NEWLINE}           { printf("NEWLINE\n"); SEND_TOKEN(TOK_YAML1_NEWLINE); }
{KEY}{COLON}        {
                      yytext[yyleng - 1] = '\0';  // Set the last symbol to null terminator
                      printf("KEY: %s\n", yytext);
                      SEND_TOKEN(TOK_YAML1_KEY);
                    }
{INDENT}+           {  
                        pstate = yypstate_new();
                        int new_indent_level = yyleng / 2;
                        int diff = new_indent_level - indent_level;
                        if (diff > 0) {
                          SEND_N_TOKENS(TOK_YAML1_INDENT, diff);
                        } else if (diff < 0) {
                          SEND_N_TOKENS(TOK_YAML1_DEDENT, -diff);
                        }
                        indent_level = new_indent_level;
                    }
{YAML_BLOCK_END}    { 
                      if (indent_level > 0)
                      {
                        SEND_N_TOKENS(TOK_YAML1_DEDENT, indent_level);
                      }
                      SEND_TOKEN(TOK_YAML1_BLOCK_END); 
                    }
<<EOF>>             {  
                      if (indent_level > 0)
                      {
                        SEND_N_TOKENS(TOK_YAML1_DEDENT, indent_level);
                      }
                      SEND_TOKEN(TOK_YAML1_BLOCK_END); 
                      return 0;  
                    }
.                   { /* Ignore all other characters */ }

%%