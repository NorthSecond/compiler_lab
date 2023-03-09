#include "syntaxTreeNode.h"

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
void printNodeInfo(struct SyntaxTreeNode *node, int indent)
{
    if (node == NULL)
    {
        return;
    }
    if (node->type != EPSILON)
    {
        for (int i = 0; i < indent; i++)
        {
            printf("  ");
        }
    }
    switch (node->type)
    {
    case NONEPSILON:
        // 打印语法单元的名称和对应在输入文件中的行号
        printf("%s (%d) \n", node->name, node->lineno);
        break;
    case EPSILON:
        // 无需打印语法单元对应的信息
#if YYDEBUG > 0
        printf("%s (%d) \n", node->name, node->lineno);
#endif // YYDEBUG
        break;

    // 如果当前节点是词法单元 无需打印行号
    case IDNODE:
        // 额外打印对应的词素
        printf("%s: %s \n", node->name, node->stringVal);
        break;
    case TYPENODE:
        // 额外打印对应的类型
        printf("%s: %s \n", node->name, node->stringVal);
        break;
    case INTNODE:
        // 额外打印对应的整数值
        printf("%s: %d \n", node->name, node->intVal);
        break;
    case FLOATNODE:
        // 额外打印对应的浮点数值
        printf("%s: %f \n", node->name, node->floatVal);
        break;
    case NONVALUENODE:
        printf("%s \n", node->name);
        break;
    default:
        break;
    }
}
#endif

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

    for (struct SyntaxTreeNode *p = root->child; p != NULL; p = p->sibling)
    {
        traverseSyntaxTree(p, indent + 1);
    }
}

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

void insertSyntaxTree(struct SyntaxTreeNode *node, struct SyntaxTreeNode *root)
{
    if (root == NULL || node == NULL)
    {
#if YYDEBUG > 0
        printf("insert error: root or node is NULL \n");
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

// 全局变量 树的根节点
struct SyntaxTreeNode *syntaxTreeRoot = NULL;
