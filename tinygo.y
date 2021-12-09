%code requires{
    #include "ast.h"
}

%{
    #include <cstdio>
    using namespace std;
    int yylex();
    extern int yylineno;
    void yyerror(const char * s){
        fprintf(stderr, "Line: %d, error: %s\n", yylineno, s);
    }

    #define YYERROR_VERBOSE 1
    #define YYDEBUG 1
    #define EQUAL 1
    #define PLUSEQUAL 2
    #define MINUSEQUAL 3
    #define ANDEQUAL 4
    #define OREQUAL 5
    #define TIMESEQUAL 6
    #define EXPONENTEQUAL 7
    #define DIVIDEEQUAL 8
    #define MODEQUAL 9
    #define ASSIGEQUAL 10
%}

%union{
    const char * string_t;
    int int_t;
    float float_t;
    bool bool_t;
    Expr * expr_t;
    ArgumentList * argument_list_t;
    Statement * statement_t;
    StatementList * statement_list_t;
    InitDeclaratorList * init_declarator_list_t;
    Init * init_t;
    Declarator * declarator_t;
    Initializer * initializer_t;
    InitializerElementList * initializer_list_t;
    Declaration * declaration_t;
    DeclarationList * declaration_list_t;
    Parameter * parameter_t;
    ParameterList * parameter_list_t;
    ArrayInitializerExpression * array_initializer_expression_t;
    SingleExprList * single_expr_list_t;
}

%token TK_MAIN
%token<string_t> TK_LIT_STRING TK_ID
%token<int_t> TK_LIT_INT
%token<float_t> TK_LIT_FLOAT
%token<bool_t> TK_TRUE TK_FALSE
%token TK_IF TK_ELSE
%token TK_FOR TK_RETURN
%token TK_INT_TYPE TK_FLOAT_TYPE TK_BOOL_TYPE TK_STRING_TYPE TK_VAR
%token TK_ASIG
%token TK_PRINT TK_BREAK TK_FUNC TK_PACKAGE TK_CONTINUE
%token TK_IMPORT
%token TK_PLUS_EQUAL TK_MINUS_EQUAL TK_PLUS_PLUS TK_MINUS_MINUS TK_NOT
%token TK_AND_EQUAL TK_EQUAL_EQUAL TK_OR_EQUAL
%token TK_OR TK_AND
%token TK_NOT_EQUAL TK_GREATER_OR_EQUAL TK_LESS_OR_EQUAL TK_TIMES_EQUAL TK_EXPONENT_EQUAL TK_DIVIDE_EQUAL TK_MOD_EQUAL

%type<expr_t> assignment_expression logical_or_expression
%type<statement_list_t> statements input
%type<statement_t> external_declaration func_definition block_statement return_statement statement
%type<declaration_t> declaration
%type<declaration_list_t> declarations
%type<initializer_t> initializer
%type<initializer_list_t> init_list
%type<declarator_t> declarator
// %type<init_t> init
%type<init_declarator_list_t> declarator_list
%type<parameter_t> parameter_declaration
%type<parameter_list_t> parameters_type_list
%type<int_t> type assignment_operator
%type<expr_t> constant expression logical_and_expression additive_expression multiplicative_expression equality_expression relational_expression
%type<expr_t> single_expression postfix_expression primary_expression
// %type<argument_list_t> argument_expression_list
%type <statement_t> if_statement for_statement expression_statement
%type <array_initializer_expression_t> array_initializer_expression
%type <single_expr_list_t> single_expression_list
// TO-DO que sea $1 por packages
%%

start: package_list input {
    list<Statement *>::iterator it = $2->begin();
    while(it != $2->end()){
        printf("semantic result: %d \n",(*it)->evaluateSemantic());
        it++;
    }
}
    ;

package_list: /* vacio */
    | package_list package
    | package
    ;

package: TK_PACKAGE TK_ID
    | TK_IMPORT TK_LIT_STRING
    ;

input: external_declaration TK_MAIN block_statement {$$->push_back($1); $$ = $3;}
    | TK_MAIN block_statement {$$ = $2;}
    ;

external_declaration: func_definition {$$ = $1;}
    | declarations {$$ = new GlobalDeclaration($1);}
    ;

func_definition: TK_FUNC TK_ID '(' ')' block_statement {
        ParameterList * pm = new ParameterList;
        $$ = new MethodDefinition($2, *pm, , $5, yylineno);
        delete pm;
    }
    | TK_FUNC TK_ID '(' ')' '{' '}' {
        ParameterList * pm = new ParameterList;
        Statement * s = new Statement;
        $$ = new MethodDefinition($2, *pm, *s, yylineno);
        delete pm;
        delete s;
    }
    | TK_FUNC TK_ID '(' parameters_type_list ')' block_statement {
        $$ = new MethodDefinition($2, $4, $6, yylineno);
        delete $4;
    }
    ;

declarations: declarations declaration { $$ = $1; $$->push_back($2); }
    | declaration {$$ = new DeclarationList; $$->push_back($1);}
    ;

parameters_type_list: parameters_type_list ',' parameter_declaration {$$ = $1; $$->push_back($3);}
    | parameter_declaration { $$ = new ParameterList; $$->push_back($1); }
    | declarator { $$ = new Declarator; $$ = $1;}
    ;

parameter_declaration: type declarator { $$ = new Parameter((Type)$1, $2, false, yylineno); }
    | type { $$ = new Parameter((Type)$1, NULL, false, yylineno); }
    | type '[' ']' { $$ = new Parameter((Type)$1, NULL, true, yylineno); }
    ;

declaration: TK_VAR declarator_list type { $$ = new Declaration((Type)$3, *$2, yylineno); delete $2;  }
    | TK_VAR declarator_list type initializer { $$ = new Declaration((Type)$3, *$2, *$4, yylineno); delete $2;  }
    | TK_VAR declarator_list initializer { 
        $$ = new Declaration(Type::infered, *$2, *$3, yylineno); 
        delete $2;
    }
    ;

declarator_list: declarator_list ',' declarator { $$ = $1; $$->push_back($3); }
    | declarator { $$ = new InitDeclaratorList; $$->push_back($1); }
    ;

declarator: TK_ID {$$ = new Declarator($1, NULL, false, yylineno);}
    | TK_ID '[' expression ']' { $$ = new Declarator($1, $3, true, yylineno);}
    ;

initializer: '='assignment_expression {
        InitializerElementList * list = new InitializerElementList;
        list->push_back($2);
        $$ = new Initializer(*list, yylineno);
    }
    | init_list { $$ = new Initializer(*$1, yylineno); delete $1;}
    ;

init_list: init_list ',' logical_or_expression { $$ = $1; $$->push_back($3); }
    | logical_or_expression {$$ = new InitializerElementList; $$->push_back($1);}
    ;

logical_or_expression: logical_or_expression TK_OR logical_and_expression { $$ = new LogicalOrExpr($1, $3, yylineno); }
    | logical_and_expression {$$ = $1;}
    ;

logical_and_expression: logical_and_expression TK_AND equality_expression { $$ = new LogicalAndExpr($1, $3, yylineno); }
    | equality_expression {$$ = $1;}
    ;

equality_expression:  equality_expression TK_EQUAL_EQUAL relational_expression { $$ = new EqExpr($1, $3, yylineno); }
    | equality_expression TK_NOT_EQUAL relational_expression { $$ = new NeqExpr($1, $3, yylineno); }
    | relational_expression {$$ = $1;}
    ;

relational_expression: relational_expression '>' additive_expression { $$ = new GtExpr($1, $3, yylineno); }
    | relational_expression '<' additive_expression { $$ = new LtExpr($1, $3, yylineno); }
    | relational_expression TK_GREATER_OR_EQUAL additive_expression { $$ = new GteExpr($1, $3, yylineno); }
    | relational_expression TK_LESS_OR_EQUAL additive_expression { $$ = new LteExpr($1, $3, yylineno); }
    | additive_expression {$$ = $1;}
    ;

additive_expression:  additive_expression '+' multiplicative_expression { $$ = new AddExpr($1, $3, yylineno); }
    | additive_expression '-' multiplicative_expression { $$ = new SubExpr($1, $3, yylineno); }
    | multiplicative_expression {$$ = $1;}
    ;

multiplicative_expression: multiplicative_expression '*' single_expression { $$ = new MulExpr($1, $3, yylineno); }
    | multiplicative_expression '/' single_expression { $$ = new DivExpr($1, $3, yylineno); }
    | multiplicative_expression '%' single_expression { $$ = new ModExpr($1, $3, yylineno); }
    | single_expression {$$ = $1;}
    ;

single_expression: TK_NOT single_expression {$$ = new UnaryExpr(NOT, $2, yylineno);}
    | postfix_expression { $$ = $1;}
    ;

postfix_expression: primary_expression {$$ = $1;}
    | postfix_expression '[' expression ']' { $$ = new ArrayExpr((IdExpr*)$1, $3, yylineno); }
    | postfix_expression '(' ')' { $$ = new MethodInvocationExpr((IdExpr*)$1, *(new ArgumentList), yylineno); }
    | postfix_expression '(' parameters_type_list ')' { $$ = new MethodInvocationExpr((IdExpr*)$1, *$3, yylineno); }
    | postfix_expression TK_PLUS_PLUS { $$ = new PostIncrementExpr((IdExpr*)$1, yylineno); }
    | postfix_expression TK_MINUS_MINUS { $$ = new PostDecrementExpr((IdExpr*)$1, yylineno); }
    | '[' ']' type '{' array_initializer_expression '}' { $$ = new ArrayInitializerExpression($3, *$5, yylineno)}
    ;

array_initializer_expression: array_initializer_expression ',' constant { $$ = $1; $$->push_back($3); }
    | constant { $$ = new ArrayInitializer; $$->push_back($1); }
    ;

primary_expression: '(' expression ')' {$$ = $2;}
    | TK_ID {$$ = new IdExpr($1, yylineno);}
    | constant {$$ = $1;}
    | TK_LIT_STRING { $$ = new StringExpr($1, yylineno); }
    ;

expression: assignment_expression {$$ = $1;}
    ;

assignment_expression: single_expression assignment_operator assignment_expression
    | single_expression assignment_operator assignment_expression
    | logical_or_expression
    | single_expression
    ;

single_expression_list: single_expression_list ',' single_expression { $$ = $1; $$->push_back($3) }
    | single_expression { $$ = new SingleExpr; $$->push_back($1) }
    ;

block_statement: '{' statements '}' { 
        DeclarationList * list = new DeclarationList();
        $$ = new BlockStatement(*$2, *list, yylineno);
        delete list;
    }
    | '{' declarations  statements '}' {$$ = new BlockStatement(*$3, *$2, yylineno); delete $2; delete $3; }
    | '{' '}' {
        StatementList * stmts = new StatementList();
        DeclarationList * decls = new DeclarationList();
        $$ = new BlockStatement(*stmts, *decls, yylineno);
        delete stmts;
        delete decls;
    }
    ;

statements: statements statement { $$ = $1; $$->push_back($2); }
    | statement { $$ = new StatementList; $$->push_back($1); }
    ;

statement: expression_statement {$$ = $1;}
    | if_statement {$$ = $1;}
    | block_statement {$$ = $1;}
    | return_statement {$$ = $1;}
    | TK_PRINT '(' parameters_type_list')' { $$ = new PrintStatement(*$3, yylineno); }
    | TK_PRINT '(' TK_LIT_STRING')' {
        StringExpr * se = new StringExpr($3, yylineno);
        $$ = new PrintStatement(*se, yylineno);
        delete se;
    }
    | TK_PRINT '(' TK_LIT_STRING ',' expression ')' {
        StringExpr * se = new StringExpr($3+$5, yylineno);
        $$ = new PrintStatement(*se, yylineno);
        delete se;
    }
    | for_statement {$$ = $1}
    | TK_CONTINUE { $$ = new ContinueStatement(yylineno); }
    | TK_BREAK { $$ = new BreakStatement(yylineno); }
    ;

if_statement: TK_IF expression statement {$$ = new IfStatement($2, $3, yylineno);}
    | TK_IF expression statement TK_ELSE statement {$$ = new ElseStatement($2, $3, $5, yylineno);}
    ;

for_statement: TK_FOR expression statement { $$ = new ForStatement($2, $3, yylineno); }
    | TK_FOR statement {
        BoolExpr * be = new BoolExpr(true, yylineno);
        $$ = new ForStatement(*be, $2, yylineno);
    }
    | TK_FOR assignment_expression ';' expression ';' additive_expression statement {
        $$ = new ForStatement($2, $4, $6, yylineno);
    }
    ;

return_statement: TK_RETURN expression { $$ = ReturnStatement(*$2, yylineno); }
    ;

expression_statement: expression {$$ = new ExprStatement($1, yylineno);}
    ;

assignment_operator: '=' { $$ = EQUAL; }
    | TK_PLUS_EQUAL {$$ = PLUSEQUAL; }
    | TK_MINUS_EQUAL { $$ = MINUSEQUAL; }
    | TK_AND_EQUAL { $$ = ANDEQUAL; }
    | TK_OR_EQUAL { $$ = OREQUAL; }
    | TK_TIMES_EQUAL { $$ = TIMESEQUAL; }
    | TK_EXPONENT_EQUAL { $$ = EXPONENTEQUAL; }
    | TK_DIVIDE_EQUAL { $$ = DIVIDEEQUAL; }
    | TK_MOD_EQUAL { $$ = MODEQUAL; }
    | TK_ASIG { $$ = ASSIGEQUAL; }
    ;

constant: TK_LIT_INT { $$ = new IntExpr($1 , yylineno);}
    | TK_LIT_FLOAT { $$ = new FloatExpr($1 , yylineno);}
    | TK_LIT_STRING { $$ = new StringExpr($1 , yylineno);}
    | TK_TRUE { $$ = new BoolExpr($1 , yylineno);}
    | TK_FALSE { $$ = new BoolExpr($1 , yylineno);}
    ;

type: TK_INT_TYPE {$$ = INT;}
    | TK_STRING_TYPE {$$ = STRING;}
    | TK_BOOL_TYPE {$$ = BOOL;}
    | TK_FLOAT_TYPE {$$ = INT;}
    ;