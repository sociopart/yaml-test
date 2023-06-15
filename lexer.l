%{
#include <stdio.h>
#include "parser.tab.h"  // Include the parser header file

extern int indent_level;
void process_yaml_end();
%}

%option noyywrap

DASH              "-"
COLON             ":"
SPACE             " "
INDENT            "  "
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
{STRING}            { printf("STR_VALUE: %s\n", yytext); return TOK_YAML1_STR; }
{INT_NUMBER}        { printf("INT_VALUE: %s\n", yytext); return TOK_YAML1_INT; }
{FLOAT_NUMBER}      { printf("FLT_VALUE: %s\n", yytext); return TOK_YAML1_FLOAT; }
{INDENT}+           {
                        int new_indent_level = yyleng / 2;
                        int diff = new_indent_level - indent_level;
                        if (diff > 0) {
                            for (int i = 0; i < diff; i++) {
                                printf("INDENT \n");
                            }
                        } else if (diff < 0) {
                            for (int i = 0; i < -diff; i++) {
                                printf("DEDENT\n");
                            }
                        }
                        indent_level = new_indent_level;
                    }
{NEWLINE}           { printf("NEWLINE\n"); return TOK_YAML1_NEWLINE; }
{KEY}{COLON}        {
                      yytext[yyleng - 1] = '\0';  // Set the last symbol to null terminator
                      printf("KEY: %s\n", yytext);
                      return TOK_YAML1_KEY;
                    }
{YAML_BLOCK_END}    { process_yaml_end(); return TOK_YAML1_BLOCK_END; }
<<EOF>>             { process_yaml_end(); return 0; }
.                   { /* Ignore all other characters */ }

%%

void process_yaml_end()
{
  if (indent_level > 0) {
      for (int i = 0; i < indent_level; i++) {
          printf("DEDENT\n");
      }
  }
  printf("YAML_END\n");
}
