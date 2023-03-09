%locations
%{
#include "lex.yy.c"
#include "syntaxTreeNode.h"

struct Error {
    int lineno;
    char character;
};

struct Error errors[MAX_ERR_NUM];
int errorCount = 0;
int errorLineno = 0;
char errorChar = '\0';

void yyerror(char const * s);
int isNewError(int errorLineno, const char errorChar);

extern int yywrap();
extern int yylineno;

// extern struct SyntaxTreeNode *syntaxTreeRoot;
%}

%union {
    char    *string;
    int     number;
    float   floats;
    struct  SyntaxTreeNode *type_pnode;
}

%define parse.lac full
%define parse.error detailed

/* tokens */
%token              SEMI        "';'"
                    COMMA       "','"
                    ASSIGNOP    "'='"
                    RELOP       "RELOP"
                    PLUS        "'+'"
                    MINUS       "'-'"
                    STAR        "'*'"
                    DIV         "'/'"
                    AND         "'&&'"
                    OR          "'||'"
                    DOT         "'.'"
                    NOT         "'!'"
                    LP          "'('"
                    RP          "')'"
                    LB          "'['"
                    RB          "']'"
                    LC          "'{'"
                    RC          "'}'"
                    STRUCT      "struct"
                    RETURN      "return"
                    IF          "'if'"
                    ELSE        "'else'"
                    WHILE       "'while'"

/* numbers */
%token <number>     INT         "int value"
%token <floats>     FLOAT       "float value"
%token <string>     ID          "identifier"
%token <string>     TYPE        "type"

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

    syntaxTreeRoot = nodeProgram;

    $$ = nodeProgram;
} 
;

ExtDefList : ExtDef ExtDefList {
    struct SyntaxTreeNode* nodeExtDefList = createNewNode("ExtDefList", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExtDefList);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeExtDefList);
    $$ = nodeExtDefList;
} 
| {
    $$ = NULL;
}
;

ExtDef : Specifier ExtDecList SEMI {
    struct SyntaxTreeNode* nodeExtDef = createNewNode("ExtDef", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExtDef);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeExtDef);
    struct SyntaxTreeNode* nodeSemi = createNewNode("SEMI", NONEPSILON, @3.first_line);
    insertSyntaxTree(nodeSemi, nodeExtDef);

    $$ = nodeExtDef;
}
| Specifier SEMI {
    struct SyntaxTreeNode* nodeExtDef = createNewNode("ExtDef", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExtDef);
    struct SyntaxTreeNode* nodeSemi = createNewNode("SEMI", NONEPSILON, @2.first_line);
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
;

ExtDecList : VarDec {
    struct SyntaxTreeNode* nodeExtDecList = createNewNode("ExtDecList", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExtDecList);

    $$ = nodeExtDecList; 
}
| VarDec COMMA ExtDecList {
    struct SyntaxTreeNode* nodeExtDecList = createNewNode("ExtDecList", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExtDecList);
    struct SyntaxTreeNode* nodeComma = createNewNode("COMMA", NONVALUENODE, @2.first_line);
    insertSyntaxTree(nodeComma, nodeExtDecList);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExtDecList);

    $$ = nodeExtDecList;
}
;

// Specifiers
Specifier : TYPE {
    struct SyntaxTreeNode* nodeSpecifier = createNewNode("Specifier", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeType = createNewNode("TYPE", TYPENODE, @1.first_line);
    nodeType->stringVal = $1;
    insertSyntaxTree(nodeType, nodeSpecifier);

    $$ = nodeSpecifier;
}
| StructSpecifier {
    struct SyntaxTreeNode* nodeSpecifier = createNewNode("Specifier", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeSpecifier);

    $$ = nodeSpecifier;
}
;

StructSpecifier : STRUCT OptTag LC DefList RC {
    struct SyntaxTreeNode* nodeStructSpecifier = createNewNode("StructSpecifier", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeStruct = createNewNode("STRUCT", NONVALUENODE, @1.first_line);

    struct SyntaxTreeNode* nodeLC = createNewNode("LC", NONVALUENODE, @3.first_line);
    struct SyntaxTreeNode* nodeRC = createNewNode("RC", NONVALUENODE, @5.first_line);

    insertSyntaxTree(nodeStruct, nodeStructSpecifier);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeStructSpecifier);
    insertSyntaxTree(nodeLC, nodeStructSpecifier);
    insertSyntaxTree((struct SyntaxTreeNode*)$4, nodeStructSpecifier);
    insertSyntaxTree(nodeRC, nodeStructSpecifier);

    $$ = nodeStructSpecifier;
}
| STRUCT Tag {
    struct SyntaxTreeNode* nodeStructSpecifier = createNewNode("StructSpecifier", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeStruct = createNewNode("STRUCT", NONVALUENODE, @1.first_line);

    insertSyntaxTree(nodeStruct, nodeStructSpecifier);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeStructSpecifier);

    $$ = nodeStructSpecifier;
}
;

OptTag : ID {
    struct SyntaxTreeNode* nodeOptTag = createNewNode("OptTag", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeID = createNewNode("ID", IDNODE, @1.first_line);
    nodeID->stringVal = $1;

    insertSyntaxTree(nodeID, nodeOptTag);

    $$ = nodeOptTag;
}
| {
    // struct SyntaxTreeNode* nodeOptTag = createNewNode("OptTag", NONEPSILON, @$.first_line);

    // $$ = nodeOptTag;
    $$ = NULL;
}
;

Tag : ID {
    struct SyntaxTreeNode* nodeTag = createNewNode("Tag", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeID = createNewNode("ID", IDNODE, @1.first_line);
    nodeID->stringVal = $1;

    insertSyntaxTree(nodeID, nodeTag);

    $$ = nodeTag;
}
;

// Declarators
VarDec : ID {
    struct SyntaxTreeNode* nodeVarDec = createNewNode("VarDec", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeID = createNewNode("ID", IDNODE, @1.first_line);
    nodeID->stringVal = $1;

    insertSyntaxTree(nodeID, nodeVarDec);

    $$ = nodeVarDec;
}
| VarDec LB INT RB {
    struct SyntaxTreeNode* nodeVarDec = createNewNode("VarDec", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeLB = createNewNode("LB", NONVALUENODE, @2.first_line);
    struct SyntaxTreeNode* nodeINT = createNewNode("INT", INTNODE, @3.first_line);
    nodeINT->intVal = $3;
    struct SyntaxTreeNode* nodeRB = createNewNode("RB", NONVALUENODE, @4.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeVarDec);
    insertSyntaxTree(nodeLB, nodeVarDec);
    insertSyntaxTree(nodeINT, nodeVarDec);
    insertSyntaxTree(nodeRB, nodeVarDec);

    $$ = nodeVarDec;
}
;

FunDec : ID LP VarList RP {
    struct SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeID = createNewNode("ID", IDNODE, @1.first_line);
    nodeID->stringVal = $1;
    struct SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUENODE, @2.first_line);
    struct SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUENODE, @4.first_line);

    insertSyntaxTree(nodeID, nodeFunDec);
    insertSyntaxTree(nodeLP, nodeFunDec);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeFunDec);
    insertSyntaxTree(nodeRP, nodeFunDec);

    $$ = nodeFunDec;
}
| ID LP RP {
    // 参数为空
    struct SyntaxTreeNode* nodeFunDec = createNewNode("FunDec", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeID = createNewNode("ID", IDNODE, @1.first_line);
    nodeID->stringVal = $1;
    struct SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUENODE, @2.first_line);
    struct SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUENODE, @3.first_line);

    insertSyntaxTree(nodeID, nodeFunDec);
    insertSyntaxTree(nodeLP, nodeFunDec);
    insertSyntaxTree(nodeRP, nodeFunDec);

    $$ = nodeFunDec;
}
;


VarList : ParamDec COMMA VarList {
    struct SyntaxTreeNode* nodeVarList = createNewNode("VarList", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeCOMMA = createNewNode("COMMA", NONVALUENODE, @2.first_line);

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
;

ParamDec : Specifier VarDec {
    struct SyntaxTreeNode* nodeParamDec = createNewNode("ParamDec", NONEPSILON, @$.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeParamDec);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeParamDec);

    $$ = nodeParamDec;
}
;

// Statements
CompSt : LC DefList StmtList RC {
    struct SyntaxTreeNode* nodeCompSt = createNewNode("CompSt", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeLC = createNewNode("LC", NONVALUENODE, @1.first_line);
    struct SyntaxTreeNode* nodeRC = createNewNode("RC", NONVALUENODE, @4.first_line);

    insertSyntaxTree(nodeLC, nodeCompSt);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeCompSt);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeCompSt);
    insertSyntaxTree(nodeRC, nodeCompSt);

    $$ = nodeCompSt;
}
;

StmtList : Stmt StmtList {
    struct SyntaxTreeNode* nodeStmtList = createNewNode("StmtList", NONEPSILON, @$.first_line);
    // struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @1.first_line);

    // insertSyntaxTree(nodeStmt, nodeStmtList);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeStmtList);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeStmtList);

    $$ = nodeStmtList;
}
| {
    // struct SyntaxTreeNode* nodeStmtList = createNewNode("StmtList", NONEPSILON, @$.first_line);

    // $$ = nodeStmtList;
    $$ = NULL;
}
;

Stmt : Exp SEMI {
    struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeSEMI = createNewNode("SEMI", NONVALUENODE, @2.first_line);

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
    struct SyntaxTreeNode* nodeRETURN = createNewNode("RETURN", NONVALUENODE, @1.first_line);
    struct SyntaxTreeNode* nodeSEMI = createNewNode("SEMI", NONVALUENODE, @3.first_line);

    insertSyntaxTree(nodeRETURN, nodeStmt);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeStmt);
    insertSyntaxTree(nodeSEMI, nodeStmt);

    $$ = nodeStmt;
}
| IF LP Exp RP Stmt {
    struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeIF = createNewNode("IF", NONVALUENODE, @1.first_line);
    struct SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUENODE, @2.first_line);
    struct SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUENODE, @4.first_line);

    insertSyntaxTree(nodeIF, nodeStmt);
    insertSyntaxTree(nodeLP, nodeStmt);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeStmt);
    insertSyntaxTree(nodeRP, nodeStmt);
    insertSyntaxTree((struct SyntaxTreeNode*)$5, nodeStmt);

    $$ = nodeStmt;
}
| IF LP Exp RP Stmt ELSE Stmt {
    struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeIF = createNewNode("IF", NONVALUENODE, @1.first_line);
    struct SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUENODE, @2.first_line);
    struct SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUENODE, @4.first_line);
    struct SyntaxTreeNode* nodeELSE = createNewNode("ELSE", NONVALUENODE, @6.first_line);

    insertSyntaxTree(nodeIF, nodeStmt);
    insertSyntaxTree(nodeLP, nodeStmt);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeStmt);
    insertSyntaxTree(nodeRP, nodeStmt);
    insertSyntaxTree((struct SyntaxTreeNode*)$5, nodeStmt);
    insertSyntaxTree(nodeELSE, nodeStmt);
    insertSyntaxTree((struct SyntaxTreeNode*)$7, nodeStmt);

    $$ = nodeStmt;
}
| WHILE LP Exp RP Stmt {
    struct SyntaxTreeNode* nodeStmt = createNewNode("Stmt", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeWHILE = createNewNode("WHILE", NONVALUENODE, @1.first_line);
    struct SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUENODE, @2.first_line);
    struct SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUENODE, @4.first_line);

    insertSyntaxTree(nodeWHILE, nodeStmt);
    insertSyntaxTree(nodeLP, nodeStmt);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeStmt);
    insertSyntaxTree(nodeRP, nodeStmt);
    insertSyntaxTree((struct SyntaxTreeNode*)$5, nodeStmt);

    $$ = nodeStmt;
}
;

// Local Definitions
DefList : Def DefList {
    struct SyntaxTreeNode* nodeDefList = createNewNode("DefList", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeDefList);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeDefList);

    $$ = nodeDefList;
}
| {
    // struct SyntaxTreeNode* nodeDefList = createNewNode("DefList", NONEPSILON, @$.first_line);
    
    // $$ = nodeDefList;
    $$ = NULL;
}
;

Def : Specifier DecList SEMI {
    struct SyntaxTreeNode* nodeDef = createNewNode("Def", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeSEMI = createNewNode("SEMI", NONVALUENODE, @3.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeDef);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeDef);
    insertSyntaxTree(nodeSEMI, nodeDef);

    $$ = nodeDef;
}
;

DecList : Dec {
    struct SyntaxTreeNode* nodeDecList = createNewNode("DecList", NONEPSILON, @$.first_line);
    // FIXME: $1 insert?
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeDecList);
    // nodeDecList->child = (struct SyntaxTreeNode*)$1;

    $$ = nodeDecList;
}
| Dec COMMA DecList {
    struct SyntaxTreeNode* nodeDecList = createNewNode("DecList", NONEPSILON, @$.first_line);
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeDecList);
    struct SyntaxTreeNode* nodeCOMMA = createNewNode("COMMA", NONVALUENODE, @2.first_line);
    insertSyntaxTree(nodeCOMMA, nodeDecList);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeDecList);

    $$ = nodeDecList;
}
;

Dec : VarDec {
    struct SyntaxTreeNode* nodeDec = createNewNode("Dec", NONEPSILON, @$.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeDec);

    $$ = nodeDec;
}
| VarDec ASSIGNOP Exp {
    struct SyntaxTreeNode* nodeDec = createNewNode("Dec", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeASSIGNOP = createNewNode("ASSIGNOP", NONVALUENODE, @2.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeDec);
    insertSyntaxTree(nodeASSIGNOP, nodeDec);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeDec);

    $$ = nodeDec;
}
;

// Expressions
Exp : Exp ASSIGNOP Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeASSIGNOP = createNewNode("ASSIGNOP", NONVALUENODE, @2.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    insertSyntaxTree(nodeASSIGNOP, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp AND Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeAND = createNewNode("AND", NONVALUENODE, @2.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    insertSyntaxTree(nodeAND, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp OR Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeOR = createNewNode("OR", NONVALUENODE, @2.first_line);
    
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    insertSyntaxTree(nodeOR, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp RELOP Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    
    struct SyntaxTreeNode* nodeRELOP = createNewNode("RELOP", NONVALUENODE, @2.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    insertSyntaxTree(nodeRELOP, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp PLUS Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodePLUS = createNewNode("PLUS", NONVALUENODE, @2.first_line);
    
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    insertSyntaxTree(nodePLUS, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp PLUS error {
    if(isNewError(@3.first_line, 'B')){
        errors[errorCount].lineno = yylineno;
        errors[errorCount].character = 'B';
        errorCount++;

        printf("Error type B at Line %d: Syntax error after \"+\". \n", @3.first_line);

        struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);

        struct SyntaxTreeNode* nodePLUS = createNewNode("PLUS", NONVALUENODE, @2.first_line);
        struct SyntaxTreeNode* nodeErr = createNewNode("error", NONEPSILON, @3.first_line);

        insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeErr);
        insertSyntaxTree(nodePLUS, nodeExp);
        insertSyntaxTree(nodeErr, nodeExp);

        $$ = nodeExp;
    } else {
        $$ = NULL;
    }
}
| Exp MINUS Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    
    struct SyntaxTreeNode* nodeMINUS = createNewNode("MINUS", NONVALUENODE, @2.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    insertSyntaxTree(nodeMINUS, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp STAR Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeSTAR = createNewNode("STAR", NONVALUENODE, @2.first_line);
    
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    insertSyntaxTree(nodeSTAR, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| Exp DIV Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeDIV = createNewNode("DIV", NONVALUENODE, @2.first_line);
    
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    insertSyntaxTree(nodeDIV, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);

    $$ = nodeExp;
}
| LP Exp RP {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUENODE, @1.first_line);
    struct SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUENODE, @3.first_line);
    
    insertSyntaxTree(nodeLP, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeExp);
    insertSyntaxTree(nodeRP, nodeExp);

    $$ = nodeExp;
}
| MINUS Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeMINUS = createNewNode("MINUS", NONVALUENODE, @1.first_line);
    
    insertSyntaxTree(nodeMINUS, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeExp);

    $$ = nodeExp;
}
| NOT Exp {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeNOT = createNewNode("NOT", NONVALUENODE, @1.first_line);
    
    insertSyntaxTree(nodeNOT, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$2, nodeExp);

    $$ = nodeExp;
}
| ID LP Args RP {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeID = createNewNode("ID", IDNODE, @1.first_line);
    nodeID->stringVal = $1;
    struct SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUENODE, @2.first_line);
    struct SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUENODE, @4.first_line);
    
    insertSyntaxTree(nodeID, nodeExp);
    insertSyntaxTree(nodeLP, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);
    insertSyntaxTree(nodeRP, nodeExp);

    $$ = nodeExp;
}
| ID LP RP {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeID = createNewNode("ID", IDNODE, @1.first_line);
    nodeID->stringVal = $1;
    struct SyntaxTreeNode* nodeLP = createNewNode("LP", NONVALUENODE, @2.first_line);
    struct SyntaxTreeNode* nodeRP = createNewNode("RP", NONVALUENODE, @3.first_line);
    
    insertSyntaxTree(nodeID, nodeExp);
    insertSyntaxTree(nodeLP, nodeExp);
    insertSyntaxTree(nodeRP, nodeExp);

    $$ = nodeExp;
}
| Exp LB Exp RB {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeLB = createNewNode("LB", NONVALUENODE, @2.first_line);
    struct SyntaxTreeNode* nodeRB = createNewNode("RB", NONVALUENODE, @4.first_line);
    
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    insertSyntaxTree(nodeLB, nodeExp);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeExp);
    insertSyntaxTree(nodeRB, nodeExp);

    $$ = nodeExp;
}
| Exp DOT ID {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeDOT = createNewNode("DOT", NONVALUENODE, @2.first_line);
    struct SyntaxTreeNode* nodeID = createNewNode("ID", IDNODE, @3.first_line);
    nodeID->stringVal = $3;
    
    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeExp);
    insertSyntaxTree(nodeDOT, nodeExp);
    insertSyntaxTree(nodeID, nodeExp);

    $$ = nodeExp;
}
| ID {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);
    struct SyntaxTreeNode* nodeID = createNewNode("ID", IDNODE, @1.first_line);
    nodeID->stringVal = $1;

    insertSyntaxTree(nodeID, nodeExp);

    $$ = nodeExp;
}
| INT {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeINT = createNewNode("INT", INTNODE, @1.first_line);
    // nodeINT->intVal = (int)strtol($1, NULL, 10);
    nodeINT->intVal = (int)$1;

    insertSyntaxTree(nodeINT, nodeExp);

    $$ = nodeExp;
}
| FLOAT {
    struct SyntaxTreeNode* nodeExp = createNewNode("Exp", NONEPSILON, @$.first_line);

    struct SyntaxTreeNode* nodeFLOAT = createNewNode("FLOAT", FLOATNODE, @1.first_line);
    // nodeFLOAT->floatVal = (float)strtod($1, NULL);
    nodeFLOAT->floatVal = (float)$1;
    
    insertSyntaxTree(nodeFLOAT, nodeExp);

    $$ = nodeExp;
}
;

Args : Exp COMMA Args {
    struct SyntaxTreeNode* nodeArgs = createNewNode("Args", NONEPSILON, @$.first_line);
    
    struct SyntaxTreeNode* nodeCOMMA = createNewNode("COMMA", NONVALUENODE, @2.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeArgs);
    insertSyntaxTree(nodeCOMMA, nodeArgs);
    insertSyntaxTree((struct SyntaxTreeNode*)$3, nodeArgs);

    $$ = nodeArgs;
}
| Exp {
    struct SyntaxTreeNode* nodeArgs = createNewNode("Args", NONEPSILON, @$.first_line);

    insertSyntaxTree((struct SyntaxTreeNode*)$1, nodeArgs);

    $$ = nodeArgs;
}
;

%%

void yyerror(char const *s) {
    if(isNewError(yylineno, 'B')) {
        printf("Error type B at Line %d: %s \n", yylineno, s);
    }
}

int isNewError(int errorLineno, const char errorChar) {
    for (int i = 0; i < errorCount; i++) {
        if (errors[i].lineno == errorLineno && errors[i].character == errorChar) {
            return 0;
        }
    }
    errors[errorCount].lineno = errorLineno;
    errors[errorCount].character = errorChar;
    errorCount++;
    return 1;
}

int yywrap() {
    return 1;
}