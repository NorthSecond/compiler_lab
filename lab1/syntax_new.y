%locations
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "lex.yy.c"

#define MAX_IDENT_LEN 32
#define MAX_NUM_LEN 32
#define MAX_ERR_NUM 10000

#define LAB1

struct Error {
    int lineno;
    char character;
};

struct Error errors[MAX_ERR_NUM];
int errorCount = 0;
int errorLineno = 0;
char errorChar = '\0';

void yyerror(char const * msg) {
    if(isNewError(yylineno, 'B')){
        printf("Error type B at Line %d: %s\n", yylineno, msg);
    }
}
int isNewError(int errorLineno, const char errorChar){
    for(int i = 0; i < errorCount; i++){
        if(errors[i].lineno == errorLineno && errors[i].character == errorChar){
            return 0;
        }
    }

    // add new error
    errors[errorCount].lineno = errorLineno;
    errors[errorCount].character = errorChar;
    errorCount++;
    return 1;
}

extern int yywrap();
extern int yylineno;

FILE *yyin;
// out is not used
// we use printf instead
// FILE *yyout;

char *yytext;

// 语法树的定义
// 语法树是多叉树
// 对应行号 子节点数量 子节点指针
struct SyntaxTreeNode
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
};

// 全局变量 语法树的根节点
struct SyntaxTreeNode *syntaxTreeRoot = NULL;

// 语法树节点的创建
struct SyntaxTreeNode *createSyntaxTree(char *name, enum SyntaxTreeNodeType type, int lineno)
{
    struct SyntaxTreeNode *node = (struct SyntaxTreeNode *)malloc(sizeof(struct SyntaxTreeNode));
    node->name = name;
    node->type = type;
    node->lineno = lineno;
    node->childCount = 0;
    node->child = NULL;
    node->sibling = NULL;
    return node;
}

#ifdef LAB1
// 打印节点信息
// 考虑一下要不要放这里 还是换个位置提出来到别的文件里面
void printNodeInfo(struct SyntaxTreeNode *node, int indent)
{
    if (node == NULL)
    {
        return;
    }
    if(node->type != EPSILON) {
        for(int i = 0; i < indent; i++) {
            printf("  ");
        }
    }
    switch (node->type)
    {
    case NONEPSILON:
        // 打印语法单元的名称和对应在输入文件中的行号
        printf("%s (%d) \r \n", node->name, node->lineno);
        break;
    case EPSILON:
        // 无需打印语法单元对应的信息
#ifdef YYDEBUG
        printf("%s (%d) \r \n", node->name, node->lineno);
#endif // YYDEBUG
        break;

    // 如果当前节点是词法单元 无需打印行号
    case IDNODE:
        // 额外打印对应的词素
        printf("%s: %s \r \n", node->name, node->stringVal);
        break;
    case TYPENODE:
        // 额外打印对应的类型
        printf("%s: %s \r \n", node->name, node->stringVal);
        break;
    case INTNODE:
        // 额外打印对应的整数值
        printf("%s: %d \r \n", node->name, node->intVal);
        break;
    case FLOATNODE:
        // 额外打印对应的浮点数值
        printf("%s: %f \r \n", node->name, node->floatVal);
        break;
    case NONVALUENODE:
        printf("%s \r \n", node->name);
        break;
    default:
        break;
    }
}
#endif

// 语法树的遍历
// 这里使用先序遍历
void traverseSyntaxTree(struct SyntaxTreeNode *root, int indent)
{
    if (root == NULL)
    {
        return;
    }
    
#ifdef LAB1
    // LAB 1: 打印节点信息
    printNodeInfo(root, indent);
#endif
    
    for(struct SyntaxTreeNode *p = root->child; p != NULL; p = p->sibling)
    {
        traverseSyntaxTree(p, indent + 1);
    }
}

// 语法树的销毁
void destroySyntaxTree(struct SyntaxTreeNode *root)
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
void insertSyntaxTree(struct SyntaxTreeNode *root, struct SyntaxTreeNode *node)
{
    if (root == NULL || node == NULL)
    {
#if YYDEBUG > 0
        printf("insert error: root or node is NULL \r \n");
#endif // YYDEBUG
        return;
    }
    if (root->child == NULL)
    {
        root->child = node;
    }
    else
    {
        struct SyntaxTreeNode *p = root->child;
        while (p->sibling != NULL)
        {
            p = p->sibling;
        }
        p->sibling = node;
    }
    root->childCount++;
}

// create new node
// 创建新的语法树节点
struct SyntaxTreeNode *createNewNode(char *name, enum SyntaxTreeNodeType type, int lineno)
{
    struct SyntaxTreeNode *node = (struct SyntaxTreeNode *)malloc(sizeof(struct SyntaxTreeNode));
    node->name = name;
    node->type = type;
    node->lineno = lineno;
    node->childCount = 0;
    node->child = NULL;
    node->sibling = NULL;
    return node;
}

%}

%error-verbose
%define parse.lac full

%union {
    char    *string;
    int     number;
    float   floats;
    struct  SyntaxTreeNode *type_pnode;
}

/* tokens */
%token              SEMI
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
%token <number>     INT
%token <floats>     FLOAT
%token <string>     ID
%token <string>     TYPE

/* precedence and associativity */

%right              ASSIGNOP
                    NOT
%left               OR
                    AND
                    RELOP
                    PLUS MINUS
                    STAR DIV
                    DOT
                    LB 
                    RB
                    LP 
                    RP
%nonassoc           ELSE
                    error
                    LOWER_THAN_ELSE

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

Program : ExtDefList {
    $$ = createNewNode("Program", NONEPSILON, 0);
    insertSyntaxTree($$, $1);
    syntaxTreeRoot = $$;
}

ExtDefList : ExtDef ExtDefList {
    $$ = createNewNode("ExtDefList", NONEPSILON, 0);
    insertSyntaxTree($$, $1);
    insertSyntaxTree($$, $2);
}