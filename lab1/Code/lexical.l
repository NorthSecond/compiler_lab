%{
#include "includes.h"
#include "syntax.tab.h"

extern YYSTYPE yylval;

extern int isNewError(int err_line, char err_char);

#if YYDEBUG > 0
#define debug_printf  printf
#else
#define debug_printf(...)
#endif // YYDEBUG

int yycolumn = 1;
#define YY_USER_ACTION\
    yylloc.first_line=yylloc.last_line=yylineno;\
    yylloc.first_column=yycolumn;\
    yylloc.last_column=yycolumn+yyleng-1;\
    yycolumn+=yyleng;

// %option reentrant
// %option noyywrap
// %option bison-bridge

#define RETURN_TOKEN(token) debug_printf("%s\n",#token);return token
%}

/* Tokens for C--*/
%option yylineno


WHITE_SPACE         [ \t]
DIGIT               [0-9]
LETTER              [a-zA-Z_]
ALNUM               [a-zA-Z0-9_]
DOT                 \.
QUOTE               [\'\"]
HEX                 [0-9a-fA-F]
OCT                 [0-7]

%%

{WHITE_SPACE}+                  ;// ignore white space
\n                              {yycolumn = 1;}

"//"                            {
    char c = input();
    while (c != EOF) {
        if (c == '\n') {
            break;
        }
        c = input();
    }
}
"/\*"                           {
    char c = input();
    while(1) {
        if (c == '*') {
            c = input();
            if (c == '/') {
                break;
            }else{
                unput(c);
            }
        }else if (c == EOF) {
            if(isNewError(yylineno, 'B')){
                printf("Error type B at Line %d: Block comment is not closed.\n", yylineno);
            }
            break;
        }
        c = input();
    }
    // yylval.string=strdup(yytext);
    // return yytext[0];
}
"\*/"                           {
    if(isNewError(yylineno, 'B')){
        printf("Error type B at Line %d: Block comment is not closed.\n", yylineno);
    }
    // return yytext[0];
}

";"                             {RETURN_TOKEN(SEMI);}
","                             {RETURN_TOKEN(COMMA);}
"="                             {RETURN_TOKEN(ASSIGNOP);}
"<"                             |
">"                             |
"<="                            |
">="                            |
"=="                            |
"!="                            {RETURN_TOKEN(RELOP);}
"+"                             {RETURN_TOKEN(PLUS);}
"-"                             {RETURN_TOKEN(MINUS);}
"*"                             {RETURN_TOKEN(STAR);}
"/"                             {RETURN_TOKEN(DIV);}
"&&"                            {RETURN_TOKEN(AND);}
"\|\|"                          {RETURN_TOKEN(OR);}
{DOT}                           {RETURN_TOKEN(DOT);}
"!"                             {RETURN_TOKEN(NOT);}
int|float                       {
    // printf("TYPE: %s\n", yytext);
    yylval.string=strdup(yytext);
    RETURN_TOKEN(TYPE);
    }
"("                             {RETURN_TOKEN(LP);}
")"                             {RETURN_TOKEN(RP);}
"\["                            {RETURN_TOKEN(LB);}
"]"                             {RETURN_TOKEN(RB);}
"\{"                            {RETURN_TOKEN(LC);}
"}"                             {RETURN_TOKEN(RC);}
"struct"                        {RETURN_TOKEN(STRUCT);}
"return"                        {RETURN_TOKEN(RETURN);}
"if"                            {RETURN_TOKEN(IF);}
"else"                          {RETURN_TOKEN(ELSE);}
"while"                         {RETURN_TOKEN(WHILE);}

{DIGIT}+        |
0[Xx]{ALNUM}*   {
    // UPDATE: PPT???????????????????????????????????? A
    // ?????????????????????????????????
    /*
    0{OCT}*                         |
    0[Xx]{HEX}+                     |
    [1-9]{DIGIT}*
    */
    bool hasError = false;
    if(yytext[0] == '0'){
        if(strlen(yytext) == 1){
            yylval.number=0;
            RETURN_TOKEN(INT);
        }
        // TODO: strtol ??????????????????????????????
        if(yytext[1] == 'x' || yytext[1] == 'X'){
            // ????????????
            if(strlen(yytext) == 2){
                if(isNewError(yylineno, 'B')){
                    printf("Error type A at Line %d: Illegal hexadecimal number \"%s\".\n", yylineno, yytext);
                    hasError = true;
                }
            }
            for(int i = 2; i< strlen(yytext); i++){
                if(!isxdigit(yytext[i])){
                    if(isNewError(yylineno, 'B')){
                        printf("Error type A at Line %d: Illegal hexadecimal number \"%s\".\n", yylineno, yytext);
                        hasError = true;
                    }
                }
            }
            if(!hasError){
                yylval.number=strtol(yytext, NULL, 16);
                RETURN_TOKEN(INT);
            }
        }

        // ?????????
        for(int i = 1; i< strlen(yytext); i++){
            if(yytext[i] < '0' || yytext[i] > '7'){
                if(isNewError(yylineno, 'B')){
                    printf("Error type A at Line %d: Illegal octal number \"%s\".\n", yylineno, yytext);
                    hasError = true;
                }
            }
        }
        if(!hasError){
            yylval.number=strtol(yytext, NULL, 8);
            RETURN_TOKEN(INT);
        }
    }
    if(!hasError){
        yylval.number=atoi(yytext);
        RETURN_TOKEN(INT);
    }
}
{DIGIT}*{DOT}{DIGIT}*[Ee][+-]?{DIGIT}*    |
{DIGIT}*{DOT}{DIGIT}*                     {
    // ????????????????????????
    // {DIGIT}*{DOT}{DIGIT}*[Ee][+-]?{DIGIT}+     |
    // (0|[1-9]{DIGIT}*){DOT}{DIGIT}+

    bool hasError = false;
    size_t len = strlen(yytext);
    if(yytext[len-1] == 'e' || yytext[len-1] == 'E' || yytext[len-1] == '.' || yytext[len-1] == '+' || yytext[len-1] == '-'){
        if(isNewError(yylineno, 'B')){
            printf("Error type A at Line %d: Illegal floating point number \"%s\".\n", yylineno, yytext);
            hasError = true;
        }
    }

    
    if(yytext[0] == '.'){
        // ??????????????????????????? e/E
        bool hasE = false;
        for(int i = 1; i < len; i++){
            if(yytext[i] == 'e' || yytext[i] == 'E'){
                if(i == 1) {
                    if(isNewError(yylineno, 'B')){
                        printf("Error type A at Line %d: Illegal floating point number \"%s\".\n", yylineno, yytext);
                        hasError = true;
                    }
                }
                hasE = true;
                break;
            }
        }
        if(!hasE){
            if(isNewError(yylineno, 'B')){
                printf("Error type A at Line %d: Illegal floating point number \"%s\".\n", yylineno, yytext);
                hasError = true;
            }
        }
    }

    if(!hasError){
        yylval.floats=atof(yytext);
        // printf("FLOAT: %s\n", yytext);
        RETURN_TOKEN(FLOAT);
    }
}
{LETTER}({LETTER}|{DIGIT})*     {
    yylval.string=strdup(yytext);
    // printf("ID: %s\n", yylval.string);
    RETURN_TOKEN(ID);
}

.                               {
    // error type A ??????????????????????????????
    if(isNewError(yylineno, 'B')){
        printf("Error type A at Line %d: Undefined token \"%s\".\n", yylineno, yytext);
    }
}

%% // end of rules
