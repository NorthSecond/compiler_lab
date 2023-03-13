# GNU make手册：http://www.gnu.org/software/make/manual/make.html
# ************ 遇到不明白的地方请google以及阅读手册 *************

# 编译器设定和编译选项
CC = gcc
# Update: 添加C++编译器
# CPP = g++
FLEX = flex
BISON = bison

# CFLAGS = -std=c99
# Update: 添加C++编译选项 C 带上 -Wall -Wextra -fno-asm -MMD
# 23-03-02 更新：既然可以C++编写了 那就直接C++吧
CFLAGS = -std=c99 -Wall -Wextra -fno-asm -MMD
# CPPFLAGS = -std=c++17 -Wall -Wextra -fno-asm 

# 编译目标：src目录下的所有.c文件
CFILES = $(shell find ./ -name "*.c")
OBJS = $(CFILES:.c=.o)
LFILE = $(shell find ./ -name "*.l")
YFILE = $(shell find ./ -name "*.y")
LFC = $(shell find ./ -name "*.l" | sed s/[^/]*\\.l/lex.yy.c/)
YFC = $(shell find ./ -name "*.y" | sed s/[^/]*\\.y/syntax.tab.c/)
LFO = $(LFC:.c=.o)
YFO = $(YFC:.c=.o)

# Update：编译目标中加入src目录下的所有.cpp文件
# CPPFILES = $(shell find ./ -name "*.cpp")
# OBJS += $(CPPFILES:.cpp=.o)

parser: syntax $(filter-out $(LFO),$(OBJS))
	$(CC) -o parser $(filter-out $(LFO),$(OBJS)) -lfl -ly

syntax: lexical syntax-c
	$(CC) -c $(YFC) -o $(YFO)
# $(CPP) $(CPPFLAGS) -c $(YFC) -o $(YFO)


lexical: $(LFILE)
	$(FLEX) -o $(LFC) $(LFILE)

syntax-c: $(YFILE)
	$(BISON) -o $(YFC) -d -v $(YFILE)

-include $(patsubst %.o, %.d, $(OBJS))

# 定义的一些伪目标
.PHONY: clean test
test:
	./parser ../Test/test1.cmm
clean:
	rm -f parser lex.yy.c syntax.tab.c syntax.tab.h syntax.output
	rm -f $(OBJS) $(OBJS:.o=.d)
	rm -f $(LFC) $(YFC) $(YFC:.c=.h)
	rm -f *~
