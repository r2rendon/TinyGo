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
    // #define EQUAL 1
    // #define PLUSEQUAL 2
    // #define MINUSEQUAL 3
%}

%token TK_LIT_STRING TK_ID TK_MAIN
%token TK_LIT_INT
%token TK_LIT_FLOAT
%token TK_IF TK_ELSE
%token TK_FOR TK_RETURN
%token TK_INT_TYPE TK_FLOAT_TYPE TK_BOOL_TYPE TK_STRING_TYPE TK_VAR 
%token TK_ASIG
%token TK_PRINT TK_BREAK TK_FUNC TK_PACKAGE TK_CONTINUE
%token TK_IMPORT TK_TRUE TK_FALSE
%token TK_PLUS_EQUAL TK_MINUS_EQUAL TK_PLUS_PLUS TK_MINUS_MINUS TK_NOT
%token TK_AND TK_AND_EQUAL TK_EQUAL_EQUAL TK_OR_EQUAL
%token TK_OR TK_AND
%token TK_NOT_EQUAL TK_GREATER_OR_EQUAL TK_LESS_OR_EQUAL TK_TIMES_EQUAL TK_EXPONENT_EQUAL TK_DIVIDE_EQUAL TK_MOD_EQUAL

start: package_list input

package_list: /* vacio */
    | package_list package
    | package
    ;

package: TK_PACKAGE TK_ID
    | TK_IMPORT TK_LIT_STRING
    ;

input: external_declaration TK_MAIN block_statement
    | TK_MAIN block_statement
    ;

external_declaration: func_definition
    | declarations
    ;

func_definition: TK_FUNC TK_ID '(' parameters_type_list ')' block_statement 
    | TK_FUNC TK_ID '(' ')' block_statement
    | TK_FUNC TK_ID '(' parameters_type_list ')' '{' '}'
    | TK_FUNC TK_ID '(' ')' '{' '}'
    ;

declarations: declarations declaration
    | declaration
    ;

declaration: TK_VAR declarator_list type
    | TK_VAR declarator_list type initializer
    | TK_VAR declarator_list initializer
    ;

declarator_list: declarator_list ',' declarator
    | declarator
    ;

declarator: TK_ID
    | TK_ID '[' ']'
    ;

initializer: assignment_expression
    | init_list
    ;

init_list: init_list ',' logical_or_expression
    | logical_or_expression
    ;

logical_or_expression: logical_or_expression TK_OR logical_and_expression
    | logical_and_expression
    ;

logical_and_expression: logical_and_expression TK_AND equality_expression
    | equality_expression
    ;

equality_expression:  equality_expression TK_EQUAL_EQUAL relational_expression
    | equality_expression TK_NOT_EQUAL relational_expression
    | relational_expression
    ;

relational_expression: relational_expression '>' additive_expression
    | relational_expression '<' additive_expression
    | relational_expression TK_GREATER_OR_EQUAL additive_expression
    | relational_expression TK_LESS_OR_EQUAL additive_expression
    | additive_expression

additive_expression:  additive_expression '+' multiplicative_expression
    | additive_expression '-' multiplicative_expression
    | multiplicative_expression
    ;

multiplicative_expression: multiplicative_expression '*' single_expression { $$ = new MulExpr($1, $3, yylineno); }
    | multiplicative_expression '/' single_expression { $$ = new DivExpr($1, $3, yylineno); }
    | single_expression {$$ = $1;}
    ;

single_expression: TK_NOT single_expression
    | postfix_expression
    ;

postfix_expression: primary_expression
    | postfix_expression '[' expression ']'
    | postfix_expression '(' ')'
    | postfix_expression '(' argument_expression_list ')'
    | postfix_expression TK_PLUS_PLUS
    | postfix_expression TK_MINUS_MINUS
    ;

primary_expression: '(' expression ')'
    | TK_ID
    | constant
    | TK_LIT_STRING
    ;

expression: assignment_expression
    ;

assignment_expression: single_expression assignment_operator assignment_expression
    | logical_or_expression
    ;

block_statement: '{' statements '}'
    | '{' declarations  statements '}'
    | '{' '}'
    ;

statements: statements statement
    | statement
    ;

statement: expression_statement
    | if_statement
    | block_statement
    | return_statement
    | TK_PRINT expression
    | for_statement
    ;

if_statement: TK_IF expression statement
    | TK_IF expression statement TK_ELSE statement
    ;

for_statement: TK_FOR expression statement
    | TK_FOR statement
    | TK_FOR assignment_operator ';' expression ';' additive_expression statement
    ;

return_statement: TK_RETURN expression
    ;

expression_statement: expression
    ;

assignment_operator: '='
    | TK_PLUS_EQUAL
    | TK_MINUS_EQUAL
    | TK_AND_EQUAL
    | TK_OR_EQUAL
    | TK_TIMES_EQUAL
    | TK_EXPONENT_EQUAL
    | TK_DIVIDE_EQUAL
    | TK_MOD_EQUAL
    | TK_ASIG
    ;

constant: TK_LIT_INT
    | TK_LIT_FLOAT
    | TK_LIT_STRING
    ;

type: TK_INT_TYPE
    | TK_STRING_TYPE
    | TK_BOOL_TYPE
    | TK_FLOAT_TYPE
    ;