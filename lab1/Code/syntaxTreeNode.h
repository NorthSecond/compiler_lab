#ifndef SYNTAXTREENODE_H
#define SYNTAXTREENODE_H

#include "includes.h"

/**
 * 词法单元的类型
 * NONEPSILON: 没有产生 \epsilon 的语法单元
 * EPSILON: 产生 \eplison 的语法单元
 * IDNODE: 词法单元ID
 * TYPENODE: 词法单元TYPE
 * INTNODE: 词法单元INT
 * FLOATNODE: 词法单元FLOAT
 * NONVALUENODE: 不产生语法单元的词法单元
 */
enum SyntaxTreeNodeType
{
    NONEPSILON,
    EPSILON,
    IDNODE,
    TYPENODE,
    INTNODE,
    FLOATNODE,
    NONVALUENODE
};

// 语法树的定义
// 语法树是多叉树
// 对应行号 子节点数量 子节点指针
struct SyntaxTreeNode
{
    char *name;
    enum SyntaxTreeNodeType type;
    int lineno;
    union
    {
        int intVal;
        float floatVal;
        char *stringVal;
    };
    int childCount;
    struct SyntaxTreeNode *child;
    struct SyntaxTreeNode *sibling;
};

// 语法树节点的创建
struct SyntaxTreeNode *createSyntaxTree(char *name, enum SyntaxTreeNodeType type, int lineno);

// 打印节点信息
// 考虑一下要不要放这里 还是换个位置提出来到别的文件里面
#ifdef LAB1
void printNodeInfo(struct SyntaxTreeNode *node, int indent);
#endif

// 语法树的遍历
// 这里使用先序遍历
void traverseSyntaxTree(struct SyntaxTreeNode *root, int indent);

// 语法树的销毁
void destroySyntaxTree(struct SyntaxTreeNode *root);

// 语法树的插入
// 对应多叉树的插入
void insertSyntaxTree(struct SyntaxTreeNode *node, struct SyntaxTreeNode *root);

// create new node
// 创建新的语法树节点
struct SyntaxTreeNode *createNewNode(char *name, enum SyntaxTreeNodeType type, int lineno);

extern struct SyntaxTreeNode *syntaxTreeRoot;

#endif // !SYNTAX