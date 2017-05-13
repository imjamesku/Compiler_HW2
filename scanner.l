%{
#include <stdio.h>
#include <string.h>
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
}
":"|";"|","|"."|"("|")"|"["|"]"|"{"|"}"	{
	if(token_on)
		printf("#punc:%s\n", yytext);
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
}
"+"|"-"|"*"|"/"|"%"|"++"|"--"|"<"|"<="|">"|">"|">="|"=="|"!="|"="|"&&"|"||"|"!"|"*"|"&"	{
	if(token_on)
		printf("#op:%s\n", yytext);
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
}
([0-9]*\.[0-9]+)|([0-9]+\.[0-9]*)/[^0-9a-zA-Z_]	{
/*doubles*/
	if(token_on)
		printf("#double:%s\n", yytext);
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
}
([1-9][0-9]*|0)/[^0-9a-zA-Z_\.]	{
/*Integers*/
	if(token_on)
		printf("#integer:%s\n", yytext);
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
}

(([0-9]+)|([0-9]+\.[0-9]*)|([0-9]*\.[0-9]+))[eE][+-]?[0-9]+/[^\.0-9a-zA-Z_]	{
/*scientific notation*/
	if(token_on)
		printf("#sci:%s\n", yytext);
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
}
[a-zA-Z_][a-zA-Z0-9_]*/[^a-zA-Z_0-9]	{
/*identifiers*/
	if(token_on)
		printf("#id:%s\n", yytext);
	strcpy(line_buf_ptr, yytext);
	line_buf_ptr += strlen(yytext);
}
#error
.	{
	fprintf(stderr, "Error at line %d: %s\n", num_lines, yytext);
	exit(1);
}
%%
int main(int argc, char* argv[]){
	//printf("arc = %d\n", argc);
	//printf("arcv[0] = %s\n", argv[0]);
	/*if(argc > 0)
		yyin = fopen(argv[0], "r");
	else
		yyin = stdin;*/
	yylex();
	//printf("#num_lines = %d\n", num_lines);
	return 0;
}

