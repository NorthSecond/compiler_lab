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

enum class SyntexTreeNodeType { 
    // 没有产生 e 的语法单元
    NONEPSILON,
    // 产生 e 的语法单元
    EPSILON,
    // 词法单元ID
    ID,
    // 词法单元TYPE
    TYPE,
    // 词法单元INT
    INT,
    // 词法单元FLOAT
    FLOAT
};

// 语法树的定义
// 语法树是多叉树
// 对应行号 子节点数量 子节点指针
typedef struct SyntaxTreeNode
{
    char *name;
    enum SyntaxTreeNodeType type;
    int lineno;
    union {
        int intVal;
        float floatVal;
        char *stringVal;
    };
    int childCount;
    struct SyntaxTreeNode *child;
    struct SyntaxTreeNode *sibling;
} SyntaxTree;

// 全局变量 语法树的根节点
Struct SyntaxTree *root = nullptr;

// 语法树的创建
SyntaxTree *createSyntaxTree(char *name, enum SyntaxTreeNodeType type, int lineno)
{
    SyntaxTree *node = (SyntaxTree *)malloc(sizeof(SyntaxTree));
    node->name = name;
    node->type = type;
    node->lineno = lineno;
    node->childCount = 0;
    node->child = NULL;
    node->sibling = NULL;
    return node;
}

// 语法树的遍历
// 这里使用先序遍历
void traverseSyntaxTree(SyntaxTree *root, int indent)
{
    if (root == NULL)
    {
        return;
    }
    for (int i = 0; i < indent; i++)
    {
        printf("  ");
    }
    // 先序遍历
    printf("%s (%d) \r \n", root->name, root->lineno);
    traverseSyntaxTree(root->child, indent + 1);
    traverseSyntaxTree(root->sibling, indent);
}

// 打印节点信息
// 考虑一下要不要放这里 还是换个位置提出来到别的文件里面
void printNodeInfo(SyntaxTree *node)
{
    if (node == NULL)
    {
        return;
    }
    switch (node->type)
    {
    case NONEPSILON:
        // 打印语法单元的名称和对应在输入文件中的行号
        printf("%s (%d) \r \n", node->name, node->lineno);
        break;
    case EPSILON:
        // 无需打印语法单元对应的信息
        // printf("%s (%d) \r \n", node->name, node->lineno);
        break;
    case ID:
        // 额外打印对应的词素
        printf("%s (%d): %s \r \n", node->name, node->lineno, node->stringVal);
        break;
    case TYPE:
        // 额外打印对应的类型
        printf("%s (%d): %s \r \n", node->name, node->lineno, node->stringVal);
        break;
    case INT:
        // 额外打印对应的整数值
        printf("%s (%d): %d \r \n", node->name, node->lineno, node->intVal);
        break;
    case FLOAT:
        // 额外打印对应的浮点数值
        printf("%s (%d): %f \r \n", node->name, node->lineno, node->floatVal);
        break;
    default:
        break;
    }
}


// 语法树的销毁
void destroySyntaxTree(SyntaxTree *root)
{
    if (root == NULL)
    {
        return;
    }
    destroySyntaxTree(root->child);
    destroySyntaxTree(root->sibling);
    free(root);
}

// 语法树的插入
// 对应多叉树的插入

%}

%union {
    char    *string;
    int     number;
    float   floats;
    struct  SyntaxTreeNode *type_pnode;
}

%define api.pure full
%lex-param { yyscan_t scanner }
%parse-param { void *scanner }

/* tokens */
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

/* numbers */
%token <number> INT
%token <floats> FLOAT
%token <string> ID

/* precedence and associativity */

%nonassoc error
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

/* non-terminals */
%type <type_pnode> Program
                   ExtDefList
                   ExtDef
                   Specifier
                   ExtDecList  
                   StructSpecifier
                   OptTag
                   Tag
                   VarDec
                   FunDec
                   VarList
                   ParamDec
                   CompSt
                   StmtList
                   Stmt
                   DefList
                   Def
                   DecList
                   Dec
                   Exp
                   Args
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
| ExtDefList error {

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
