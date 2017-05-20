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
%nonassoc SIGN_PRECEDENCE
%left OP_INCREMENT OP_DECREMENT
%nonassoc ARR_IDX
%left '[' ']'

%{
	#include <stdio.h>
	#include "y.tab.h"
	void yyerror(char *s);
	int yylex(void);
	int sym[26];
%}

%%

program: declaration ';' program
	|function_declaration '{' compound_statement '}' program
	|statement ';' program
	|if_else_statement program
	|for_statement program
	;
if_else_statement: KEY_IF '(' expression ')' '{' compound_statement '}' KEY_ELSE '{' compound_statement '}'
	| KEY_IF '(' expression ')' '{' compound_statement '}'
	;
for_statement: KEY_FOR '(' optionalExpression ';' optionalExpression ';' optionalExpression ')' '{' compound_statement '}'
	;
optionalExpression: expression
	|
	;
compound_statement: declarations statements
	;
declarations: over1Declarations
	|
	;
over1Declarations: declaration ';'
	| declaration ';' over1Declarations
	;
statements: over1Statements
	|
	;

over1Statements: allKindsOfStatements
	| allKindsOfStatements over1Statements
	;

allKindsOfStatements: statement ';'
	| if_else_statement
	| for_statement
	;

statement: ID '=' expression
	| ID arr_indices '=' expression
	| ID '(' expressions  ')'
	| ID '(' ')'
	;
arr_indices: '[' expression ']'
	| '[' expression ']' arr_indices
	;
declaration: TYPE identifiers
	|KEY_CONST TYPE const_identifiers
	|function_declaration
	;
function_declaration: TYPE ID '(' parameters ')'
	|TYPE_VOID ID '(' parameters ')'
	;

parameters: parameters_over1
	|
	;
parameters_over1:TYPE ID arr_brackets ',' parameters_over1
	| TYPE ID ',' parameters_over1
	| TYPE ID arr_brackets
	| TYPE ID
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
	|'(' expression ')'
	|'+' expression %prec SIGN_PRECEDENCE
	|'-' expression %prec SIGN_PRECEDENCE
	|ID '(' expressions ')'
	|ID '(' ')'
	|ID arr_indices %prec ARR_IDX
	;
%%

void yyerror(char *s){
	fprintf(stderr, "%s\n", s);
}

int main(void){
	yyparse();
	return 0;
}
