%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "lex.yy.c"

#define MAX_IDENT_LEN 32
#define MAX_NUM_LEN 32
#define MAX_ERR_NUM 1e4

struct Error {
    int lineno;
    const char character;
};

struct Error errors[MAX_ERR_NUM];
int errorCount = 0;
int errorLineno = 0;
char errorChar = '\0';

int yyerror(size_t err_line, const char err_char);
int isNewError(int errorLineno, const char errorChar);

extern int yylex();
extern int yyparse();
int yywrap();
extern size_t yylineno;


FILE *yyin;
// out is not used
// we use printf instead
// FILE *yyout;

char *yytext;
%}

%union {
    char    *string;
    int     number;
    float   floats;
}

%define api.pure full
%lex-param { yyscan_t scanner }
%parse-param { void *scanner }

%token  SEMI
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
        WHILE

%token <number> INT
%token <floats> FLOAT
%token <string> ID

// precedence and associativity

%right ASSIGNOP
%left OR
%left AND
%left RELOP
%left PLUS MINUS
%left STAR DIV
%right NOT
%left DOT
%left LB RB
%left LP RP
%nonassoc ELSE

%%

// High-level Definitions

Program : ExtDefList {
    printf("Program parsed successfully \r \n");
    printf("Total lines: %d \r \n", yylineno);
    printf("Total errors: %d \r \n", errorCount);
    for (int i = 0; i < errorCount; i++) {
        printf("Error %d: Line %d, character %c \r \n", i + 1, errors[i].lineno, errors[i].character);
    }
}

ExtDefList : ExtDef ExtDefList {
    printf("Ext_def_list parsed successfully \r \n");
} 
| {
    printf("Ext_def_list parsed successfully \r \n");
}

ExtDef : Specifier ExtDecList SEMI {
    printf("Ext_def parsed successfully \r \n");
}
| Specifier SEMI {
    printf("Ext_def parsed successfully \r \n");
}
| Specifier FunDec CompSt {
    printf("Ext_def parsed successfully \r \n");
}

ExtDecList : VarDec {
    printf("Ext_dec_list parsed successfully \r \n");
}
| VarDec COMMA ExtDecList {
    printf("Ext_dec_list parsed successfully \r \n");
}

// Specifiers
Specifier : TYPE {
    printf("Specifier parsed successfully \r \n");
}
| StructSpecifier {
    printf("Specifier parsed successfully \r \n");
}

StructSpecifier : STRUCT OptTag LC DefList RC {
    printf("Struct_specifier parsed successfully \r \n");
}
| STRUCT Tag {
    printf("Struct_specifier parsed successfully \r \n");
}

OptTag : ID {
    printf("Opt_tag parsed successfully \r \n");
}
| {
    printf("Opt_tag parsed successfully \r \n");
}

Tag : ID {
    printf("Tag parsed successfully \r \n");
}

// Declarators
VarDec : ID {
    printf("Var_dec parsed successfully \r \n");
}
| VarDec LB INT RB {
    printf("Var_dec parsed successfully \r \n");
}

FunDec : ID LP VarList RP {
    printf("Fun_dec parsed successfully \r \n");
}
| ID LP RP {
    printf("Fun_dec parsed successfully \r \n");
}

VarList : ParamDec COMMA VarList {
    printf("Var_list parsed successfully \r \n");
}
| ParamDec {
    printf("Var_list parsed successfully \r \n");
}

ParamDec : Specifier VarDec {
    printf("Param_dec parsed successfully \r \n");
}

// Statements
CompSt : LC DefList StmtList RC {
    printf("Comp_st parsed successfully \r \n");
}

StmtList : Stmt StmtList {
    printf("Stmt_list parsed successfully \r \n");
}
| {
    printf("Stmt_list parsed successfully \r \n");
}

Stmt : Exp SEMI {
    printf("Stmt parsed successfully \r \n");
}
| CompSt {
    printf("Stmt parsed successfully \r \n");
}
| RETURN Exp SEMI {
    printf("Stmt parsed successfully \r \n");
}
| IF LP Exp RP Stmt {
    printf("Stmt parsed successfully \r \n");
}
| IF LP Exp RP Stmt ELSE Stmt {
    printf("Stmt parsed successfully \r \n");
}
| WHILE LP Exp RP Stmt {
    printf("Stmt parsed successfully \r \n");
}

// Local Definitions
DefList : Def DefList {
    printf("Def_list parsed successfully \r \n");
}
| {
    printf("Def_list parsed successfully \r \n");
}

Def : Specifier DecList SEMI {
    printf("Def parsed successfully \r \n");
}

DecList : Dec {
    printf("Dec_list parsed successfully \r \n");
}
| Dec COMMA DecList {
    printf("Dec_list parsed successfully \r \n");
}

Dec : VarDec {
    printf("Dec parsed successfully \r \n");
}
| VarDec ASSIGNOP Exp {
    printf("Dec parsed successfully \r \n");
}

// Expressions
Exp : Exp ASSIGNOP Exp {
    printf("Exp parsed successfully \r \n");
}
| Exp AND Exp {
    printf("Exp parsed successfully \r \n");
}
| Exp OR Exp {
    printf("Exp parsed successfully \r \n");
}
| Exp RELOP Exp {
    printf("Exp parsed successfully \r \n");
}
| Exp PLUS Exp {
    printf("Exp parsed successfully \r \n");
}
| Exp MINUS Exp {
    printf("Exp parsed successfully \r \n");
}
| Exp STAR Exp {
    printf("Exp parsed successfully \r \n");
}
| Exp DIV Exp {
    printf("Exp parsed successfully \r \n");
}
| LP Exp RP {
    printf("Exp parsed successfully \r \n");
}
| MINUS Exp {
    printf("Exp parsed successfully \r \n");
}
| NOT Exp {
    printf("Exp parsed successfully \r \n");
}
| ID LP Args RP {
    printf("Exp parsed successfully \r \n");
}
| ID LP RP {
    printf("Exp parsed successfully \r \n");
}
| Exp LB Exp RB {
    printf("Exp parsed successfully \r \n");
}
| Exp DOT ID {
    printf("Exp parsed successfully \r \n");
}
| ID {
    printf("Exp parsed successfully \r \n");
}
| INT {
    printf("Exp parsed successfully \r \n");
}
| FLOAT {
    printf("Exp parsed successfully \r \n");
}


Args : Exp COMMA Args {
    printf("Args parsed successfully \r \n");
}
| Exp {
    printf("Args parsed successfully \r \n");
}


%%

int yyparse() {
    yyscan_t scanner;
    yylex_init(&scanner);
    yyset_in(yyin, scanner);
    yyparse(scanner);
    yylex_destroy(scanner);
    return 0;
}

int yyerror(size_t err_line, const char err_char) {
    if (isNewError(err_line, err_char)) {
        errors[errorCount].lineno = err_line;
        errors[errorCount].character = err_char;
        errorCount++;
        return 1;
    }
    return 0;
}

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

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s filename, please try again with a filename as the argument to the program (e.g. test.cmm) \r \n", argv[0]);
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        printf("Error: Could not open file %s \r \n", argv[1]);
        return 1;
    }
    yyrestart(yyin);
    yyparse();
    fclose(yyin);
    return 0;
}
