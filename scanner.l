%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"
#define MAX_STR_CONST 2048
int num_lines = 1, char_counter;
int source_on = 1, token_on = 1;
char string_buf[MAX_STR_CONST];
char *string_buf_ptr;
char line_buf[MAX_STR_CONST];
char *line_buf_ptr = line_buf;
%}
%x comment
%x string
%x char_condition
%x oneLineComment
%%
"#pragma source on"	{
	source_on = 1;
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
}
"#pragma source off"	{
	source_on = 0;
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
}
"#pragma token on"	{
	token_on = 1;
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
}
"#pragma token off"	{
	token_on = 0;
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
}
"/*"	{
	/*comment start*/
		BEGIN(comment);
		//printf("/*");
		strcpy(line_buf_ptr, yytext);
		line_buf_ptr += strlen(yytext);
		
}
<comment>"*/"	{
		BEGIN(INITIAL);
		//printf("*/");
		strcpy(line_buf_ptr, yytext);
		line_buf_ptr += strlen(yytext);
}
<comment>\n	{
/*new line*/
		//num_lines++;
		*line_buf_ptr++ = '\0';
		//printf("\n");
		if(source_on)
			printf("%d:%s\n", num_lines, line_buf);
		line_buf_ptr = line_buf;
		num_lines++;
}
<comment>[^\n]	{
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
}


"//"	{
	/*oneLineComment start*/
	BEGIN(oneLineComment);
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
	//printf("//");
}
<oneLineComment>\n	{
/*new line*/
	//num_lines++;
	//printf("\n");
	BEGIN(INITIAL);
	unput('\n');
}
<oneLineComment>[^\n]*	{
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
}
\"	{
/*string  starting quote*/
		//strcpy(string_buf, yytext);
		//string_buf[yyleng-1] = '\0';
		//string_buf_ptr = string_buf+1;
		string_buf_ptr = string_buf;
		//if(token_on)
		//	printf("#string:%s\n", string_buf_ptr);
		//strcpy(line_buf_ptr, yytext);
		//line_buf_ptr += yyleng;
		BEGIN(string);
}
<string>{
	\"	{
	/*end string*/
		*string_buf_ptr = '\0';
		*line_buf_ptr++ = '"';
		strcpy(line_buf_ptr, string_buf);
		line_buf_ptr += strlen(string_buf);
		*line_buf_ptr++ = '"';
		if(token_on)
			printf("#string:%s\n", string_buf);
		BEGIN(INITIAL);
		return STRING;
	}
	\\\"	{
		*string_buf_ptr++ = '\\';
		*string_buf_ptr++ = '"';
	}
	.	{
	/*a \n in a string results in an error*/
		*string_buf_ptr++ = yytext[0];
	}
	\n	{
		/*error
		cannot switch lines in a string*/
		fprintf(stderr, "Error at line %d: %s\n", num_lines, yytext);
		exit(1);
	}
}
"'"	{
	BEGIN(char_condition);
	char_counter = 0;
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
}
<char_condition>{
	/*If char_counter>=1 error, there should be only 1 char in the quote.*/
	\'	{
		BEGIN(INITIAL);
		strcpy(line_buf_ptr, yytext);
		line_buf_ptr += strlen(yytext);
		return CHAR;
	}
	[ -~]	{
		if(char_counter > 0){	
			fprintf(stderr, "Error at line %d: %s\n", num_lines, yytext);
			exit(1);
		}
			
		if(token_on)
			printf("#char:\'%c\'\n", yytext[0]);
		char_counter++;
		strcpy(line_buf_ptr, yytext);
		line_buf_ptr += strlen(yytext);
	}
	\\n	{
		if(char_counter > 0){
			fprintf(stderr, "Error at line %d: %s\n", num_lines, yytext);
			exit(1);
		}
		if(token_on)
			printf("#char:\'\\n\'\n");
		char_counter++;
		strcpy(line_buf_ptr, yytext);
		line_buf_ptr += strlen(yytext);
	}
	\\t	{
		if(char_counter > 0){
			fprintf(stderr, "Error at line %d: %s\n", num_lines, yytext);
			exit(1);
		}
		if(token_on)
			printf("#char:\'\\t\'\n");
		char_counter++;
		strcpy(line_buf_ptr, yytext);
		line_buf_ptr += strlen(yytext);
	}
	/*\\r	printf("#char:%c\n", '\r');
	\\b	printf("#char:%c\n", '\b');
	\\f	printf("#char:%c\n", '\f');*/
}

\n	{
/*new line*/
	//num_lines++;
	*line_buf_ptr++ = '\0';
	//printf("-------line %d-------\n", num_lines);
	if(source_on)
		printf("%d:%s\n", num_lines, line_buf);
	line_buf_ptr = line_buf;
	num_lines++;
}
" "	{
/*space*/
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
}
\t	{
/*tabs*/
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
}
(void|int|double|bool|char|null|for|while|do|if|else|switch|return|break|continue|const|true|false|struct|case|default|fclose|clearerr|feof|ferror|fflush|fgetpos|fopen|fread|freopen|fseek|fsetpos|ftell|fwrite|remove|rename|rewind|setbuf|tmpfile|tmpnam|fprintf|printf|sprintf|vfprintf|vprintf|vsprintf|fscanf|scanf|sscanf|fgetc|fgets|fputc|fputs|getc|getchar|gets|putc|putchar|puts|ungetc|perror)/[^0-9a-zA-Z_]	{
	if(token_on)
		printf("#key:%s\n", yytext);
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
	if(strcmp(yytext, "void") == 0)
		return TYPE_VOID;
	else if(strcmp(yytext, "int") == 0)
		return TYPE;
	else if(strcmp(yytext, "double") == 0)
		return TYPE;
	else if(strcmp(yytext, "bool") == 0)
		return TYPE;
	else if(strcmp(yytext, "char") == 0)
		return TYPE;
	else if(strcmp(yytext, "null") == 0)
		return CONSTANT;
	else if(strcmp(yytext, "for") == 0)
		return KEY_FOR;
	else if(strcmp(yytext, "while") == 0)
		return KEY_WHILE;
	else if(strcmp(yytext, "do") == 0)
		return KEY_DO;
	else if(strcmp(yytext, "if") == 0)
		return KEY_IF;
	else if(strcmp(yytext, "else") == 0)
		return KEY_ELSE;
	else if(strcmp(yytext, "switch") == 0)
		return KEY_SWITCH;
	else if(strcmp(yytext, "return") == 0)
		return KEY_RETURN;
	else if(strcmp(yytext, "break") == 0)
		return KEY_BREAK;
	else if(strcmp(yytext, "continue") == 0)
		return KEY_CONTINUE;
	else if(strcmp(yytext, "const") == 0)
		return KEY_CONST;
	else if(strcmp(yytext, "true") == 0)
		return CONSTANT;
	else if(strcmp(yytext, "false") == 0)
		return CONSTANT;
	else if(strcmp(yytext, "struct") == 0)
		return KEY_STRUCT;
	else if(strcmp(yytext, "case") == 0)
		return KEY_CASE;
	else if(strcmp(yytext, "default") == 0)
		return KEY_DEFAULT;
	else
		return ID;
	/*else if(strcmp(yytext, "fclose") == 0)
		return ID;
	else if(strcmp(yytext, "clearerr") == 0)
		return ID;
	else if(strcmp(yytext, "feof") == 0)
		return ID;
	else if(strcmp(yytext, "ferror") == 0)
		return ID;
	else if(strcmp(yytext, "fflush") == 0)
		return ID;
	else if(strcmp(yytext, "fgetpos") == 0)
		return ID;
	else if(strcmp(yytext, "fopen") == 0)
		return ID;
	else if(strcmp(yytext, "fread") == 0)
		return ID;
	else if(strcmp(yytext, "freopen") == 0)
		return ID;
	else if(strcmp(yytext, "fseek") == 0)
		return ID;
	else if(strcmp(yytext, "fsetpos") == 0)
		return ID;
	else if(strcmp(yytext, "ftell") == 0)
		return ID;
	else if(strcmp(yytext, "fwrite") == 0)
		return ID;
	else if(strcmp(yytext, "remove") == 0)
		return ID;
	else if(strcmp(yytext, "rename") == 0)
		return ID;
	else if(strcmp(yytext, "rewind") == 0)
		return ID;
	else if(strcmp(yytext, "setbuf") == 0)
		return ID;
	else if(strcmp(yytext, "tmpfile") == 0)
		return ID;
	else if(strcmp(yytext, "tmpnam") == 0)
		return ID;
	else if(strcmp(yytext, "fprintf") == 0)
		return ID;
	else if(strcmp(yytext, "printf") == 0)
		return ID;
	else if(strcmp(yytext, "sprintf") == 0)
		return ID;
	else if(strcmp(yytext, "vfprintf") == 0)
		return ID;
	else if(strcmp(yytext, "vprintf") == 0)
		return ID;
	else if(strcmp(yytext, "vsprintf") == 0)
		return ID;
	else if(strcmp(yytext, "fscanf") == 0)
		return ID;
	else if(strcmp(yytext, "fscanf") == 0)
		return ID;
	else if(strcmp(yytext, "scanf") == 0)
		return ID;
	else if(strcmp(yytext, "sscanf") == 0)
		return ID;
	else if(strcmp(yytext, "fgetc") == 0)
		return ID;
	else if(strcmp(yytext, "fgets") == 0)
		return ID;
	else if(strcmp(yytext, "fputc") == 0)
		return ID;
	else if(strcmp(yytext, "fputs") == 0)
		return ID;
	else if(strcmp(yytext, "getc") == 0)
		return ID;
	else if(strcmp(yytext, "fscanf") == 0)
		return ID;*/
}
":"|";"|","|"."|"("|")"|"["|"]"|"{"|"}"	{
/*punctuation*/
	if(token_on)
		printf("#punc:%s\n", yytext);
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
	return yytext[0];
}
"+"|"-"|"*"|"/"|"%"|"++"|"--"|"<"|"<="|">"|">"|">="|"=="|"!="|"="|"&&"|"||"|"!"|"*"|"&"	{
/*operators*/
	if(token_on)
		printf("#op:%s\n", yytext);
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
	if(strcmp(yytext, "++") == 0)
		return OP_INCREMENT;
	else if(strcmp(yytext, "--") == 0)
		return OP_DECREMENT;
	else if(strcmp(yytext, "<") == 0)
		return OP_CMP;
	else if(strcmp(yytext, "<=") == 0)
		return OP_CMP;
	else if(strcmp(yytext, ">") == 0)
		return OP_CMP;
	else if(strcmp(yytext, ">=") == 0)
		return OP_CMP;
	else if(strcmp(yytext, "==") == 0)
		return OP_CMP;
	else if(strcmp(yytext, "!=") == 0)
		return OP_CMP;
	else if(strcmp(yytext, "&&") == 0)
		return OP_LAND;
	else if(strcmp(yytext, "||") == 0)
		return OP_LOR;
	else
		return yytext[0];
	
}
([0-9]*\.[0-9]+)|([0-9]+\.[0-9]*)/[^0-9a-zA-Z_]	{
/*doubles*/
	if(token_on)
		printf("#double:%s\n", yytext);
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
	return DOUBLE;
}
([1-9][0-9]*|0)/[^0-9a-zA-Z_\.]	{
/*Integers*/
	if(token_on)
		printf("#integer:%s\n", yytext);
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
	//yylval.intValue = atoi(yytext);
	return INTEGER;
}

(([0-9]+)|([0-9]+\.[0-9]*)|([0-9]*\.[0-9]+))[eE][+-]?[0-9]+/[^\.0-9a-zA-Z_]	{
/*scientific notation*/
	if(token_on)
		printf("#sci:%s\n", yytext);
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
	return SCI_NOTATION;
}
[a-zA-Z_][a-zA-Z0-9_]*/[^a-zA-Z_0-9]	{
/*identifiers*/
	if(token_on)
		printf("#id:%s\n", yytext);
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
	return ID;
}
#error
.	{
	fprintf(stderr, "Error at line %d: %s\n", num_lines, yytext);
	exit(1);
}
%%
/*int main(int argc, char* argv[]){
	yylex();
	//printf("#num_lines = %d\n", num_lines);
	return 0;
}*/

