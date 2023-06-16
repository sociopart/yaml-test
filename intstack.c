#include "intstack.h"

int_stack* create_stack() {
    int_stack* stack = (int_stack*)malloc(sizeof(int_stack));
    stack->array = (int*)malloc(10 * sizeof(int));
    stack->top = -1;
    stack->size = 10;
    return stack;
}

int is_empty(int_stack* stack) {
    return (stack->top == -1);
}

int is_full(int_stack* stack) {
    return (stack->top == stack->size - 1);
}

void resize(int_stack* stack) {
    stack->size *= 2;
    stack->array = (int*)realloc(stack->array, stack->size * sizeof(int));
}

void push(int_stack* stack, int item) {
    if (is_full(stack)) {
        resize(stack);
    }
    stack->array[++stack->top] = item;
}

int pop(int_stack* stack) {
    if (is_empty(stack)) {
        printf("Stack is empty.\n");
        return -1;
    }
    return stack->array[stack->top--];
}

int peek(int_stack* stack) {
    if (is_empty(stack)) {
        printf("Stack is empty.\n");
        return -1;
    }
    return stack->array[stack->top];
}

void display(int_stack* stack) {
    if (is_empty(stack)) {
        printf("Stack is empty.\n");
        return;
    }
    printf("Stack: ");
    for (int i = stack->top; i >= 0; i--) {
        printf("%d ", stack->array[i]);
    }
    printf("\n");
}

void destroy_stack(int_stack* stack) {
    free(stack->array);
    free(stack);
}
