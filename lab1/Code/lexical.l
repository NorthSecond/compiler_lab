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
int|float                     {
    // printf("TYPE: %s\n", yytext);
    yylval.string=strdup(yytext);
    RETURN_TOKEN(TYPE);}
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
    // UPDATE: PPT里要求这种必须是错误类型 A
    // 不能放到语法分析处理了
    /*
    0{OCT}*                         |
    0[Xx]{HEX}+                     |
    [1-9]{DIGIT}*
    */
    if(yytext[0] == '0'){
        if(strlen(yytext) == 1){
            yylval.number=0;
            RETURN_TOKEN(INT);
        }
        // TODO: strtol 需不需要前进一下位数
        if(yytext[1] == 'x' || yytext[1] == 'X'){
            // 十六进制
            if(strlen(yytext) == 2){
                if(isNewError(yylineno, 'B')){
                    printf("Error type A at Line %d: Illegal hexadecimal number \"%s\".\n", yylineno, yytext);
                    return;
                }
            }
            for(int i = 2; i< strlen(yytext); i++){
                if(!isxdigit(yytext[i])){
                    if(isNewError(yylineno, 'B')){
                        printf("Error type A at Line %d: Illegal hexadecimal number \"%s\".\n", yylineno, yytext);
                        return;
                    }
                }
            }
            yylval.number=strtol(yytext, NULL, 16);
            RETURN_TOKEN(INT);
        }
        // 八进制
        for(int i = 1; i< strlen(yytext); i++){
            if(yytext[i] < '0' || yytext[i] > '7'){
                if(isNewError(yylineno, 'B')){
                    printf("Error type A at Line %d: Illegal octal number \"%s\".\n", yylineno, yytext);
                    return;
                }
            }
        }

        yylval.number=strtol(yytext, NULL, 8);
        RETURN_TOKEN(INT);
    }

    yylval.number=atoi(yytext);
    RETURN_TOKEN(INT);
}
{DIGIT}*{DOT}{DIGIT}*[Ee][+-]?{DIGIT}*    |
{DIGIT}*{DOT}{DIGIT}*                     {
    // 和上面一样的改动
    // {DIGIT}*{DOT}{DIGIT}*[Ee][+-]?{DIGIT}+     |
    // (0|[1-9]{DIGIT}*){DOT}{DIGIT}+

    size_t len = strlen(yytext);
    if(yytext[len-1] == 'e' || yytext[len-1] == 'E' || yytext[len-1] == '.' || yytext[len-1] == '+' || yytext[len-1] == '-'){
        if(isNewError(yylineno, 'B')){
            printf("Error type A at Line %d: Illegal floating point number \"%s\".\n", yylineno, yytext);
            return;
        }
    }

    
    if(yytext[0] == '.'){
        // 需要检查后面带不带 e/E
        bool hasE = false;
        for(int i = 1; i < len; i++){
            if(yytext[i] == 'e' || yytext[i] == 'E'){
                if(i == 1) {
                    if(isNewError(yylineno, 'B')){
                        printf("Error type A at Line %d: Illegal floating point number \"%s\".\n", yylineno, yytext);
                        return;
                    }
                }
                hasE = true;
                break;
            }
        }
        if(!hasE){
            if(isNewError(yylineno, 'B')){
                printf("Error type A at Line %d: Illegal floating point number \"%s\".\n", yylineno, yytext);
                return;
            }
        }
    }

    yylval.floats=atof(yytext);
    // printf("FLOAT: %s\n", yytext);
    RETURN_TOKEN(FLOAT);
}
{LETTER}({LETTER}|{DIGIT})*     {
    yylval.string=strdup(yytext);
    // printf("ID: %s\n", yylval.string);
    RETURN_TOKEN(ID);
}

.                               {
    // FIXME: error type A 但是一行只能一个错误
    if(isNewError(yylineno, 'B')){
        printf("Error type A at Line %d: Undefined token \"%s\".\n", yylineno, yytext);
    }
    return yytext[0];
}

%% // end of rules
