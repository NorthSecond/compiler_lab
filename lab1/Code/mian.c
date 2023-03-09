#include "includes.h"

#include "syntaxTreeNode.h"
#include "syntax.tab.h"
// #include "lex.yy.c"

extern int yyparse();
extern int errorCount;

// extern struct SyntaxTreeNode *syntaxTreeRoot;

extern FILE *yyin;
extern char *yytext;
extern int yyrestart(FILE *input_file);

int main(int argc, char *argv[])
{
    syntaxTreeRoot = NULL;
    if (argc != 2)
    {
        printf("Usage: %s filename, please try again with a filename as the argument to the program (e.g. test.cmm) \n", argv[0]);
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if (!yyin)
    {
        printf("Error: Could not open file %s \n", argv[1]);
        return 1;
    }
    yyrestart(yyin);
    yyparse();
    fclose(yyin);

#ifdef LAB1
    if (errorCount == 0)
    {
        traverseSyntaxTree(syntaxTreeRoot, 0);
    }
#endif

    destroySyntaxTree(syntaxTreeRoot);
    return 0;
}
