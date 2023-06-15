%{
#include <stdio.h>
#include <stdlib.h>
%}

%option noyywrap

// Regular expressions for YAML tokens
%%
"---"                      { printf("YAML_START\n"); }
"["                        { printf("SEQUENCE_START\n"); }
"]"                        { printf("SEQUENCE_END\n"); }
"{"                        { printf("MAPPING_START\n"); }
"}"                        { printf("MAPPING_END\n"); }
":"                        { printf("COLON\n"); }
"-"                        { printf("DASH\n"); }
"("                        { printf("PAREN_OPEN\n"); }
")"                        { printf("PAREN_CLOSE\n"); }
"\""([^\"\\]|\\.)*"\""     { printf("STRING\n"); }
[0-9]+                     { printf("INT\n"); }
[A-Za-z_][A-Za-z0-9_]*     { printf("ID\n"); }
[ \r]                      { /* Skip whitespace */ }
\n                         { /* Skip newlines */ }
.                          { /* Ignore unrecognized characters */ }
%%
