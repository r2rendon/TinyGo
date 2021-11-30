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
"var" {return TK_VAR;}
"println" { return TK_PRINT; }
"for" {return TK_FOR;}
"import" {return TK_IMPORT;}
"return" {return TK_RETURN ;}
"true" {return TK_TRUE;}
"false" {return TK_FALSE ;}
"+" {return '+' ;}
"+=" {return TK_PLUSEQUAL;}
"&=" {return TK_ANDEQUAL;}
"&&" {return TK_AND ;}
"==" {return TK_EQUALEQUAL;}
"!=" {return TK_NOTEQUAL ;}
"(" {return '(';}
")" {return ')';}
"-" {return '-';}
"-=" {return TK_MINUSEQUAL;}
"|=" {return TK_ORQUAL;}
"||" {return TK_OR;}
"<" {return '<' ;}
"<=" {return TK_MINUSEQUAL ;}
"[" {return '[';}
"]" {return ']';}
"*" {return '*';}
"^" {return '^';}
"*=" {return TK_TIMESEQUAL;}
"^=" {return TK_EXPONENTEQUAL;}
">" {return '>' ;}
">=" {return TK_GREATEREQUAL;}
"{" {return '{';}
"}" {return '}';}
"/" {return '/' ;}
"/=" {return TK_DIVIDEEQUAL;}
"++" {return TK_PLUSPLUS ;}
"=" {return '=' ;}
":=" {return TK_ASIG;}
"," {return ',' ;}
";" {return ';';}
"%" {return '%' ;}
"%=" {return TK_MODEQUAL;}
"--" {return TK_MINUSMINUS ;}
"!" {return '!';}
":" {return ':';}


\".*\" { yylval.string_t = strdup(yytext); return TK_LIT_STRING; }
{DIGIT}+ { yylval.int_t = atoi(yytext); return TK_LIT_INT; }
{DIGIT}+"."{DIGIT}+ { yylval.float_t = atof(yytext); return TK_LIT_FLOAT; }
[a-zA-Z]({DIGIT}|[a-zA-Z_0-9]|_)* { yylval.string_t = strdup(yytext); return TK_ID; }

"//"[^\n]* {/* nada */}
. {printf("caracter '%c' invalido en la linea %d\n", yytext[0], yylineno);}

<comment>"*/" {BEGIN(INITIAL);}
<comment>.|\n {/*nada*/}
<comment><<EOF>> {printf("comentario incompleto en la linea %d\n", yylineno); return 0;}
%%