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
    FLOAT,
    // 不产生语法单元的词法单元
    NONVALUE
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
    // printf("%s (%d) \r \n", root->name, root->lineno);
    printNodeInfo(root);
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
    case FLOAT:
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
void insertSyntaxTree(SyntaxTree *root, SyntaxTreeNode *node)
{
    if (root == NULL)
    {
        return;
    }
    if (root->child == NULL)
    {
        root->child = node;
    }
    else
    {
        SyntaxTree *p = root->child;
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
SyntaxTreeNode *createNewNode(char *name, enum SyntaxTreeNodeType type, int lineno)
{
    Struct SyntaxTreeNode *node = (SyntaxTreeNode *)malloc(sizeof(SyntaxTreeNode));
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
    SyntaxTreeNode* nodeProgram = createNewNode("Program", NONEPSILON, @$.first_line);

    insertSyntaxTree((SyntaxTreeNode* $1), nodeProgram);

    $$ = nodeProgram;

    syntaxTreeRoot = $$;
} 
| ExtDefList error {
    if(isNewError(@2.first_line, 'B')) {
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Unexpected zharacter. \r \n", @2.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @2.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$1, nodeErr);

        SyntaxTreeNode* nodeProgram = createNewNode("Program", NONEPSILON, @2.first_line);

        $$ = nodeProgram;
        syntaxTreeRoot = $$;
    } else {
        $$ = nullptr;
    }
}

ExtDefList : ExtDef ExtDefList {
    SyntaxTreeNode* nodeExtDefList = createNewNode("ExtDefList", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeExtDefList);
    insertSyntaxTree((SyntaxTreeNode*)$2, nodeExtDefList);
    $$ = nodeExtDefList;
} 
| {
    $$ = nullptr;
}

ExtDef : Specifier ExtDecList SEMI {
    SyntaxTreeNode* nodeExtDef = createNewNode("ExtDef", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeExtDef);
    insertSyntaxTree((SyntaxTreeNode*)$2, nodeExtDef);
    SyntaxTreeNode* nodeSemi = createNewNode("SEMI", SEMI, @3.first_line);
    insertSyntaxTree(nodeSemi, nodeExtDef);

    $$ = nodeExtDef;
}
| Specifier SEMI {
    SyntaxTreeNode* nodeExtDef = createNewNode("ExtDef", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeExtDef);
    SyntaxTreeNode* nodeSemi = createNewNode("SEMI", SEMI, @2.first_line);
    insertSyntaxTree(nodeSemi, nodeExtDef);

    $$ = nodeExtDef;
}
| Specifier FunDec CompSt {
    SyntaxTreeNode* nodeExtDef = createNewNode("ExtDef", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeExtDef);
    insertSyntaxTree((SyntaxTreeNode*)$2, nodeExtDef);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeExtDef);

    $$ = nodeExtDef;
} 
| Specifier error {
    if(isNewError(@2.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \". \r \n", @2.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @2.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$1, nodeErr);

        SyntaxTreeNode* nodeExtDef = createNewNode("ExtDef", NONEPSILON, @2.first_line);
        insertSyntaxTree(nodeErr, nodeExtDef);

        $$ = nodeExtDef;
    } else {
        $$ = nullptr;
    }
}

ExtDecList : VarDec {
    SyntaxTreeNode* nodeExtDecList = createNewNode("ExtDecList", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeExtDecList);

    $$ = nodeExtDecList;
}
| VarDec COMMA ExtDecList {
    SyntaxTreeNode* nodeExtDecList = createNewNode("ExtDecList", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeExtDecList);
    SyntaxTreeNode* nodeComma = createNewNode("COMMA", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeComma, nodeExtDecList);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeExtDecList);

    $$ = nodeExtDecList;
}

// Specifiers
Specifier : TYPE {
    Struct SyntaxTreeNode* nodeSpecifier = createNewNode("Specifier", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeType = createNewNode("TYPE", NONVALUE, @1.first_line);
    insertSyntaxTree(nodeType, nodeSpecifier);

    $$ = nodeSpecifier;
}
| StructSpecifier {
    SyntaxTreeNode* nodeSpecifier = createNewNode("Specifier", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeSpecifier);

    $$ = nodeSpecifier;
}

StructSpecifier : STRUCT OptTag LC DefList RC {
    SyntaxTreeNode* nodeStructSpecifier = createNewNode("StructSpecifier", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeStruct = createNewNode("STRUCT", NONVALUE, @1.first_line);

    SyntaxTreeNode* nodeLC = createNewNode("LC", NONVALUE, @3.first_line);
    SyntaxTreeNode* nodeRC = createNewNode("RC", NONVALUE, @5.first_line);

    insertSyntaxTree(nodeStruct, nodeStructSpecifier);
    insertSyntaxTree((SyntaxTreeNode*)$2, nodeStructSpecifier);
    insertSyntaxTree(nodeLC, nodeStructSpecifier);
    insertSyntaxTree((SyntaxTreeNode*)$4, nodeStructSpecifier);
    insertSyntaxTree(nodeRC, nodeStructSpecifier);

    $$ = nodeStructSpecifier;
}
| STRUCT Tag {
    SyntaxTreeNode* nodeStructSpecifier = createNewNode("StructSpecifier", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeStruct = createNewNode("STRUCT", NONVALUE, @1.first_line);

    insertSyntaxTree(nodeStruct, nodeStructSpecifier);
    insertSyntaxTree((SyntaxTreeNode*)$2, nodeStructSpecifier);

    $$ = nodeStructSpecifier;
}
| STRUCT OptTag LC DefList error {
    if(isNewError(@5.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \"}\". \r \n", @5.first_line);
        
        SyntaxTreeNode* nodeStructSpecifier = createNewNode("StructSpecifier", NONEPSILON, @$.first_line);
        SyntaxTreeNode* nodeStruct = createNewNode("STRUCT", NONVALUE, @1.first_line);

        SyntaxTreeNode* nodeLC = createNewNode("LC", NONVALUE, @3.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @5.first_line);

        insertSyntaxTree(nodeStruct, nodeStructSpecifier);
        insertSyntaxTree((SyntaxTreeNode*)$2, nodeStructSpecifier);
        insertSyntaxTree(nodeLC, nodeStructSpecifier);
        insertSyntaxTree((SyntaxTreeNode*)$4, nodeStructSpecifier);
        insertSyntaxTree(nodeErr, nodeStructSpecifier);

        $$ = nodeStructSpecifier;
    } else {
        $$ = nullptr;
    }
}

OptTag : ID {
    SyntaxTreeNode* nodeOptTag = createNewNode("OptTag", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeID = createNewNode("ID", ID, @1.first_line);
    nodeID->stringVal = $1;

    insertSyntaxTree(nodeID, nodeOptTag);

    $$ = nodeOptTag;
}
| {
    SyntaxTreeNode* nodeOptTag = createNewNode("OptTag", NONEPSILON, @$.first_line);

    $$ = nodeOptTag;
}

Tag : ID {
    SyntaxTreeNode* nodeTag = createNewNode("Tag", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeID = createNewNode("ID", ID, @1.first_line);
    nodeID->stringVal = $1;

    insertSyntaxTree(nodeID, nodeTag);

    $$ = nodeTag;
}

// Declarators
VarDec : ID {
    SyntaxTreeNode* nodeVarDec = createNewNode("VarDec", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeID = createNewNode("ID", ID, @1.first_line);
    nodeID->stringVal = $1;

    insertSyntaxTree(nodeID, nodeVarDec);

    $$ = nodeVarDec;
}
| VarDec LB INT RB {
    SyntaxTreeNode* nodeVarDec = createNewNode("VarDec", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeLB = createNewNode("LB", NONVALUE, @2.first_line);
    SyntaxTreeNode* nodeINT = createNewNode("INT", INT, @3.first_line);
    nodeINT->intVal = $3;
    SyntaxTreeNode* nodeRB = createNewNode("RB", NONVALUE, @4.first_line);

    insertSyntaxTree((SyntaxTreeNode*)$1, nodeVarDec);
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

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$1, nodeErr);

        SyntaxTreeNode* nodeVarDec = createNewNode("VarDec", NONEPSILON, @3.first_line);
        insertSyntaxTree(nodeErr, nodeVarDec);

        $$ = nodeVarDec;
    } else {
        $$ = nullptr;
    }
}
| VarDec LB INT error {
    if(isNewError(@4.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \"]\". \r \n", @4.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @4.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$1, nodeErr);

        SyntaxTreeNode* nodeVarDec = createNewNode("VarDec", NONEPSILON, @4.first_line);
        insertSyntaxTree(nodeErr, nodeVarDec);

        $$ = nodeVarDec;
    } else {
        $$ = nullptr;
    }
}

FunDec : ID LP VarList RP {
    SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeID = createNewNode("ID", ID, @1.first_line);
    nodeID->stringVal = $1;
    SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUE, @2.first_line);
    SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUE, @4.first_line);

    insertSyntaxTree(nodeID, nodeFunDec);
    insertSyntaxTree(nodeLP, nodeFunDec);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeFunDec);
    insertSyntaxTree(nodeRP, nodeFunDec);

    $$ = nodeFunDec;
}
| ID LP RP {
    // 参数为空
    SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeID = createNewNode("ID", ID, @1.first_line);
    nodeID->stringVal = $1;
    SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUE, @2.first_line);
    SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUE, @3.first_line);

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

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$1, nodeErr);

        SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @3.first_line);
        insertSyntaxTree(nodeErr, nodeFunDec);

        $$ = nodeFunDec;
    } else {
        $$ = nullptr;
    }
}
| ID LP VarList error {
    if(isNewError(@4.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \")\". \r \n", @4.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @4.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$1, nodeErr);

        SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @4.first_line);
        insertSyntaxTree(nodeErr, nodeFunDec);

        $$ = nodeFunDec;
    } else {
        $$ = nullptr;
    }
}
| ID LP error VarList {
    if(isNewError(@3.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Syntax error after the \"(\". \r \n", @3.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);
        insertSyntaxTree((SyntaxTreeNode* $1), nodeErr);

        SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @3.first_line);
        insertSyntaxTree(nodeErr, nodeFunDec);

        $$ = nodeFunDec;
    } else {
        $$ = nullptr;
    }
}
| ID LP error error {
    if(isNewError(@3.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Syntax error after the \"(\". \r \n", @3.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$1, nodeErr);

        SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @3.first_line);
        insertSyntaxTree(nodeErr, nodeFunDec);

        $$ = nodeFunDec;
    } else {
        $$ = nullptr;
    }
}
| ID LP error RP {
    if(isNewError(@3.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Syntax error after the \"(\". \r \n", @3.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$1, nodeErr);

        SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @3.first_line);
        insertSyntaxTree(nodeErr, nodeFunDec);

        $$ = nodeFunDec;
    } else {
        $$ = nullptr;
    }
}
| ID error RP {
    if(isNewError(@2.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \"(\". \r \n", @2.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @2.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$1, nodeErr);

        SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @2.first_line);
        insertSyntaxTree(nodeErr, nodeFunDec);

        $$ = nodeFunDec;
    } else {
        $$ = nullptr;
    }
}


VarList : ParamDec COMMA VarList {
    SyntaxTreeNode* nodeVarList = createNewNode("VarList", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeCOMMA = createNewNode("COMMA", NONVALUE, @2.first_line);

    insertSyntaxTree((SyntaxTreeNode*)$1, nodeVarList);
    insertSyntaxTree(nodeCOMMA, nodeVarList);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeVarList);

    $$ = nodeVarList;
}
| ParamDec {
    SyntaxTreeNode* nodeVarList = createNewNode("VarList", NONEPSILON, @$.first_line);

    insertSyntaxTree((SyntaxTreeNode*)$1, nodeVarList);

    $$ = nodeVarList;
}

ParamDec : Specifier VarDec {
    SyntaxTreeNode* nodeParamDec = createNewNode("ParamDec", NONEPSILON, @$.first_line);

    insertSyntaxTree((SyntaxTreeNode*)$1, nodeParamDec);
    insertSyntaxTree((SyntaxTreeNode*)$2, nodeParamDec);

    $$ = nodeParamDec;
}

// Statements
CompSt : LC DefList StmtList RC {
    SyntaxTreeNode* nodeCompSt = createNewNode("CompSt", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeLC = createNewNode("LC", NONVALUE, @1.first_line);
    SyntaxTreeNode* nodeRC = createNewNode("RC", NONVALUE, @4.first_line);

    insertSyntaxTree(nodeLC, nodeCompSt);
    insertSyntaxTree((SyntaxTreeNode*)$2, nodeCompSt);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeCompSt);
    insertSyntaxTree(nodeRC, nodeCompSt);

    $$ = nodeCompSt;
}
| error DefList StmtList RC {
    if(isNewError(@1.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \"{\". \r \n", @1.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @1.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$2, nodeErr);

        SyntaxTreeNode* nodeCompSt = createNewNode("CompSt", NONEPSILON, @1.first_line);
        insertSyntaxTree(nodeErr, nodeCompSt);

        $$ = nodeCompSt;
    } else {
        $$ = nullptr;
    }
}

StmtList : Stmt StmtList {
    SyntaxTreeNode* nodeStmtList = createNewNode("StmtList", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @1.first_line);

    insertSyntaxTree(nodeStmt, nodeStmtList);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeStmtList);
    insertSyntaxTree((SyntaxTreeNode*)$2, nodeStmtList);

    $$ = nodeStmtList;
}
| {
    SyntaxTreeNode* nodeStmtList = createNewNode("StmtList", NONEPSILON, @$.first_line);

    $$ = nodeStmtList;
}

Stmt : Exp SEMI {
    SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeSEMI = createNewNode("SEMI", NONVALUE, @2.first_line);

    insertSyntaxTree((SyntaxTreeNode*)$1, nodeStmt);
    insertSyntaxTree(nodeSEMI, nodeStmt);

    $$ = nodeStmt;
}
| CompSt {
    SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @$.first_line);

    insertSyntaxTree((SyntaxTreeNode*)$1, nodeStmt);

    $$ = nodeStmt;
}
| RETURN Exp SEMI {
    SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeRETURN = createNewNode("RETURN", NONVALUE, @1.first_line);
    SyntaxTreeNode* nodeSEMI = createNewNode("SEMI", NONVALUE, @3.first_line);

    insertSyntaxTree(nodeRETURN, nodeStmt);
    insertSyntaxTree((SyntaxTreeNode*)$2, nodeStmt);
    insertSyntaxTree(nodeSEMI, nodeStmt);

    $$ = nodeStmt;
}
| RETURN Exp error {
    if(isNewError(@3.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \";\". \r \n", @3.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$2, nodeErr);

        SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @3.first_line);
        insertSyntaxTree(nodeErr, nodeStmt);

        $$ = nodeStmt;
    } else {
        $$ = nullptr;
    }
}
| IF LP Exp RP Stmt {
    SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeIF = createNewNode("IF", NONVALUE, @1.first_line);
    SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUE, @2.first_line);
    SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUE, @4.first_line);

    insertSyntaxTree(nodeIF, nodeStmt);
    insertSyntaxTree(nodeLP, nodeStmt);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeStmt);
    insertSyntaxTree(nodeRP, nodeStmt);
    insertSyntaxTree((SyntaxTreeNode*)$5, nodeStmt);

    $$ = nodeStmt;
}
| IF error Exp RP Stmt {
    if(isNewError(@2.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \"(\". \r \n", @2.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @2.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$3, nodeErr);

        SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @2.first_line);
        insertSyntaxTree(nodeErr, nodeStmt);

        $$ = nodeStmt;
    } else {
        $$ = nullptr;
    }
}
| IF LP Exp error Stmt {
    if(isNewError(@4.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \")\". \r \n", @4.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @4.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$3, nodeErr);

        SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @4.first_line);
        insertSyntaxTree(nodeErr, nodeStmt);

        $$ = nodeStmt;
    } else {
        $$ = nullptr;
    }
}
| IF LP Exp RP Stmt ELSE Stmt {
    SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeIF = createNewNode("IF", NONVALUE, @1.first_line);
    SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUE, @2.first_line);
    SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUE, @4.first_line);
    SyntaxTreeNode* nodeELSE = createNewNode("ELSE", NONVALUE, @6.first_line);

    insertSyntaxTree(nodeIF, nodeStmt);
    insertSyntaxTree(nodeLP, nodeStmt);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeStmt);
    insertSyntaxTree(nodeRP, nodeStmt);
    insertSyntaxTree((SyntaxTreeNode*)$5, nodeStmt);
    insertSyntaxTree(nodeELSE, nodeStmt);
    insertSyntaxTree((SyntaxTreeNode*)$7, nodeStmt);

    $$ = nodeStmt;
}
| IF LP Exp RP Stmt ELSE error {
    if(isNewError(@7.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Syntax error after \"else\". \r \n", @7.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @7.first_line);

        SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @7.first_line);
        insertSyntaxTree(nodeErr, nodeStmt);

        $$ = nodeStmt;
    } else {
        $$ = nullptr;
    }
}
| WHILE LP Exp RP Stmt {
    SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeWHILE = createNewNode("WHILE", NONVALUE, @1.first_line);
    SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUE, @2.first_line);
    SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUE, @4.first_line);

    insertSyntaxTree(nodeWHILE, nodeStmt);
    insertSyntaxTree(nodeLP, nodeStmt);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeStmt);
    insertSyntaxTree(nodeRP, nodeStmt);
    insertSyntaxTree((SyntaxTreeNode*)$5, nodeStmt);

    $$ = nodeStmt;
}
| WHILE error Exp RP Stmt {
    if(isNewError(@2.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \"(\". \r \n", @2.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @2.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$3, nodeErr);

        SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @2.first_line);
        insertSyntaxTree(nodeErr, nodeStmt);

        $$ = nodeStmt;
    } else {
        $$ = nullptr;
    }
}
| WHILE LP Exp error Stmt {
    if(isNewError(@4.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \")\". \r \n", @4.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @4.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$3, nodeErr);

        SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @4.first_line);
        insertSyntaxTree(nodeErr, nodeStmt);

        $$ = nodeStmt;
    } else {
        $$ = nullptr;
    }
}
| WHILE LP Exp RP Stmt error {
    if(isNewError(@6.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Syntax error after \"while\". \r \n", @6.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @6.first_line);

        SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @6.first_line);
        insertSyntaxTree(nodeErr, nodeStmt);

        $$ = nodeStmt;
    } else {
        $$ = nullptr;
    }
}

// Local Definitions
DefList : Def DefList {
    SyntaxTreeNode* nodeDefList = createNewNode("DefList", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeDefList);
    insertSyntaxTree((SyntaxTreeNode*)$2, nodeDefList);

    $$ = nodeDefList;
}
| {
    SyntaxTreeNode* nodeDefList = createNewNode("DefList", NONEPSILON, @$.first_line);
    
    $$ = nodeDefList;
}

Def : Specifier DecList SEMI {
    SyntaxTreeNode* nodeDef = createNewNode("Def", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeDef);
    insertSyntaxTree((SyntaxTreeNode*)$2, nodeDef);
    SyntaxTreeNode* nodeSEMI = createNewNode("SEMI", NONVALUE, @3.first_line);
    insertSyntaxTree(nodeSEMI, nodeDef);

    $$ = nodeDef;
}

DecList : Dec {
    SyntaxTreeNode* nodeDecList = createNewNode("DecList", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeDecList);

    $$ = nodeDecList;
}
| Dec COMMA DecList {
    SyntaxTreeNode* nodeDecList = createNewNode("DecList", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeDecList);
    SyntaxTreeNode* nodeCOMMA = createNewNode("COMMA", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeCOMMA, nodeDecList);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeDecList);

    $$ = nodeDecList;
}
| Dec error DecList {
    if(isNewError(@2.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \",\". \r \n", @2.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @2.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$1, nodeErr);
        insertSyntaxTree((SyntaxTreeNode*)$3, nodeErr);

        SyntaxTreeNode* nodeDecList = createNewNode("DecList", NONEPSILON, @2.first_line);
        insertSyntaxTree(nodeErr, nodeDecList);

        $$ = nodeDecList;
    } else {
        $$ = nullptr;
    }
}
| Dec COMMA error {
    if(isNewError(@3.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Syntax error after \",\". \r \n", @3.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$1, nodeErr);

        SyntaxTreeNode* nodeDecList = createNewNode("DecList", NONEPSILON, @3.first_line);
        insertSyntaxTree(nodeErr, nodeDecList);

        $$ = nodeDecList;
    } else {
        $$ = nullptr;
    }
}

Dec : VarDec {
    SyntaxTreeNode* nodeDec = createNewNode("Dec", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeDec);

    $$ = nodeDec;
}
| VarDec ASSIGNOP Exp {
    SyntaxTreeNode* nodeDec = createNewNode("Dec", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeDec);

    SyntaxTreeNode* nodeASSIGNOP = createNewNode("ASSIGNOP", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeASSIGNOP, nodeDec);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeDec);

    $$ = nodeDec;
}
| VarDec error Exp {
    if(isNewError(@2.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Missing \"=\". \r \n", @2.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @2.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$1, nodeErr);
        insertSyntaxTree((SyntaxTreeNode*)$3, nodeErr);

        SyntaxTreeNode* nodeDec = createNewNode("Dec", NONEPSILON, @2.first_line);
        insertSyntaxTree(nodeErr, nodeDec);

        $$ = nodeDec;
    } else {
        $$ = nullptr;
    }
}
| VarDec ASSIGNOP error {
    if(isNewError(@3.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Syntax error after \"=\". \r \n", @3.first_line);

        SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$1, nodeErr);

        SyntaxTreeNode* nodeDec = createNewNode("Dec", NONEPSILON, @3.first_line);
        insertSyntaxTree(nodeErr, nodeDec);

        $$ = nodeDec;
    } else {
        $$ = nullptr;
    }
}

// Expressions
Exp : Exp ASSIGNOP Exp {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeExp);
    SyntaxTreeNode* nodeASSIGNOP = createNewNode("ASSIGNOP", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeASSIGNOP, nodeExp);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp AND Exp {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeExp);
    SyntaxTreeNode* nodeAND = createNewNode("AND", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeAND, nodeExp);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp OR Exp {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeExp);
    SyntaxTreeNode* nodeOR = createNewNode("OR", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeOR, nodeExp);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp RELOP Exp {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeExp);
    SyntaxTreeNode* nodeRELOP = createNewNode("RELOP", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeRELOP, nodeExp);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp PLUS Exp {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeExp);
    SyntaxTreeNode* nodePLUS = createNewNode("PLUS", NONVALUE, @2.first_line);
    insertSyntaxTree(nodePLUS, nodeExp);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp MINUS Exp {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeExp);
    SyntaxTreeNode* nodeMINUS = createNewNode("MINUS", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeMINUS, nodeExp);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp STAR Exp {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeExp);
    SyntaxTreeNode* nodeSTAR = createNewNode("STAR", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeSTAR, nodeExp);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp DIV Exp {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeExp);
    SyntaxTreeNode* nodeDIV = createNewNode("DIV", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeDIV, nodeExp);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| LP Exp RP {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUE, @1.first_line);
    insertSyntaxTree(nodeLP, nodeExp);
    insertSyntaxTree((SyntaxTreeNode*)$2, nodeExp);
    SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUE, @3.first_line);
    insertSyntaxTree(nodeRP, nodeExp);

    $$ = nodeExp;
}
| MINUS Exp {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeMINUS = createNewNode("MINUS", NONVALUE, @1.first_line);
    insertSyntaxTree(nodeMINUS, nodeExp);
    insertSyntaxTree((SyntaxTreeNode*)$2, nodeExp);

    $$ = nodeExp;
}
| NOT Exp {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeNOT = createNewNode("NOT", NONVALUE, @1.first_line);
    insertSyntaxTree(nodeNOT, nodeExp);
    insertSyntaxTree((SyntaxTreeNode*)$2, nodeExp);

    $$ = nodeExp;
}
| ID LP Args RP {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeID = createNewNode("ID", NONVALUE, @1.first_line);
    insertSyntaxTree(nodeID, nodeExp);
    SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeLP, nodeExp);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeExp);
    SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUE, @4.first_line);
    insertSyntaxTree(nodeRP, nodeExp);

    $$ = nodeExp;
}
| ID LP RP {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeID = createNewNode("ID", NONVALUE, @1.first_line);
    insertSyntaxTree(nodeID, nodeExp);
    SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeLP, nodeExp);
    SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUE, @3.first_line);
    insertSyntaxTree(nodeRP, nodeExp);

    $$ = nodeExp;
}
| Exp LB Exp RB {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeExp);
    SyntaxTreeNode* nodeLB = createNewNode("LB", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeLB, nodeExp);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeExp);
    SyntaxTreeNode* nodeRB = createNewNode("RB", NONVALUE, @4.first_line);
    insertSyntaxTree(nodeRB, nodeExp);

    $$ = nodeExp;
}
| Exp DOT ID {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeExp);
    SyntaxTreeNode* nodeDOT = createNewNode("DOT", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeDOT, nodeExp);
    SyntaxTreeNode* nodeID = createNewNode("ID", NONVALUE, @3.first_line);
    insertSyntaxTree(nodeID, nodeExp);

    $$ = nodeExp;
}
| ID {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeID = createNewNode("ID", NONVALUE, @1.first_line);
    insertSyntaxTree(nodeID, nodeExp);

    $$ = nodeExp;
}
| INT {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeINT = createNewNode("INT", INT, @1.first_line);
    nodeINT->intVal = (int)strtol($1, NULL, 10);
    insertSyntaxTree(nodeINT, nodeExp);

    $$ = nodeExp;
}
| FLOAT {
    SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    SyntaxTreeNode* nodeFLOAT = createNewNode("FLOAT", FLOAT, @1.first_line);
    nodeFLOAT->floatVal = (float)strtod($1, NULL);
    insertSyntaxTree(nodeFLOAT, nodeExp);

    $$ = nodeExp;
}


Args : Exp COMMA Args {
    SyntaxTreeNode* nodeArgs = createNewNode("Args", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeArgs);
    SyntaxTreeNode* nodeCOMMA = createNewNode("COMMA", NONVALUE, @2.first_line);
    insertSyntaxTree(nodeCOMMA, nodeArgs);
    insertSyntaxTree((SyntaxTreeNode*)$3, nodeArgs);

    $$ = nodeArgs;
}
| Exp COMMA error {
    if(isNewError(@2.first_line, @2.first_column)) {
        errors[errorCount].lineno = @2.first_line;
        errors[errorCount].character = @2.first_column;
        errorCount++;

        prinft("Error type B at Line %d: Missing argument after ',' \r \n", @2.first_line);

        SyntaxTreeNode* nodeArgs = createNewNode("Args", NONEPSILON, @$.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$1, nodeArgs);
        SyntaxTreeNode* nodeCOMMA = createNewNode("COMMA", NONVALUE, @2.first_line);
        insertSyntaxTree(nodeCOMMA, nodeArgs);
        SyntaxTreeNode* nodeError = createNewNode("error", NONVALUE, @3.first_line);
        insertSyntaxTree(nodeError, nodeArgs);

        $$ = nodeArgs;
    } else {
        $$ = nullptr;
    }
}
| Exp error Args {
    if(isNewError(@2.first_line, @2.first_column)) {
        errors[errorCount].lineno = @2.first_line;
        errors[errorCount].character = @2.first_column;
        errorCount++;

        prinft("Error type B at Line %d: Missing ',' between arguments \r \n", @2.first_line);

        SyntaxTreeNode* nodeArgs = createNewNode("Args", NONEPSILON, @$.first_line);
        insertSyntaxTree((SyntaxTreeNode*)$1, nodeArgs);
        SyntaxTreeNode* nodeError = createNewNode("error", NONVALUE, @2.first_line);
        insertSyntaxTree(nodeError, nodeArgs);
        insertSyntaxTree((SyntaxTreeNode*)$3, nodeArgs);

        $$ = nodeArgs;
    } else {
        $$ = nullptr;
    }
}
| Exp {
    SyntaxTreeNode* nodeArgs = createNewNode("Args", NONEPSILON, @$.first_line);
    insertSyntaxTree((SyntaxTreeNode*)$1, nodeArgs);

    $$ = nodeArgs;
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

    if (errorCount == 0) {
        traverseSyntaxTree(root);
    }
    return 0;
}
