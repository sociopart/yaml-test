%{
#include <stdio.h>
#include "parser.tab.h"  // Include the parser header file

extern int indent_level;
YYSTYPE yylval;
yypstate *pstate = NULL;

//#define LEX_DBG
#ifdef LEX_DBG
  #define LEX_PRINTF(pargs)    printf pargs
  #define LEX_PRINTF_N(n, pargs) do { \
    for (int i = 0; i < n; ++i)       \
    {                                 \
      printf pargs;                    \
    }                                 \
  } while(0)
#else
  #define LEX_PRINTF(pargs)         (void)(0)
  #define LEX_PRINTF_N(n, pargs)    (void)(0)
#endif

#define SEND_N_TOKENS(token, amount) do {               \
  if (pstate == NULL)                                   \
  {                                                     \
    pstate = yypstate_new();                            \
  }                                                     \
  for (int i = 0; i < amount; ++i) {                    \
    yypush_parse(pstate, token, &yylval);               \
  }                                                     \
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

{YAML_BLOCK_START}  { LEX_PRINTF(("[LEX]YAML_START\n")); SEND_TOKEN(TOK_YAML1_BLOCK_START); }
{DASH}              { LEX_PRINTF(("[LEX]DASH\n")); SEND_TOKEN(TOK_YAML1_DASH); }
{COLON}             { LEX_PRINTF(("[LEX]COLON\n")); SEND_TOKEN(TOK_YAML1_COLON); }
{NULL}              { LEX_PRINTF(("[LEX]VOID_VALUE: %s\n", yytext)); SEND_TOKEN(TOK_YAML1_NULL); }
{TRUE}              { LEX_PRINTF(("[LEX]BOOL_VALUE: %s\n", yytext)); SEND_TOKEN(TOK_YAML1_TRUE); }
{FALSE}             { LEX_PRINTF(("[LEX]BOOL_VALUE: %s\n", yytext)); SEND_TOKEN(TOK_YAML1_FALSE); }
{STRING}            { LEX_PRINTF(("[LEX]STR_VALUE: %s\n", yytext)); SEND_TOKEN(TOK_YAML1_STR); }
{INT_NUMBER}        { LEX_PRINTF(("[LEX]INT_VALUE: %s\n", yytext)); SEND_TOKEN(TOK_YAML1_INT); }
{FLOAT_NUMBER}      { LEX_PRINTF(("[LEX]FLT_VALUE: %s\n", yytext)); SEND_TOKEN(TOK_YAML1_FLOAT); }
{NEWLINE}           { LEX_PRINTF(("[LEX]NEWLINE\n")); SEND_TOKEN(TOK_YAML1_NEWLINE); }
{KEY}{COLON}        {
                      yytext[yyleng - 1] = '\0';  // Set the last symbol to null terminator
                      LEX_PRINTF(("[LEX]KEY: %s\n", yytext));
                      SEND_TOKEN(TOK_YAML1_KEY);
                    }
{INDENT}+           {  
                        int new_indent_level = yyleng / 2;
                        int diff = new_indent_level - indent_level;
                        if (diff > 0) {
                            for (int i = 0; i < diff; i++) {
                                SEND_TOKEN(TOK_YAML1_INDENT);
                                LEX_PRINTF(("[LEX] INDENT\n"));
                            }
                        } else if (diff < 0) {
                            for (int i = 0; i < -diff; i++) {
                                SEND_TOKEN(TOK_YAML1_DEDENT);
                                LEX_PRINTF(("[LEX] DEDENT\n"));
                            }
                        }
                        indent_level = new_indent_level;
                    }
{YAML_BLOCK_END}    { 
                      while (indent_level > 0)
                      {
                        SEND_TOKEN(TOK_YAML1_DEDENT);
                        LEX_PRINTF(("[LEX] DEDENT\n"));
                        indent_level--;
                      }
                      if (pstate != NULL)
                      {
                        yypstate_delete(pstate); 
                      }
                      return TOK_YAML1_BLOCK_END; 
                    }
<<EOF>>             {  
                      while (indent_level > 0)
                      {
                        SEND_TOKEN(TOK_YAML1_DEDENT);
                        LEX_PRINTF(("[LEX] DEDENT\n"));
                        indent_level--;
                      }
                      yypush_parse(pstate, TOK_YAML1_BLOCK_END, &yylval);
                      if (pstate != NULL)
                      {
                        yypstate_delete(pstate); 
                      }
                      return 0;  
                    }
.                   { /* Ignore all other characters */ }

%%