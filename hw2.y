%token INTEGER STRING DOUBLE SCI_NOTATION CHAR
%token TYPE TYPE_VOID
%token CONSTANT
%token KEY_FOR KEY_WHILE KEY_DO KEY_IF KEY_ELSE KEY_SWITCH KEY_RETURN KEY_BREAK KEY_CONTINUE KEY_CONST KEY_STRUCT KEY_CASE KEY_DEFAULT
%token ID
%token OP_INCREMENT OP_DECREMENT OP_CMP OP_LAND OP_LOR

%left OP_LOR
%left OP_LAND
%left '!'
%left OP_CMP
%left '+' '-'
%left '*' '/' '%'
%left OP_INCREMENT OP_DECREMENT
%left '[' ']'

%{
	#include <stdio.h>
	#include "y.tab.h"
	void yyerror(char *s);
	int yylex(void);
	int sym[26];
%}

%%

program: expression program
	|declaration ';' program
	|function_declaration '{' program '}' program
	|
	;

declaration: TYPE identifiers
	|KEY_CONST TYPE const_identifiers
	|function_declaration
	;
function_declaration: TYPE ID '(' parameters ')'
	|TYPE_VOID ID '(' parameters ')'
	;

parameters: TYPE ID
	| TYPE ID arr_brackets
	| TYPE ID ',' parameters
	|
	;

identifiers: identifier
	|identifier ',' identifiers
	;

identifier:
	ID
	|ID '=' expression
	|ID arr_brackets
	|ID arr_brackets '=' '{' expressions '}'
	;

arr_brackets: '[' INTEGER ']'
	|'[' INTEGER ']'  arr_brackets
	;

const_identifiers: const_identifier
	|const_identifier ',' const_identifiers
	;

const_identifier:ID '=' expression
	;

expressions: expression
	|expression ',' expressions
	;

expression: expression OP_LOR expression
	|expression OP_LAND expression
	|expression OP_CMP expression
	|'!' expression
	|expression '+' expression
	|expression '-' expression
	|expression '*' expression
	|expression '/' expression
	|expression '%' expression
	|expression OP_INCREMENT
	|expression OP_DECREMENT
	|INTEGER
	|DOUBLE
	|SCI_NOTATION
	|CHAR
	|ID
	|STRING
	|CONSTANT
	;
%%

void yyerror(char *s){
	fprintf(stderr, "%s\n", s);
}

int main(void){
	yyparse();
	return 0;
}
