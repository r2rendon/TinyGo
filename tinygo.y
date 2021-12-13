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
    StatementList * statements_t;
    InitDeclaratorList * declarator_list_t;
    Init * init_t;
    Declarator * declarator_t;
    Initializer * initializer_t;
    InitializerElementList * init_list_t;
    Declaration * declaration_t;
    DeclarationList * declaration_list_t;
    Parameter * parameter_t;
    ParameterList * parameter_list_t;
    SingleExprList * single_expr_list_t;
}

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

%type<string_t> concat_list
%type<expr_t> assignment_expression logical_or_expression
%type<statements_t> statements input
%type<statement_t> external_declaration func_definition block_statement statement
%type<declaration_t> declaration
%type<declaration_list_t> declarations
%type<initializer_t> initializer
%type<init_list_t> init_list
%type<declarator_list_t> declarator_list
%type<init_t> init_declarator
%type<declarator_t> declarator
%type<parameter_t> parameter_declaration
%type<parameter_list_t> parameters_type_list
%type<int_t> type assignment_operator
%type<expr_t> constant expression logical_and_expression additive_expression multiplicative_expression equality_expression relational_expression
%type<expr_t> single_expression postfix_expression primary_expression
%type<argument_list_t> argument_expression_list
%type <statement_t> if_statement for_statement expression_statement jump_statement print_statement
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

input: input external_declaration {$$ = $1; $$->push_back($2);}
    |  external_declaration {$$ = new StatementList; $$->push_back($1);}
    ;

external_declaration: func_definition {$$ = $1;}
    | declaration {$$ = new GlobalDeclaration($1);}
    ;

func_definition: TK_FUNC TK_ID '(' ')' block_statement {
        ParameterList * pm = new ParameterList;
        $$ = new MethodDefinition($2, *pm, $5, yylineno);
        delete pm;
    }
    | TK_FUNC TK_ID '(' ')' '{' '}' {
        ParameterList * pm = new ParameterList;
        $$ = new MethodDefinition($2, *pm, NULL, yylineno);
        delete pm;
    }
    | TK_FUNC TK_ID '(' parameters_type_list ')' block_statement {
        $$ = new MethodDefinition($2, *($4), $6, yylineno);
        delete $4;
    }
    ;

declarations: declarations declaration { $$ = $1; $$->push_back($2); }
    | declaration {$$ = new DeclarationList; $$->push_back($1);}
    ;

declaration: TK_VAR declarator_list type { $$ = new Declaration((Type)$3, *$2, yylineno); delete $2;  }
    | TK_VAR declarator_list {   $$ = new Declaration((Type)INT, *$2, yylineno); 
        delete $2;
    }
    | TK_VAR declarator_list type initializer { $$ = new Declaration((Type)$3, *$2, yylineno); delete $2;  }
    | TK_VAR declarator_list initializer { 
        $$ = new Declaration((Type)INFERED, *$2, yylineno); 
        delete $2;
    }
    ;


declarator_list: declarator_list ',' init_declarator { $$ = $1; $$->push_back($3); }
    | declarator_list init_declarator { $$ = $1; $$->push_back($2); }
    | init_declarator { $$ = new InitDeclaratorList; $$->push_back($1); }
    ;
      
init_declarator: declarator {$$ = new Init($1, NULL, yylineno);}
    | declarator '=' initializer { $$ = new Init($1, $3, yylineno); }
    | declarator TK_ASIG initializer { $$ = new Init($1, $3, yylineno); }
    ;

declarator: TK_ID {$$ = new Declarator($1, NULL, false, yylineno);}
    | TK_LIT_STRING { $$ = new Declarator($1, NULL, false, yylineno);}
    | TK_ID '[' assignment_expression ']' { $$ = new Declarator($1, $3, true, yylineno);}
    | TK_ID '[' ']' {$$ = new Declarator($1, NULL, true, yylineno);}
    ;
  
initializer: '=' assignment_expression {
        InitializerElementList * list = new InitializerElementList;
        list->push_back($2);
        $$ = new Initializer(*list, yylineno);
    }
    | TK_ASIG assignment_expression {
        InitializerElementList * list = new InitializerElementList;
        list->push_back($2);
        $$ = new Initializer(*list, yylineno);
    }
    | init_list { $$ = new Initializer(*$1, yylineno); delete $1;}
    | '{' init_list '}'{ $$ = new Initializer(*$2, yylineno); delete $2;  }
    | '[' ']' type  '{' init_list '}'{ $$ = new Initializer(*$5, yylineno); delete $5;  }
;

parameters_type_list: parameters_type_list ',' parameter_declaration {$$ = $1; $$->push_back($3);}
                   | parameters_type_list parameter_declaration {$$ = $1; $$->push_back($2);}
                   | parameter_declaration { $$ = new ParameterList; $$->push_back($1); }
                   ;

parameter_declaration: declarator type{ $$ = new Parameter((Type)$2, $1, false, yylineno); }
                     | type { $$ = new Parameter((Type)$1, NULL, false, yylineno); }
                     | type '[' ']'  { $$ = new Parameter((Type)$1, NULL, true, yylineno); }
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
    | multiplicative_expression '^' single_expression { $$ = new ExpExpr($1, $3, yylineno);}
    | single_expression {$$ = $1;}
    ;

single_expression: TK_NOT single_expression {$$ = new SingleExpr(NOT, $2, yylineno);}
    | postfix_expression { $$ = $1;}
    ;

postfix_expression: primary_expression {$$ = $1;}
    | postfix_expression '[' expression ']' { $$ = new ArrayExpr((IdExpr*)$1, $3, yylineno); }
    | postfix_expression '(' ')' { $$ = new MethodInvocationExpr((IdExpr*)$1, *(new ArgumentList), yylineno); }
    | postfix_expression '(' argument_expression_list ')' { $$ = new MethodInvocationExpr((IdExpr*)$1, *($3), yylineno); }
    | postfix_expression TK_PLUS_PLUS { $$ = new PostIncrementExpr((IdExpr*)$1, yylineno); }
    | postfix_expression TK_MINUS_MINUS { $$ = new PostDecrementExpr((IdExpr*)$1, yylineno); }
    ;

argument_expression_list: argument_expression_list ',' assignment_expression {$$ = $1;  $$->push_back($3);}
    | assignment_expression { $$ = new ArgumentList; $$->push_back($1);}
    ;

primary_expression: '(' expression ')' {$$ = $2;}
    | TK_ID {$$ = new IdExpr($1, yylineno);}
    | constant {$$ = $1;}
    | TK_LIT_STRING { $$ = new StringExpr($1, yylineno); }
    ;

expression: assignment_expression {$$ = $1;}
          ;

assignment_expression: single_expression assignment_operator assignment_expression  
    | logical_or_expression
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
              | statements expression_statement { $$ = $1; $$->push_back($2); }
              | statement { $$ = new StatementList; $$->push_back($1); }
              | expression_statement { $$ = new StatementList; $$->push_back($1); }
              ;

statement:  if_statement {$$ = $1;}
    | block_statement {$$ = $1;}
    | jump_statement {$$ = $1;}
    | for_statement { $$ = $1;}
    | print_statement { $$ = $1; }
    ;

jump_statement: TK_RETURN expression {$$ = new ReturnStatement($2, yylineno);}
              | TK_BREAK { $$ = new BreakStatement(yylineno);}
              | TK_CONTINUE { $$ = new ContinueStatement(yylineno);}
              | TK_RETURN { $$ = new ReturnStatement(NULL, yylineno);}
              ;

if_statement: TK_IF expression statement {$$ = new IfStatement($2, $3, yylineno);}
    | TK_IF expression statement TK_ELSE statement {$$ = new ElseStatement($2, $3, $5, yylineno);}
    ;

print_statement: TK_PRINT '(' concat_list ')' {$$ = new PrintStatement($3,NULL,yylineno);}
               | TK_PRINT '(' concat_list ',' expression ')'{$$ = new PrintStatement($3,$5,yylineno);}
               | TK_PRINT '(' expression ')' {$$ = new PrintStatement("",$3,yylineno);}
               ;
concat_list: concat_list ',' TK_LIT_STRING { $$ = $1;}
           | TK_LIT_STRING {$$=$1;}
           | TK_ID { $$ = $1;}
            ;
for_statement: TK_FOR expression statement { $$ = new ForStatement($2, $3, yylineno); }
    | TK_FOR statement  { {$$ = new ForStatement(NULL,$2,yylineno);} }
    | TK_FOR assignment_expression ';' expression ';' additive_expression statement {
        $$ = new ForStatementExtended($2, $4, $6,$7, yylineno);    }
    ;

expression_statement: expression {$$ = new ExprStatement($1, yylineno);}
    ;

assignment_operator:'=' { $$ = EQUAL;}
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