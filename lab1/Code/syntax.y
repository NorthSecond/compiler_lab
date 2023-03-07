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
