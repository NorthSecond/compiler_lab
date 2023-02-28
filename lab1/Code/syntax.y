%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "lex.yy.c"

#define MAX_IDENT_LEN 32
#define MAX_NUM_LEN 32
#define MAX_ERR_NUM 1e4

int yylex();
int yyerror(char *s);
int yyparse();
int yywrap();

size_t yylineno;

FILE *yyin;
// out is not used
// we use printf instead
// FILE *yyout;

char *yytext;

int isNewError(int errorLineno, const char errorChar);

struct Error {
    int lineno;
    char character;
};

struct Error errors[MAX_ERR_NUM];
int errorCount = 0;
int errorLineno = 0;
char errorChar = '\0';

// int yylex(){
//     char c[2];
//     fgets(c, 2, yyin);
//     return c[0];
// }

int isNewError(int errorLineno, const char errorChar) {
    for (int i = 0; i < errorCount; i++) {
        if (errors[i].lineno == errorLineno && errors[i].character == errorChar) {
            return 0;
        }
    }
    return 1;
}

int yywrap() {
    return 1;
}

int yyerror(char *s) {
    if (isNewError(errorLineno, errorChar)) {
        errors[errorCount].lineno = errorLineno;
        errors[errorCount].character = errorChar;
        errorCount++;
    }
    return 0;
}
%}


%define api.pure full
%lex-param { yyscan_t scanner }
%parse-param { void *scanner }

%token  INT
        FLOAT
        ID
        SEMI
        COMMA
        ASSIGNOP
        RELOP
        PLUS
        MINUS
        STAR
        DIV
        AND
        OR
        DOT
        NOT
        TYPE
        LP
        RP
        LB
        RB
        LC
        RC
        STRUCT
        RETURN
        IF
        ELSE

%union {
    char *string;
    int number;
    float floats;
    char *position;
}

%%

commands
    : command SEMI commands
    | command SEMI
    | error SEMI commands
    | error SEMI
    ;

command
    : 
    | ID LP RP
    ;

/* exit: EXIT; */



%%

int yylex() {
    char c[2];
    fgets(c, 2, yyin);
    return c[0];
}

int yyparse() {
    yyscan_t scanner;
    yylex_init(&scanner);
    yyset_in(yyin, scanner);
    yyparse(scanner);
    yylex_destroy(scanner);
    return 0;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s filename, please try again with a filename as the argument to the program (e.g. %s test.c) \r \n", argv[0], argv[0]);
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        printf("Error: Could not open file %s \r \n", argv[1]);
        return 1;
    }
    yyparse();
    fclose(yyin);
    return 0;
}
