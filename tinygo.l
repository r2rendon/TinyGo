%option noyywrap
%option yylineno
%option caseless
%x comment

%{
    #include <stdio.h>
    #include "tokens.h"
%}

DIGIT [0-9]

%%

[\t \r \n] { /* nada */ }
"/*" {BEGIN(comment);}
"break" { return TK_BREAK; }
"func" { return TK_FUNC; }
"else" { return TK_ELSE; }
"package" { return TK_PACKAGE; }
"if" { return TK_IF; }
"continue" { return TK_CONTINUE; }
"int" { return TK_INT_TYPE; }
"float32" { return TK_FLOAT_TYPE;  }
"bool" { return TK_BOOL_TYPE; }
"string" { return TK_STRING_TYPE; }
"var" {return TK_VAR;}
"fmt.Println" { return TK_PRINT; }
"for" {return TK_FOR;}
"import" {return TK_IMPORT;}
"return" {return TK_RETURN ;}
"true" {return TK_TRUE;}
"false" {return TK_FALSE ;}
"func main()" {return TK_MAIN ;}
\".*\" { return TK_LIT_STRING; }
{DIGIT}+ {return TK_LIT_INT; }
{DIGIT}+"."{DIGIT}+ { return TK_LIT_FLOAT; }
[a-zA-Z]({DIGIT}|[a-zA-Z_0-9]|_)* { return TK_ID; }
"+" {return '+' ;}
"+=" {return TK_PLUS_EQUAL;}
"&=" {return TK_AND_EQUAL;}
"&&" {return TK_AND ;}
"==" {return TK_EQUAL_EQUAL;}
"!=" {return TK_NOT_EQUAL ;}
"(" {return '(';}
")" {return ')';}
"-" {return '-';}
"-=" {return TK_MINUS_EQUAL;}
"|=" {return TK_OR_EQUAL;}
"||" {return TK_OR;}
"<" {return '<' ;}
"<=" {return TK_LESS_OR_EQUAL ;}
"[" {return '[';}
"]" {return ']';}
"*" {return '*';}
"^" {return '^';}
"*=" {return TK_TIMES_EQUAL;}
"^=" {return TK_EXPONENT_EQUAL;}
">" {return '>' ;}
">=" {return TK_GREATER_OR_EQUAL;}
"{" {return '{';}
"}" {return '}';}
"/" {return '/' ;}
"/=" {return TK_DIVIDE_EQUAL;}
"++" {return TK_PLUS_PLUS ;}
"=" {return '=' ;}
":=" {return TK_ASIG;}
"," {return ',' ;}
";" {return ';';}
"%" {return '%' ;}
"%=" {return TK_MOD_EQUAL;}
"--" {return TK_MINUS_MINUS ;}
"!" {return '!';}
":" {return ':';}
"//"[^\n]* {/* nada */}
. {printf("caracter '%c' invalido en la linea %d\n", yytext[0], yylineno);}

<comment>"*/" {BEGIN(INITIAL);}
<comment>.|\n {/*nada*/}
<comment><<EOF>> {printf("comentario incompleto en la linea %d\n", yylineno); return 0;}
%%