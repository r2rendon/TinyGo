#include <string>
#include <list>
#include <map>

using namespace std;

class Expr;
class Init; // InitDeclarator
class Declaration;
class Parameter;
class Statement;
class SingleExpr;
typedef list<Expr *> InitializerElementList;
typedef list<Init *> InitDeclaratorList;
typedef list<Declaration *> DeclarationList;
typedef list<Parameter *> ParameterList;
typedef list<Statement *> StatementList;
typedef list<Expr *> ArgumentList;
typedef list<SingleExpr *> SingleExprList;

enum StatementKind{
    FOR_STATEMENT,
    IF_STATEMENT,
    EXPRESSION_STATEMENT,
    RETURN_STATEMENT,
    CONTINUE_STATEMENT,
    BREAK_STATEMENT,
    PRINT_STATEMENT,
    FUNCTION_DEFINITION_STATEMENT,
    GLOBAL_DECLARATION_STATEMENT,
    ELSE_STATEMENT,
    BLOCK_STATEMENT,
};

enum Type{
    INVALID,
    STRING,
    INT,
    FLOAT,
    INT_ARRAY,
    FLOAT_ARRAY,
    BOOL_ARRAY,
    STRING_ARRAY,
    BOOL,
    INFERED
};

enum SingleType{
    NOT
};

class Statement{
    public:
        int line;
        virtual int evaluateSemantic() = 0;
        virtual StatementKind getKind() = 0;
};

class Expr{
    public:
        int line;
        virtual Type getType() = 0;
};

class Initializer{
    public:
        Initializer(){}
        Initializer(InitializerElementList expressions, int line){
            this->expressions = expressions;
            this->line = line;
        }
        InitializerElementList expressions;
        int line;
};

class Declarator{
    public:
        Declarator(string id, Expr* arrayDeclaration, bool isArray, int line){
            this->id = id;
            this->isArray = isArray;
            this->line = line;
            this->arrayDeclaration = arrayDeclaration;
        }
        string id;
        bool isArray;
        int line;
        Expr * arrayDeclaration;
};

class Init{
    public:
        Init(Declarator * declarator, Initializer * initializer, int line){
            this->declarator = declarator;
            this->initializer = initializer;
            this->line = line;
        }
        Declarator * declarator;
        Initializer * initializer;
        int line;
};

class Declaration{
    public:
        Declaration(Type type, InitDeclaratorList declarations, int line){
            this->type = type;
            this->declarations = declarations;
            this->line = line;
        }
        
        Type type;
        InitDeclaratorList declarations;
        int line;
        int evaluateSemantic();
};


class Parameter{
    public:
        Parameter(Type type, Declarator * declarator, bool isArray, int line){
            this->type = type;
            this->declarator = declarator;
            this->line = line;
        }
        Type type;
        Declarator* declarator;
        bool isArray;
        int line;
        int evaluateSemantic();
};

class BlockStatement : public Statement{
    public:
        BlockStatement(StatementList statements, DeclarationList declarations, int line){
            this->statements = statements;
            this->declarations = declarations;
            this->line = line;
        }
        StatementList statements;
        DeclarationList declarations;
        int line;
        int evaluateSemantic();
        StatementKind getKind(){
            return BLOCK_STATEMENT;
        }
};

class GlobalDeclaration : public Statement {
    public:
        GlobalDeclaration(Declaration * declaration){
            this->declaration = declaration;
        }
        Declaration * declaration;
        int evaluateSemantic();
        StatementKind getKind(){
            return GLOBAL_DECLARATION_STATEMENT;
        }
};

class MethodDefinition : public Statement{
    public:
        MethodDefinition(string id, ParameterList params, Statement * statement, int line){
            this->id = id;
            this->params = params;
            this->statement = statement;
            this->line = line;
        }

        string id;
        ParameterList params;
        Statement * statement;
        int line;
        int evaluateSemantic();
        StatementKind getKind(){
            return FUNCTION_DEFINITION_STATEMENT;
        }
};

class IntExpr : public Expr{
    public:
        IntExpr(int value, int line){
            this->value = value;
            this->line = line;
        }
        int value;
        Type getType();
};

class FloatExpr : public Expr{
    public:
        FloatExpr(float value, int line){
            this->value = value;
            this->line = line;
        }
        float value;
        Type getType();
};

class BoolExpr : public Expr{
    public:
        BoolExpr(bool value, int line){
            this->value = value;
            this->line = line;
        }
        bool value;
        Type getType();
};

class StringExpr : public Expr{
    public:
        StringExpr(string value, int line){
            this->value = value;
            this->line = line;
        }
        string value;
        Type getType();
};

class BinaryExpr : public Expr{
    public:
        BinaryExpr(Expr * expr1, Expr *expr2, int line){
            this->expr1 = expr1;
            this->expr2 = expr2;
            this->line = line;
        }
        Expr * expr1;
        Expr *expr2;
        int line;
};

#define IMPLEMENT_BINARY_EXPR(name) \
class name##Expr : public BinaryExpr{\
    public: \
        name##Expr(Expr * expr1, Expr *expr2, int line) : BinaryExpr(expr1, expr2, line){}\
        Type getType(); \
};

class SingleExpr : public Expr{
    public:
        SingleExpr(int type, Expr* expr, int line){
            this->type = type;
            this->expr = expr;
            this->line = line;
        }
        int type;
        Expr* expr;
        int line;
        Type getType();
};

class PostIncrementExpr: public Expr{
    public:
        PostIncrementExpr(Expr * expr, int line){
            this->expr = expr;
            this->line = line;
        }
        Expr * expr;
        int line;
        Type getType();
};

class PostDecrementExpr: public Expr{
    public:
        PostDecrementExpr(Expr * expr, int line){
            this->expr = expr;
            this->line = line;
        }
        Expr * expr;
        int line;
        Type getType();
};

class IdExpr : public Expr{
    public:
        IdExpr(string id, int line){
            this->id = id;
            this->line = line;
        }
        string id;
        int line;
        Type getType();
};

class ArrayExpr : public Expr{
    public:
        ArrayExpr(IdExpr * id, Expr * expr, int line){
            this->id = id;
            this->expr = expr;
            this->line = line;
        }
        IdExpr * id;
        Expr * expr;
        int line;
        Type getType();
};

class MethodInvocationExpr : public Expr{
    public:
        MethodInvocationExpr(IdExpr * id, ArgumentList args, int line){
            this->id = id;
            this->args = args;
            this->line = line;
        }
        IdExpr * id;
        ArgumentList args;
        int line;
        Type getType();

};

class IfStatement : public Statement{
    public:
        IfStatement(Expr * conditionalExpr, Statement * trueStatement, int line){
            this->conditionalExpr = conditionalExpr;
            this->trueStatement = trueStatement;
            this->line = line;
        }
        Expr * conditionalExpr;
        Statement * trueStatement;
        int evaluateSemantic();
        StatementKind getKind(){return IF_STATEMENT;}
};

class ForStatement : public Statement{
    public:
        ForStatement(Expr * conditionalExpr, Statement * loopStatement, int line){
            this->conditionalExpr = conditionalExpr;
            this->loopStatement = loopStatement;
            this->line = line;
        }
        Expr* conditionalExpr;
        Statement * loopStatement;
        int line;
        int evaluateSemantic();
        StatementKind getKind(){
            return FOR_STATEMENT;
        }
};
       
class ForStatementExtended: public Statement{
    public:
        ForStatementExtended(Expr * assignmentExpression, Expr * conditionalExpr, Expr * additiveExpression, Statement * loopStatement, int line){
            this->conditionalExpr = conditionalExpr;
            this->assignmentExpression = assignmentExpression;
            this->additiveExpression = additiveExpression;
            this->loopStatement = loopStatement;
            this->line = line;
        }

        Expr * conditionalExpr;
        Expr * assignmentExpression;
        Expr * additiveExpression;
        Statement * loopStatement;
        int evaluateSemantic();
        StatementKind getKind(){return FOR_STATEMENT;}
};

class ElseStatement : public Statement{
    public:
        ElseStatement(Expr * conditionalExpr, Statement * trueStatement, Statement * falseStatement, int line){
            this->conditionalExpr = conditionalExpr;
            this->trueStatement = trueStatement;
            this->line = line;
            this->falseStatement = falseStatement;
        }
        Expr * conditionalExpr;
        Statement * trueStatement;
        Statement * falseStatement;
        int evaluateSemantic();
        StatementKind getKind(){return ELSE_STATEMENT;}
};

class ExprStatement : public Statement{
    public:
        ExprStatement(Expr * expr, int line){
            this->expr = expr;
            this->line = line;
        }
        Expr * expr;
        int evaluateSemantic();
        StatementKind getKind(){return EXPRESSION_STATEMENT;}
};

class ReturnStatement : public Statement{
    public:
        ReturnStatement(Expr * expr, int line){
            this->expr = expr;
            this->line = line;
        }
        Expr * expr;
        int evaluateSemantic();
        StatementKind getKind(){return RETURN_STATEMENT;}
};

class PrintStatement : public Statement{
    public:
        PrintStatement(string string,Expr * expr, int line){
            localString = string;
            this->expr = expr;
            this->line = line;
        }
        
        string localString;
        Expr * expr;
        int evaluateSemantic();
        StatementKind getKind(){return PRINT_STATEMENT;}
};

class ContinueStatement : public Statement{
    public:
        ContinueStatement(int line){
            this->line = line;
        }
        int evaluateSemantic();
        StatementKind getKind(){return CONTINUE_STATEMENT;}
};

class BreakStatement : public Statement{
    public:
        BreakStatement(int line){
            this->line = line;
        }
        int evaluateSemantic();
        StatementKind getKind(){return BREAK_STATEMENT;}
};

class ArrayInitializerExpression : public Expr {
    public:
        ArrayInitializerExpression(Type type, Expr * expr, int line){
            this->type = type;
            this->expr = expr;
            this->line = line;
        }
        Type type;
        Expr * expr;
        int line;
        Type getType();
};

IMPLEMENT_BINARY_EXPR(Add);
IMPLEMENT_BINARY_EXPR(Sub);
IMPLEMENT_BINARY_EXPR(Mul);
IMPLEMENT_BINARY_EXPR(Div);
IMPLEMENT_BINARY_EXPR(Mod);
IMPLEMENT_BINARY_EXPR(Exp);
IMPLEMENT_BINARY_EXPR(Eq);
IMPLEMENT_BINARY_EXPR(Neq);
IMPLEMENT_BINARY_EXPR(Gte);
IMPLEMENT_BINARY_EXPR(Lte);
IMPLEMENT_BINARY_EXPR(Gt);
IMPLEMENT_BINARY_EXPR(Lt);
IMPLEMENT_BINARY_EXPR(LogicalAnd);
IMPLEMENT_BINARY_EXPR(LogicalOr);
IMPLEMENT_BINARY_EXPR(Assign);
IMPLEMENT_BINARY_EXPR(PlusEqual);
IMPLEMENT_BINARY_EXPR(MinusEqual);
IMPLEMENT_BINARY_EXPR(TimesEqual);
IMPLEMENT_BINARY_EXPR(ExponentEqual);
IMPLEMENT_BINARY_EXPR(DivideEqual);
IMPLEMENT_BINARY_EXPR(ModEqual);