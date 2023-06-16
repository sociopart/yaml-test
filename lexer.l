%{
#include <stdio.h>
#include "parser.tab.h"  // Include the parser header file
#include <stdbool.h>
extern int indent_level;
extern int object_need_resolve;
YYSTYPE yylval;
yypstate *pstate = NULL;
extern FILE* yyin;
int yyinput(void) {
    return getc(yyin);
}

//#define LEX_DBG
#ifdef LEX_DBG
  #define LEX_PRINTF(pargs)    printf pargs
#else
  #define LEX_PRINTF(pargs)         (void)(0)
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
{DASH}{SPACE}+      {
                      if (object_need_resolve == 1)
                      {
                        // First symbol of line after "key:\n" is a dash.
                        LEX_PRINTF(("[LEX]YAML_ARR_START\n")); 
                        SEND_TOKEN(TOK_YAML1_ARR_START);
                        object_need_resolve = 0;
                      }
                      int next_char = input();
                      
                      //LEX_PRINTF(("[LEX]DASH\n")); 
                      //SEND_TOKEN(TOK_YAML1_DASH);

                      // If no newline defined, then insert it as a token.
                      if (next_char != '\n') {
                          // Get back to DASH position
                          LEX_PRINTF(("[LEX]NEWLINE\n")); 
                          //SEND_TOKEN(TOK_YAML1_NEWLINE);
                      }
                      // Unput the first char we extracted.
                      unput(next_char);
                    }
{COLON}{SPACE}+     {
                      // If smth is defined like "key:\n", then it's probably
                      // an array or a structure.
                      // If it's an array, it will contain dash as a first
                      // symbol of next line.
                      int next_char = input();
                      object_need_resolve = (next_char == '\n');
                      unput(next_char);
                    }
{COLON}             { LEX_PRINTF(("[LEX]COLON\n")); SEND_TOKEN(TOK_YAML1_COLON); }
{NULL}              { LEX_PRINTF(("[LEX]VOID_VALUE: %s\n", yytext)); SEND_TOKEN(TOK_YAML1_NULL); }
{TRUE}              { LEX_PRINTF(("[LEX]BOOL_VALUE: %s\n", yytext)); SEND_TOKEN(TOK_YAML1_NUMBER); }
{FALSE}             { LEX_PRINTF(("[LEX]BOOL_VALUE: %s\n", yytext)); SEND_TOKEN(TOK_YAML1_NUMBER); }
{STRING}            { LEX_PRINTF(("[LEX]STR_VALUE: %s\n", yytext)); SEND_TOKEN(TOK_YAML1_STRING); }
{INT_NUMBER}        { LEX_PRINTF(("[LEX]INT_VALUE: %s\n", yytext)); SEND_TOKEN(TOK_YAML1_NUMBER); }
{FLOAT_NUMBER}      { LEX_PRINTF(("[LEX]FLT_VALUE: %s\n", yytext)); SEND_TOKEN(TOK_YAML1_NUMBER); }
{KEY}               {
                      // Otherwise, first symbol of a "key:\n" is a letter.
                      if (object_need_resolve == 1)
                      {
                        LEX_PRINTF(("[LEX]YAML_OBJ_START\n")); 
                        SEND_TOKEN(TOK_YAML1_OBJ_START);
                        object_need_resolve = 0;
                      }
                      LEX_PRINTF(("[LEX]KEY: %s\n", yytext));
                      SEND_TOKEN(TOK_YAML1_KEY);
                    }
{NEWLINE}           { LEX_PRINTF(("[LEX]NEWLINE\n")); SEND_TOKEN(TOK_YAML1_NEWLINE); }
{INDENT}+           {  
                        int new_indent_level = yyleng / 2;
                        int diff = new_indent_level - indent_level;
                        if (diff > 0) {
                            for (int i = 0; i < diff; i++) {
                                //SEND_TOKEN(TOK_YAML1_INDENT);
                                LEX_PRINTF(("[LEX]INDENT\n"));
                            }
                        } else if (diff < 0) {
                            for (int i = 0; i < -diff; i++) {
                                SEND_TOKEN(TOK_YAML1_DEDENT);
                                LEX_PRINTF(("[LEX]DEDENT\n"));
                            }
                        }
                        indent_level = new_indent_level;
                    }
{YAML_BLOCK_END}    { 
                      while (indent_level > 0)
                      {
                        SEND_TOKEN(TOK_YAML1_DEDENT);
                        LEX_PRINTF(("[LEX]DEDENT\n"));
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
                        LEX_PRINTF(("[LEX]DEDENT\n"));
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