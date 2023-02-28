%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include "syntax.tab.h"

int yycolumn;
extern bool is_error;

extern int yylex();
extern int atoi();
extern float atof();
extern int isNewError(int errorLineno, const char errorChar);

#if YYDEBUG > 0
#define debug_printf  printf
#else
#define debug_printf(...)
#endif // YYDEBUG

#define YY_USER_ACTION\
    yylloc.first_line=yylloc.last_line=yylineno;\
    yylloc.first_column=yycolumn;\
    yylloc.last_column=yycolumn+yyleng-1;\
    yycolumn+=yyleng;


#define RETURN_TOKEN(token) debug_printf("%s\n",#token);return token

%}

/* Tokens for C--*/
%option noyywrap
%option bison-bridge
%option reentrant

WHITE_SPACE         [\s]
DIGIT               [0-9]
LETTER              [a-zA-Z_]
DOT                 \.
QUOTE               [\'\"]
HEX                 [0-9a-fA-F]
OCT                 [0-7]

%%

{WHITE_SPACE}+      ;// ignore white space
\n                  ;// ignore new line
0{OCT}*                         |
0[Xx]{HEX}+                     |
[1-9]{DIGIT}*                   yylval->number=atoi(yytext);RETURN_TOKEN(INT);
{DIGIT}*{DOT}{DIGIT}*[Ee][+-]?{DIGIT}+     |
(0|[1-9]{DIGIT}*){DOT}{DIGIT}+             yylval->number=atof(yytext);RETURN_TOKEN(FLOAT);
{LETTER}[{LETTER}{DIGIT}]*      yylval->string=yytext;RETURN_TOKEN(ID);
";"                             RETURN_TOKEN(SEMI);
","                             RETURN_TOKEN(COMMA);
"="                             RETURN_TOKEN(ASSIGNUP);
"<"                             |
">"                             |
"<="                            |
">="                            |
"=="                            |
"!="                            RETURN_TOKEN(RELOP);
"+"                             RETURN_TOKEN(PLUS);
"-"                             RETURN_TOKEN(MINUS);
"*"                             RETURN_TOKEN(STAR);
"/"                             RETURN_TOKEN(DIV);
&&                              RETURN_TOKEN(AND);
\|\|                            RETURN_TOKEN(OR);
{DOT}                           RETURN_TOKEN(DOT);
!                               RETURN_TOKEN(NOT);
[int|float]                     RETURN_TOKEN(TYPE);
"("                             RETURN_TOKEN(LP);
")"                             RETURN_TOKEN(RP);
\[                              RETURN_TOKEN(LB);
]                               RETURN_TOKEN(RB);
\{                              RETURN_TOKEN(LC);
"}"                             RETURN_TOKEN(RC);
struct                          RETURN_TOKEN(STRUCT);
return                          RETURN_TOKEN(RETURN);
if                              RETURN_TOKEN(IF);
else                            RETURN_TOKEN(ELSE);
while                           RETURN_TOKEN(WHILE);
"//"                            {
    // RETURN_TOKEN(LINECOMMENT);
    char c = yylex();
    while (c != EOF) {
        if (c == '\n') {
            break;
        }
        c = yylex();
    }
}
"/\*"                           {
    // RETURN_TOKEN(BLOCKCOMMENT);
    char c = yylex();
    while(1) {
        if (c == '*') {
            c = yylex();
            if (c == '/') {
                break;
            }else{
                unput(c);
            }
        }else if (c == EOF) {
            if(isNewError(yylineno, yytext[0])){
                printf("Error type B at Line %d: Block comment is not closed.\n", yylineno);
            }
            break;
        }
        c = yylex();
    }
    return yytext[0];
}
"\*/"                           {
    if(isNewError(yylineno, yytext[0])){
        printf("Error type B at Line %d: Block comment is not closed.\n", yylineno);
    }
    return yytext[0];
}
.                               {
    printf("Unknown character [%c]\n",yytext[0]);   
    return yytext[0];
}

%% 

void scan_string(const char *str, yyscan_t scanner) {
  yy_switch_to_buffer(yy_scan_string(str, scanner), scanner);
}

int main(void)
{
    return 0;
}
