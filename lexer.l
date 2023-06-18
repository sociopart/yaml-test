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

#define TOKEN_STACK_PUSH(token)                         \
    do {                                                \
        if (t_stack == NULL)                            \
            t_stack = ts_create();                      \
        ts_push(t_stack, token);                        \
    } while (0)

#define STACK_POP_N_TOKENS(amount)                      \
    do {                                                \
        int current_token = -1;                         \
        for (int i = 0; i < amount; i++) {              \
            current_token = ts_pop(t_stack);            \
            if (current_token != -1) {                  \
                SEND_TOKEN(current_token);              \
            }                                           \
        }                                               \
    } while (0)

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
  last_pushed_token = token;                            \
} while (0)

#define CLEANUP()                                       \
    do {                                                \
        if (pstate != NULL) {                           \
            yypstate_delete(pstate);                    \
        }                                               \
        if (t_stack != NULL) {                          \
          ts_destroy(t_stack);                          \
        }                                               \
    } while (0)


int yyinput(void) {
    return getc(yyin);
}

int indent_level = 0;
int last_pushed_token = -1;
token_stack* t_stack = NULL;

YYSTYPE yylval;
yypstate *pstate = NULL;
extern FILE* yyin;
// -----------------------------------------------------------------------------
%}

%option noyywrap
%x KEY_STATE NL_STATE

DASH                  "-"
COLON                 ":"
SPACE                 " "
INDENT                "  "{DASH}*
NULL                  "null"
TRUE                  "true"
FALSE                 "false"
NEWLINE               "\n"
YAML_BLOCK_START      {DASH}{DASH}{DASH}{NEWLINE}
YAML_BLOCK_END        "..."
STRING                "\""([^\"\\]|\\.)*"\""
INT_NUMBER            [+-]?[[:digit:]]+
FLOAT_NAN             [+-]?[Nn][Aa][Nn]
FLOAT_INF             [+-]?[Ii][Nn][Ff]
FLOAT_NUMBER          {FLOAT_NAN}|{FLOAT_INF}|{INT_NUMBER}("."[[:digit:]]*)?([eE]{INT_NUMBER})?
KEY                   [a-zA-Z_][a-zA-Z0-9_\-]*
YAML_ARRAY_DASH       {DASH}{SPACE}* 
ARR_START             {SPACE}*{DASH}{SPACE}*
%%

{NULL}                  { SEND_TOKEN(TOK_YAML1_NULL); }
{TRUE}                  { SEND_TOKEN(TOK_YAML1_NUMBER); }
{FALSE}                 { SEND_TOKEN(TOK_YAML1_NUMBER); }
{STRING}                { SEND_TOKEN(TOK_YAML1_STRING); }
{INT_NUMBER}            { SEND_TOKEN(TOK_YAML1_NUMBER); }
{FLOAT_NUMBER}          { SEND_TOKEN(TOK_YAML1_NUMBER); }
{NEWLINE}               { BEGIN(NL_STATE); }
{COLON}                 {SEND_TOKEN(TOK_YAML1_COLON); BEGIN(KEY_STATE);}
{YAML_BLOCK_START}      { SEND_TOKEN(TOK_YAML1_BLOCK_START); }
{YAML_ARRAY_DASH}       {
                          if (ts_peek(t_stack) != TOK_YAML1_ARR_END)
                          {
                            SEND_TOKEN(TOK_YAML1_ARR_START);
                            TOKEN_STACK_PUSH(TOK_YAML1_ARR_END);
                          }
                        }
{KEY}                   {
                          if (last_pushed_token == TOK_YAML1_ARR_START){
                            SEND_TOKEN(TOK_YAML1_OBJ_START);
                            TOKEN_STACK_PUSH(TOK_YAML1_OBJ_END);
                          }
                          /* 
                            If something was present after a nested 
                            struct / array, then add a separator between elems.
                          */
                          if (last_pushed_token == TOK_YAML1_ARR_END \
                          || last_pushed_token == TOK_YAML1_OBJ_END)
                          {
                            SEND_TOKEN(TOK_YAML1_NEWLINE);
                          }
                          SEND_TOKEN(TOK_YAML1_KEY);
                          LEX_PRINTF(("[LEX] key is: %s\n", yytext));
                        }
  /* ------------------------ Handling NEWLINE_STATE ------------------------ */
<NL_STATE>{INDENT}+      {
                          int new_indent_level = yyleng / 2;
                          int diff = new_indent_level - indent_level;
                          /* 
                            If indentation level wasn't changed, then next
                            element exists and belongs to current struct.
                          */
                          if (diff == 0)
                          {
                            SEND_TOKEN(TOK_YAML1_NEWLINE);
                          }
                          else if (diff < 0)
                          {
                            STACK_POP_N_TOKENS(-diff);
                          }
                          indent_level = new_indent_level;
                          BEGIN(INITIAL); /* Get back anyways. */
                        }
<NL_STATE>.             {
                          /* Get back in any other situation. */
                          REJECT;
                          BEGIN(INITIAL);
                        }
  /* ------------------------------------------------------------------------ */
  /* -------------------------- Handling KEY_STATE -------------------------- */
<KEY_STATE>{NEWLINE}*{ARR_START}  {
                          SEND_TOKEN(TOK_YAML1_ARR_START);
                          TOKEN_STACK_PUSH(TOK_YAML1_ARR_END);
                          LEX_PRINTF(("[LEX] array is: %s", yytext));
                          BEGIN(INITIAL);
                        }

<KEY_STATE>{NEWLINE}    {
                          SEND_TOKEN(TOK_YAML1_OBJ_START);
                          TOKEN_STACK_PUSH(TOK_YAML1_OBJ_END);
                          BEGIN(INITIAL);
                        }

<KEY_STATE>.            {
                          BEGIN(INITIAL);
                        }
  /* ------------------------------------------------------------------------ */
{INDENT}+{YAML_ARRAY_DASH}*               { 
                          //printf("INDENT triggered\n");
                          int new_indent_level = yyleng / 2;

                          int diff = new_indent_level - indent_level;
                          if (diff < 0)
                          {
                            STACK_POP_N_TOKENS(-diff);
                          }
                          indent_level = new_indent_level;
                        }
{YAML_BLOCK_END}        {
                          STACK_POP_N_TOKENS(indent_level);
                          indent_level = 0;
                          CLEANUP();
                          return TOK_YAML1_BLOCK_END; 
                        }
<<EOF>>                 {  
                          STACK_POP_N_TOKENS(indent_level);
                          indent_level = 0;
                          //SEND_TOKEN(TOK_YAML1_BLOCK_END);
                          CLEANUP();
                          return 0;  
                        }
.                       { /* Ignore all other characters */ }
