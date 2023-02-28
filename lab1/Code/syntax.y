%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

int yylex();
int yyerror(char *s);
int yyparse();
int yywrap();
int yylineno;

FILE *yyin;
// out is not used
// we use printf instead
// FILE *yyout;

char *yytext;
%}

%%

%%
