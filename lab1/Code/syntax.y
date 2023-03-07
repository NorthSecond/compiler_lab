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

extern int yyerror();
// int yyerror(size_t err_line, const char err_char);
int isNewError(int errorLineno, const char errorChar);

// extern int yylex();
// extern int yyparse(void);
extern int yywrap();
extern size_t yylineno;


FILE *yyin;
// out is not used
// we use printf instead
// FILE *yyout;

char *yytext;

/**
 * 词法单元的类型
 * NONEPSILON: 没有产生 \epsilon 的语法单元
 * EPSILON: 产生 \eplison 的语法单元
 * ID: 词法单元ID
 * TYPE: 词法单元TYPE
 * INT: 词法单元INT
 * FLOATS: 词法单元FLOAT
 * NONVALUE: 不产生语法单元的词法单元
 */
enum SyntaxTreeNodeType { 
    NONEPSILON,
    EPSILON,
    ID,
    TYPE,
    INT,
    FLOATS,
    NONVALUE
};

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

// 语法树的创建
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
void printNodeInfo(struct SyntaxTreeNode *node)
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

    // 如果当前节点是词法单元 无需打印行号
    case ID:
        // 额外打印对应的词素
        printf("%s: %s \r \n", node->name, node->stringVal);
        break;
    case TYPE:
        // 额外打印对应的类型
        printf("%s: %s \r \n", node->name, node->stringVal);
        break;
    case INT:
        // 额外打印对应的整数值
        printf("%s: %d \r \n", node->name, node->intVal);
        break;
    case FLOATS:
        // 额外打印对应的浮点数值
        printf("%s: %f \r \n", node->name, node->floatVal);
        break;
    case NONVALUE:
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
    for (int i = 0; i < indent; i++)
    {
        // 用两个空格缩进
        printf("  ");
    }
    
#ifdef LAB1
    // LAB 1: 打印节点信息
    printNodeInfo(root);
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

%union {
    char    *string;
    int     number;
    float   floats;
    struct  SyntaxTreeNode *type_pnode;
}

/* %define api.pure full */
/* %lex-param { yyscan_t scanner } */
/* %parse-param { void *scanner } */

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
    struct SyntaxTreeNode* nodeProgram = createNewNode("Program", NONEPSILON, @$.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*) $1, nodeProgram);

    $$ = nodeProgram;

    syntaxTreeRoot = $$;
} 
| ExtDefList error {
    if(isNewError(@2.first_line, 'B')) {
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Unexpected zharacter. \r \n", @2.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @2.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeErr);

        struct SyntaxTreeNode* nodeProgram = createNewNode("Program", NONEPSILON, @2.first_line);

        $$ = nodeProgram;
        syntaxTreeRoot = $$;
    } else {
        $$ = NULL;
    }
}

ExtDefList : ExtDef ExtDefList {
    struct SyntaxTreeNode* nodeExtDefList = createNewNode("ExtDefList", EPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExtDefList);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeExtDefList);
    $$ = nodeExtDefList;
} 
| {
    $$ = NULL;
}

ExtDef : Specifier ExtDecList SEMI {
    struct SyntaxTreeNode* nodeExtDef = createNewNode("ExtDef", EPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExtDef);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeExtDef);
    struct SyntaxTreeNode* nodeSemi = createNewNode("SEMI", SEMI, @3.first_line);
    insertSyntaxTree(nodeSemi, nodeExtDef);

    $$ = nodeExtDef;
}
| Specifier SEMI {
    struct SyntaxTreeNode* nodeExtDef = createNewNode("ExtDef", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExtDef);
    struct SyntaxTreeNode* nodeSemi = createNewNode("SEMI", SEMI, @2.first_line);
    insertSyntaxTree(nodeSemi, nodeExtDef);

    $$ = nodeExtDef;
}
| Specifier FunDec CompSt {
    struct SyntaxTreeNode* nodeExtDef = createNewNode("ExtDef", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExtDef);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeExtDef);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExtDef);

    $$ = nodeExtDef;
} 
| Specifier error {
    if(isNewError(@2.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \". \r \n", @2.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @2.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeErr);

        struct SyntaxTreeNode* nodeExtDef = createNewNode("ExtDef", NONEPSILON, @2.first_line);
        insertSyntaxTree(nodeErr, nodeExtDef);

        $$ = nodeExtDef;
    } else {
        $$ = NULL;
    }
}

ExtDecList : VarDec {
    struct SyntaxTreeNode* nodeExtDecList = createNewNode("ExtDecList", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExtDecList);

    $$ = nodeExtDecList;
}
| VarDec COMMA ExtDecList {
    struct SyntaxTreeNode* nodeExtDecList = createNewNode("ExtDecList", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExtDecList);
    struct SyntaxTreeNode* nodeComma = createNewNode("COMMA", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeComma, nodeExtDecList);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExtDecList);

    $$ = nodeExtDecList;
}

// Specifiers
Specifier : TYPE {
    struct SyntaxTreeNode* nodeSpecifier = createNewNode("Specifier", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeType = createNewNode("TYPE", NONVALUE, @1.first_line);
    insertSyntaxTree(nodeType, nodeSpecifier);

    $$ = nodeSpecifier;
}
| StructSpecifier {
    struct SyntaxTreeNode* nodeSpecifier = createNewNode("Specifier", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeSpecifier);

    $$ = nodeSpecifier;
}

StructSpecifier : STRUCT OptTag LC DefList RC {
    struct SyntaxTreeNode* nodeStructSpecifier = createNewNode("StructSpecifier", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeStruct = createNewNode("STRUCT", NONVALUE, @1.first_line);

    struct SyntaxTreeNode* nodeLC = createNewNode("LC", NONVALUE, @3.first_line);
    struct SyntaxTreeNode* nodeRC = createNewNode("RC", NONVALUE, @5.first_line);

    insertSyntaxTree(nodeStruct, nodeStructSpecifier);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeStructSpecifier);
    insertSyntaxTree(nodeLC, nodeStructSpecifier);
    insertSyntaxTree((struct SyntaxTreeNode*)$4, nodeStructSpecifier);
    insertSyntaxTree(nodeRC, nodeStructSpecifier);

    $$ = nodeStructSpecifier;
}
| STRUCT Tag {
    struct SyntaxTreeNode* nodeStructSpecifier = createNewNode("StructSpecifier", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeStruct = createNewNode("STRUCT", NONVALUE, @1.first_line);

    insertSyntaxTree(nodeStruct, nodeStructSpecifier);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeStructSpecifier);

    $$ = nodeStructSpecifier;
}
| STRUCT OptTag LC DefList error {
    if(isNewError(@5.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \"}\". \r \n", @5.first_line);
        
        struct SyntaxTreeNode* nodeStructSpecifier = createNewNode("StructSpecifier", NONEPSILON, @$.first_line);
        struct SyntaxTreeNode* nodeStruct = createNewNode("STRUCT", NONVALUE, @1.first_line);

        struct SyntaxTreeNode* nodeLC = createNewNode("LC", NONVALUE, @3.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @5.first_line);

        insertSyntaxTree(nodeStruct, nodeStructSpecifier);
        insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeStructSpecifier);
        insertSyntaxTree(nodeLC, nodeStructSpecifier);
        insertSyntaxTree((struct SyntaxTreeNode*)$4, nodeStructSpecifier);
        insertSyntaxTree(nodeErr, nodeStructSpecifier);

        $$ = nodeStructSpecifier;
    } else {
        $$ = NULL;
    }
}

OptTag : ID {
    struct SyntaxTreeNode* nodeOptTag = createNewNode("OptTag", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeID = createNewNode("ID", ID, @1.first_line);
    nodeID->stringVal = $1;

    insertSyntaxTree(nodeID, nodeOptTag);

    $$ = nodeOptTag;
}
| {
    struct SyntaxTreeNode* nodeOptTag = createNewNode("OptTag", NONEPSILON, @$.first_line);

    $$ = nodeOptTag;
}

Tag : ID {
    struct SyntaxTreeNode* nodeTag = createNewNode("Tag", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeID = createNewNode("ID", ID, @1.first_line);
    nodeID->stringVal = $1;

    insertSyntaxTree(nodeID, nodeTag);

    $$ = nodeTag;
}

// Declarators
VarDec : ID {
    struct SyntaxTreeNode* nodeVarDec = createNewNode("VarDec", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeID = createNewNode("ID", ID, @1.first_line);
    nodeID->stringVal = $1;

    insertSyntaxTree(nodeID, nodeVarDec);

    $$ = nodeVarDec;
}
| VarDec LB INT RB {
    struct SyntaxTreeNode* nodeVarDec = createNewNode("VarDec", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeLB = createNewNode("LB", NONVALUE, @2.first_line);
    struct SyntaxTreeNode* nodeINT = createNewNode("INT", INT, @3.first_line);
    nodeINT->intVal = $3;
    struct SyntaxTreeNode* nodeRB = createNewNode("RB", NONVALUE, @4.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeVarDec);
    insertSyntaxTree(nodeLB, nodeVarDec);
    insertSyntaxTree(nodeINT, nodeVarDec);
    insertSyntaxTree(nodeRB, nodeVarDec);

    $$ = nodeVarDec;
}
| VarDec LB error RB {
    if(isNewError(@3.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Syntax error at index, require INT value. \r \n", @3.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeErr);

        struct SyntaxTreeNode* nodeVarDec = createNewNode("VarDec", NONEPSILON, @3.first_line);
        insertSyntaxTree(nodeErr, nodeVarDec);

        $$ = nodeVarDec;
    } else {
        $$ = NULL;
    }
}
| VarDec LB INT error {
    if(isNewError(@4.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \"]\". \r \n", @4.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @4.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeErr);

        struct SyntaxTreeNode* nodeVarDec = createNewNode("VarDec", NONEPSILON, @4.first_line);
        insertSyntaxTree(nodeErr, nodeVarDec);

        $$ = nodeVarDec;
    } else {
        $$ = NULL;
    }
}

FunDec : ID LP VarList RP {
    struct SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeID = createNewNode("ID", ID, @1.first_line);
    nodeID->stringVal = $1;
    struct SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUE, @2.first_line);
    struct SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUE, @4.first_line);

    insertSyntaxTree(nodeID, nodeFunDec);
    insertSyntaxTree(nodeLP, nodeFunDec);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeFunDec);
    insertSyntaxTree(nodeRP, nodeFunDec);

    $$ = nodeFunDec;
}
| ID LP RP {
    // 参数为空
    struct SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeID = createNewNode("ID", ID, @1.first_line);
    nodeID->stringVal = $1;
    struct SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUE, @2.first_line);
    struct SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUE, @3.first_line);

    insertSyntaxTree(nodeID, nodeFunDec);
    insertSyntaxTree(nodeLP, nodeFunDec);
    insertSyntaxTree(nodeRP, nodeFunDec);

    $$ = nodeFunDec;
}
| ID LP error {
    if(isNewError(@3.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \")\". \r \n", @3.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeErr);

        struct SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @3.first_line);
        insertSyntaxTree(nodeErr, nodeFunDec);

        $$ = nodeFunDec;
    } else {
        $$ = NULL;
    }
}
| ID LP VarList error {
    if(isNewError(@4.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \")\". \r \n", @4.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @4.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeErr);

        struct SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @4.first_line);
        insertSyntaxTree(nodeErr, nodeFunDec);

        $$ = nodeFunDec;
    } else {
        $$ = NULL;
    }
}
| ID LP error VarList {
    if(isNewError(@3.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Syntax error after the \"(\". \r \n", @3.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*) $1, nodeErr);

        struct SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @3.first_line);
        insertSyntaxTree(nodeErr, nodeFunDec);

        $$ = nodeFunDec;
    } else {
        $$ = NULL;
    }
}
/* | ID LP error error {
    if(isNewError(@3.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Syntax error after the \"(\". \r \n", @3.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeErr);

        struct SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @3.first_line);
        insertSyntaxTree(nodeErr, nodeFunDec);

        $$ = nodeFunDec;
    } else {
        $$ = NULL;
    }
} */
| ID LP error RP {
    if(isNewError(@3.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Syntax error after the \"(\". \r \n", @3.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeErr);

        struct SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @3.first_line);
        insertSyntaxTree(nodeErr, nodeFunDec);

        $$ = nodeFunDec;
    } else {
        $$ = NULL;
    }
}
| ID error RP {
    if(isNewError(@2.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \"(\". \r \n", @2.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @2.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeErr);

        struct SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @2.first_line);
        insertSyntaxTree(nodeErr, nodeFunDec);

        $$ = nodeFunDec;
    } else {
        $$ = NULL;
    }
}


VarList : ParamDec COMMA VarList {
    struct SyntaxTreeNode* nodeVarList = createNewNode("VarList", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeCOMMA = createNewNode("COMMA", NONVALUE, @2.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeVarList);
    insertSyntaxTree(nodeCOMMA, nodeVarList);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeVarList);

    $$ = nodeVarList;
}
| ParamDec {
    struct SyntaxTreeNode* nodeVarList = createNewNode("VarList", NONEPSILON, @$.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeVarList);

    $$ = nodeVarList;
}

ParamDec : Specifier VarDec {
    struct SyntaxTreeNode* nodeParamDec = createNewNode("ParamDec", NONEPSILON, @$.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeParamDec);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeParamDec);

    $$ = nodeParamDec;
}

// Statements
CompSt : LC DefList StmtList RC {
    struct SyntaxTreeNode* nodeCompSt = createNewNode("CompSt", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeLC = createNewNode("LC", NONVALUE, @1.first_line);
    struct SyntaxTreeNode* nodeRC = createNewNode("RC", NONVALUE, @4.first_line);

    insertSyntaxTree(nodeLC, nodeCompSt);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeCompSt);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeCompSt);
    insertSyntaxTree(nodeRC, nodeCompSt);

    $$ = nodeCompSt;
}
| error DefList StmtList RC {
    if(isNewError(@1.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \"{\". \r \n", @1.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @1.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeErr);

        struct SyntaxTreeNode* nodeCompSt = createNewNode("CompSt", NONEPSILON, @1.first_line);
        insertSyntaxTree(nodeErr, nodeCompSt);

        $$ = nodeCompSt;
    } else {
        $$ = NULL;
    }
}

StmtList : Stmt StmtList {
    struct SyntaxTreeNode* nodeStmtList = createNewNode("StmtList", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @1.first_line);

    insertSyntaxTree(nodeStmt, nodeStmtList);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeStmtList);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeStmtList);

    $$ = nodeStmtList;
}
| {
    struct SyntaxTreeNode* nodeStmtList = createNewNode("StmtList", NONEPSILON, @$.first_line);

    $$ = nodeStmtList;
}

Stmt : Exp SEMI {
    struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeSEMI = createNewNode("SEMI", NONVALUE, @2.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeStmt);
    insertSyntaxTree(nodeSEMI, nodeStmt);

    $$ = nodeStmt;
}
| CompSt {
    struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @$.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeStmt);

    $$ = nodeStmt;
}
| RETURN Exp SEMI {
    struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeRETURN = createNewNode("RETURN", NONVALUE, @1.first_line);
    struct SyntaxTreeNode* nodeSEMI = createNewNode("SEMI", NONVALUE, @3.first_line);

    insertSyntaxTree(nodeRETURN, nodeStmt);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeStmt);
    insertSyntaxTree(nodeSEMI, nodeStmt);

    $$ = nodeStmt;
}
| RETURN Exp error {
    if(isNewError(@3.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \";\". \r \n", @3.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeErr);

        struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @3.first_line);
        insertSyntaxTree(nodeErr, nodeStmt);

        $$ = nodeStmt;
    } else {
        $$ = NULL;
    }
}
| IF LP Exp RP Stmt {
    struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeIF = createNewNode("IF", NONVALUE, @1.first_line);
    struct SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUE, @2.first_line);
    struct SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUE, @4.first_line);

    insertSyntaxTree(nodeIF, nodeStmt);
    insertSyntaxTree(nodeLP, nodeStmt);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeStmt);
    insertSyntaxTree(nodeRP, nodeStmt);
    insertSyntaxTree((struct SyntaxTreeNode*)$5, nodeStmt);

    $$ = nodeStmt;
}
| IF error Exp RP Stmt {
    if(isNewError(@2.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \"(\". \r \n", @2.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @2.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeErr);

        struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @2.first_line);
        insertSyntaxTree(nodeErr, nodeStmt);

        $$ = nodeStmt;
    } else {
        $$ = NULL;
    }
}
| IF LP Exp error Stmt {
    if(isNewError(@4.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \")\". \r \n", @4.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @4.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeErr);

        struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @4.first_line);
        insertSyntaxTree(nodeErr, nodeStmt);

        $$ = nodeStmt;
    } else {
        $$ = NULL;
    }
}
| IF LP Exp RP Stmt ELSE Stmt {
    struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeIF = createNewNode("IF", NONVALUE, @1.first_line);
    struct SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUE, @2.first_line);
    struct SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUE, @4.first_line);
    struct SyntaxTreeNode* nodeELSE = createNewNode("ELSE", NONVALUE, @6.first_line);

    insertSyntaxTree(nodeIF, nodeStmt);
    insertSyntaxTree(nodeLP, nodeStmt);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeStmt);
    insertSyntaxTree(nodeRP, nodeStmt);
    insertSyntaxTree((struct SyntaxTreeNode*)$5, nodeStmt);
    insertSyntaxTree(nodeELSE, nodeStmt);
    insertSyntaxTree((struct SyntaxTreeNode*)$7, nodeStmt);

    $$ = nodeStmt;
}
| IF LP Exp RP Stmt ELSE error {
    if(isNewError(@7.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Syntax error after \"else\". \r \n", @7.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @7.first_line);

        struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @7.first_line);
        insertSyntaxTree(nodeErr, nodeStmt);

        $$ = nodeStmt;
    } else {
        $$ = NULL;
    }
}
| WHILE LP Exp RP Stmt {
    struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeWHILE = createNewNode("WHILE", NONVALUE, @1.first_line);
    struct SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUE, @2.first_line);
    struct SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUE, @4.first_line);

    insertSyntaxTree(nodeWHILE, nodeStmt);
    insertSyntaxTree(nodeLP, nodeStmt);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeStmt);
    insertSyntaxTree(nodeRP, nodeStmt);
    insertSyntaxTree((struct SyntaxTreeNode*)$5, nodeStmt);

    $$ = nodeStmt;
}
| WHILE error Exp RP Stmt {
    if(isNewError(@2.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \"(\". \r \n", @2.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @2.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeErr);

        struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @2.first_line);
        insertSyntaxTree(nodeErr, nodeStmt);

        $$ = nodeStmt;
    } else {
        $$ = NULL;
    }
}
| WHILE LP Exp error Stmt {
    if(isNewError(@4.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \")\". \r \n", @4.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @4.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeErr);

        struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @4.first_line);
        insertSyntaxTree(nodeErr, nodeStmt);

        $$ = nodeStmt;
    } else {
        $$ = NULL;
    }
}
/* | WHILE LP Exp RP Stmt error {
    if(isNewError(@6.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Syntax error after \"while\". \r \n", @6.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @6.first_line);

        struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @6.first_line);
        insertSyntaxTree(nodeErr, nodeStmt);

        $$ = nodeStmt;
    } else {
        $$ = NULL;
    }
} */

// Local Definitions
DefList : Def DefList {
    struct SyntaxTreeNode* nodeDefList = createNewNode("DefList", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeDefList);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeDefList);

    $$ = nodeDefList;
}
| {
    struct SyntaxTreeNode* nodeDefList = createNewNode("DefList", NONEPSILON, @$.first_line);
    
    $$ = nodeDefList;
}

Def : Specifier DecList SEMI {
    struct SyntaxTreeNode* nodeDef = createNewNode("Def", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeDef);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeDef);
    struct SyntaxTreeNode* nodeSEMI = createNewNode("SEMI", NONVALUE, @3.first_line);
    insertSyntaxTree(nodeSEMI, nodeDef);

    $$ = nodeDef;
}

DecList : Dec {
    struct SyntaxTreeNode* nodeDecList = createNewNode("DecList", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeDecList);

    $$ = nodeDecList;
}
| Dec COMMA DecList {
    struct SyntaxTreeNode* nodeDecList = createNewNode("DecList", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeDecList);
    struct SyntaxTreeNode* nodeCOMMA = createNewNode("COMMA", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeCOMMA, nodeDecList);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeDecList);

    $$ = nodeDecList;
}
| Dec error DecList {
    if(isNewError(@2.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \",\". \r \n", @2.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @2.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeErr);
        insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeErr);

        struct SyntaxTreeNode* nodeDecList = createNewNode("DecList", NONEPSILON, @2.first_line);
        insertSyntaxTree(nodeErr, nodeDecList);

        $$ = nodeDecList;
    } else {
        $$ = NULL;
    }
}
| Dec COMMA error {
    if(isNewError(@3.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Syntax error after \",\". \r \n", @3.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeErr);

        struct SyntaxTreeNode* nodeDecList = createNewNode("DecList", NONEPSILON, @3.first_line);
        insertSyntaxTree(nodeErr, nodeDecList);

        $$ = nodeDecList;
    } else {
        $$ = NULL;
    }
}

Dec : VarDec {
    struct SyntaxTreeNode* nodeDec = createNewNode("Dec", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeDec);

    $$ = nodeDec;
}
| VarDec ASSIGNOP Exp {
    struct SyntaxTreeNode* nodeDec = createNewNode("Dec", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeDec);

    struct SyntaxTreeNode* nodeASSIGNOP = createNewNode("ASSIGNOP", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeASSIGNOP, nodeDec);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeDec);

    $$ = nodeDec;
}
| VarDec error Exp {
    if(isNewError(@2.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \"=\". \r \n", @2.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @2.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeErr);
        insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeErr);

        struct SyntaxTreeNode* nodeDec = createNewNode("Dec", NONEPSILON, @2.first_line);
        insertSyntaxTree(nodeErr, nodeDec);

        $$ = nodeDec;
    } else {
        $$ = NULL;
    }
}
| VarDec ASSIGNOP error {
    if(isNewError(@3.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Syntax error after \"=\". \r \n", @3.first_line);

        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeErr);

        struct SyntaxTreeNode* nodeDec = createNewNode("Dec", NONEPSILON, @3.first_line);
        insertSyntaxTree(nodeErr, nodeDec);

        $$ = nodeDec;
    } else {
        $$ = NULL;
    }
}

// Expressions
Exp : Exp ASSIGNOP Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    struct SyntaxTreeNode* nodeASSIGNOP = createNewNode("ASSIGNOP", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeASSIGNOP, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp AND Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    struct SyntaxTreeNode* nodeAND = createNewNode("AND", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeAND, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp OR Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    struct SyntaxTreeNode* nodeOR = createNewNode("OR", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeOR, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp RELOP Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    struct SyntaxTreeNode* nodeRELOP = createNewNode("RELOP", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeRELOP, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp PLUS Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    struct SyntaxTreeNode* nodePLUS = createNewNode("PLUS", NONVALUE, @2.first_line);
    insertSyntaxTree(nodePLUS, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp MINUS Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    struct SyntaxTreeNode* nodeMINUS = createNewNode("MINUS", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeMINUS, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp STAR Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    struct SyntaxTreeNode* nodeSTAR = createNewNode("STAR", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeSTAR, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp DIV Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    struct SyntaxTreeNode* nodeDIV = createNewNode("DIV", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeDIV, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| LP Exp RP {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUE, @1.first_line);
    insertSyntaxTree(nodeLP, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeExp);
    struct SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUE, @3.first_line);
    insertSyntaxTree(nodeRP, nodeExp);

    $$ = nodeExp;
}
| MINUS Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeMINUS = createNewNode("MINUS", NONVALUE, @1.first_line);
    insertSyntaxTree(nodeMINUS, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeExp);

    $$ = nodeExp;
}
| NOT Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeNOT = createNewNode("NOT", NONVALUE, @1.first_line);
    insertSyntaxTree(nodeNOT, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeExp);

    $$ = nodeExp;
}
| ID LP Args RP {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeID = createNewNode("ID", NONVALUE, @1.first_line);
    insertSyntaxTree(nodeID, nodeExp);
    struct SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeLP, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);
    struct SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUE, @4.first_line);
    insertSyntaxTree(nodeRP, nodeExp);

    $$ = nodeExp;
}
| ID LP RP {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeID = createNewNode("ID", NONVALUE, @1.first_line);
    insertSyntaxTree(nodeID, nodeExp);
    struct SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeLP, nodeExp);
    struct SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUE, @3.first_line);
    insertSyntaxTree(nodeRP, nodeExp);

    $$ = nodeExp;
}
| Exp LB Exp RB {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    struct SyntaxTreeNode* nodeLB = createNewNode("LB", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeLB, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);
    struct SyntaxTreeNode* nodeRB = createNewNode("RB", NONVALUE, @4.first_line);
    insertSyntaxTree(nodeRB, nodeExp);

    $$ = nodeExp;
}
| Exp DOT ID {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    struct SyntaxTreeNode* nodeDOT = createNewNode("DOT", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeDOT, nodeExp);
    struct SyntaxTreeNode* nodeID = createNewNode("ID", NONVALUE, @3.first_line);
    insertSyntaxTree(nodeID, nodeExp);

    $$ = nodeExp;
}
| ID {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeID = createNewNode("ID", NONVALUE, @1.first_line);
    insertSyntaxTree(nodeID, nodeExp);

    $$ = nodeExp;
}
| INT {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeINT = createNewNode("INT", INT, @1.first_line);
    // nodeINT->intVal = (int)strtol($1, NULL, 10);
    nodeINT->intVal = (int)$1;
    insertSyntaxTree(nodeINT, nodeExp);

    $$ = nodeExp;
}
| FLOAT {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeFLOAT = createNewNode("FLOAT", FLOATS, @1.first_line);
    // nodeFLOAT->floatVal = (float)strtod($1, NULL);
    nodeFLOAT->floatVal = (float)$1;
    insertSyntaxTree(nodeFLOAT, nodeExp);

    $$ = nodeExp;
}


Args : Exp COMMA Args {
    struct SyntaxTreeNode* nodeArgs = createNewNode("Args", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeArgs);
    struct SyntaxTreeNode* nodeCOMMA = createNewNode("COMMA", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeCOMMA, nodeArgs);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeArgs);

    $$ = nodeArgs;
}
| Exp COMMA error {
    if(isNewError(@2.first_line, @2.first_column)) {
        errors[errorCount].lineno = @2.first_line;
        errors[errorCount].character = @2.first_column;
        errorCount++;

        printf("Error type B at Line %d: Missing argument after ',' \r \n", @2.first_line);

        struct SyntaxTreeNode* nodeArgs = createNewNode("Args", NONEPSILON, @$.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeArgs);
        struct SyntaxTreeNode* nodeCOMMA = createNewNode("COMMA", NONVALUE, @2.first_line);
        insertSyntaxTree(nodeCOMMA, nodeArgs);
        struct SyntaxTreeNode* nodeError = createNewNode("error", NONVALUE, @3.first_line);
        insertSyntaxTree(nodeError, nodeArgs);

        $$ = nodeArgs;
    } else {
        $$ = NULL;
    }
}
| Exp error Args {
    if(isNewError(@2.first_line, @2.first_column)) {
        errors[errorCount].lineno = @2.first_line;
        errors[errorCount].character = @2.first_column;
        errorCount++;

        printf("Error type B at Line %d: Missing ',' between arguments \r \n", @2.first_line);

        struct SyntaxTreeNode* nodeArgs = createNewNode("Args", NONEPSILON, @$.first_line);
        insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeArgs);
        struct SyntaxTreeNode* nodeError = createNewNode("error", NONVALUE, @2.first_line);
        insertSyntaxTree(nodeError, nodeArgs);
        insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeArgs);

        $$ = nodeArgs;
    } else {
        $$ = NULL;
    }
}
| Exp {
    struct SyntaxTreeNode* nodeArgs = createNewNode("Args", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeArgs);

    $$ = nodeArgs;
}


%%

/* int yyparse() {
    yyscan_t scanner;
    yylex_init(&scanner);
    yyset_in(yyin, scanner);
    yyparse(scanner);
    yylex_destroy(scanner);
    return 0;
} */

/* int yyerror(size_t err_line, const char err_char) {
    if (isNewError(err_line, err_char)) {
        errors[errorCount].lineno = err_line;
        errors[errorCount].character = err_char;
        errorCount++;
        return 1;
    }
    return 0;
} */

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

#ifdef LAB1
    if (errorCount == 0) {
        traverseSyntaxTree(syntaxTreeRoot, 0);
    }
#endif

    destroySyntaxTree(syntaxTreeRoot);
    return 0;
}
