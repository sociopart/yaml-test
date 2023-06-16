#ifndef INTSTACK_H
#define INTSTACK_H

#include <stdio.h>
#include <stdlib.h>

typedef struct {
    int* array;
    int top;
    int size;
} int_stack;

int_stack* create_stack();
int is_empty(int_stack* stack);
int is_full(int_stack* stack);
void resize(int_stack* stack);
void push(int_stack* stack, int item);
int pop(int_stack* stack);
int peek(int_stack* stack);
void display(int_stack* stack);
void destroy_stack(int_stack* stack);

#endif  /* INTSTACK_H */
