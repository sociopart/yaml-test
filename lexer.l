%{
#include <stdio.h>
#include "parser.tab.h"  // Include the parser header file
// -----------------------------------------------------------------------------
// Helper structure which will hold all stack info.
typedef struct {
    int* array;
    int top;
    int size;
} token_stack;

token_stack* ts_create() {
    token_stack* stack = (token_stack*)malloc(sizeof(token_stack));
    stack->array = (int*)malloc(10 * sizeof(int));
    stack->top = -1;
    stack->size = 10;
    return stack;
}

void ts_push(token_stack* stack, int item) {
    if (stack->top == stack->size - 2) {
        stack->size *= 2;
        stack->array = (int*)realloc(stack->array, stack->size * sizeof(int));
    }
    stack->array[++stack->top] = item;
}

void ts_display(token_stack* stack) {
    if (stack->top != -1) {
        printf("Stack is empty.\n");
        return;
    }
    printf("Stack: ");
    for (int i = stack->top; i >= 0; i--) {
        printf("%d ", stack->array[i]);
    }
    printf("\n");
}

int ts_pop(token_stack* stack) {
    return (stack != NULL && stack->top != -1) ? stack->array[stack->top--] : -1;
}

int ts_peek(token_stack* stack) {
    return (stack != NULL && stack->top != -1) ? stack->array[stack->top] : -1;
}

void ts_destroy(token_stack* stack) {
    free(stack->array);
    free(stack);
}

// -----------------------------------------------------------------------------
// Definitions
//#define LEX_DBG
#ifdef LEX_DBG
  #define LEX_PRINTF(pargs)    printf pargs
#else
  #define LEX_PRINTF(pargs)    (void)(0)
#endif

#define SEND_TOKEN(token) do {                          \
  if (pstate == NULL)                                   \
  {                                                     \
    pstate = yypstate_new();                            \
  }                                                     \
  yypush_parse(pstate, token, &yylval);                 \
} while (0)

#define TOKEN_STACK_PUSH(token)  {                      \
  if (t_stack == NULL) t_stack = ts_create();           \
  ts_push(t_stack, token);                              \
}                                                       \

int yyinput(void) {
    return getc(yyin);
}

int indent_level = 0;
int object_need_resolve = 0;
token_stack* t_stack = NULL;

YYSTYPE yylval;
yypstate *pstate = NULL;
extern FILE* yyin;
// -----------------------------------------------------------------------------
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
                      int stack_peek = ts_peek(t_stack);
                      if (stack_peek != TOK_YAML1_ARR_END)
                      {
                        SEND_TOKEN(TOK_YAML1_ARR_START);
                        TOKEN_STACK_PUSH(TOK_YAML1_ARR_END);
                      }
                    }
{SPACE}*{KEY}{SPACE}*{COLON}{SPACE}*{NEWLINE}  {
                    SEND_TOKEN(TOK_YAML1_OBJ_START);
                    printf("OBJ_END is: %d\n", TOK_YAML1_OBJ_END);
                    TOKEN_STACK_PUSH(TOK_YAML1_OBJ_END);
                    printf("Stack peek is: %d\n", ts_peek(t_stack));
                    }
{NULL}              { LEX_PRINTF(("[LEX]VOID_VALUE: %s\n", yytext)); SEND_TOKEN(TOK_YAML1_NULL); }
{TRUE}              { LEX_PRINTF(("[LEX]BOOL_VALUE: %s\n", yytext)); SEND_TOKEN(TOK_YAML1_NUMBER); }
{FALSE}             { LEX_PRINTF(("[LEX]BOOL_VALUE: %s\n", yytext)); SEND_TOKEN(TOK_YAML1_NUMBER); }
{STRING}            { LEX_PRINTF(("[LEX]STR_VALUE: %s\n", yytext));  SEND_TOKEN(TOK_YAML1_STRING); }
{INT_NUMBER}        { LEX_PRINTF(("[LEX]INT_VALUE: %s\n", yytext));  SEND_TOKEN(TOK_YAML1_NUMBER); }
{FLOAT_NUMBER}      { LEX_PRINTF(("[LEX]FLT_VALUE: %s\n", yytext));  SEND_TOKEN(TOK_YAML1_NUMBER); }
{NEWLINE}           { LEX_PRINTF(("[LEX]NEWLINE\n"));                SEND_TOKEN(TOK_YAML1_NEWLINE); }
{INDENT}+           {  
                        int new_indent_level = yyleng / 2;
                        int diff = new_indent_level - indent_level;
                        int current_token = -1;
                        if (diff < 0)
                        {
                          for (int i = 0; i < -diff; i++)
                          {
                            current_token = ts_pop(t_stack);
                            if(current_token != -1)
                            {
                              SEND_TOKEN(current_token);
                            }
                          }
                        }
                        indent_level = new_indent_level;
                    }
{YAML_BLOCK_END}    { 
                      int current_token = -1;
                      for (int i = 0; i < indent_level; i++) {
                          current_token = ts_pop(t_stack);
                          if(current_token != -1)
                          {
                            SEND_TOKEN(current_token);
                          }
                      }
                      indent_level = 0;
                      if (pstate != NULL)
                      {
                        yypstate_delete(pstate); 
                      }
                      return TOK_YAML1_BLOCK_END; 
                    }
<<EOF>>             {  
                      int current_token = -1;
                      for (int i = 0; i < indent_level; i++) {
                          current_token = ts_pop(t_stack);
                          if(current_token != -1)
                          {
                            SEND_TOKEN(current_token);
                          }
                      }
                      indent_level = 0;
                      SEND_TOKEN(TOK_YAML1_BLOCK_END);

                      if (pstate != NULL)
                      {
                        yypstate_delete(pstate); 
                      }
                      return 0;  
                    }
.                   { /* Ignore all other characters */ }
