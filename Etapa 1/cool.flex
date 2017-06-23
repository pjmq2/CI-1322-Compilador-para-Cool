/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

int tamComent;
int tamString;
void resetString();
void agregString(char* str);

/*
 *  Add Your own definitions here
 */

%}

/*
 * Define names for regular expressions here.
 * Los TOKENS se tomaron de cool-parse.h
 */
 
/*
*Los Keywords pueden estar en mayuscula o minuscula, solo true y false TIENEN que empezar en minuscula
*/

TRUE       		t[Rr][Uu][Ee]
FALSE      		f[Aa][Ll][Ss][Ee]
CLASS 			class|CLASS|Class
ELSE 			[Ee][Ll][Ss][Ee]
FI 			fi|FI
IF 			if
IN 			in
INHERITS 		[Ii][Nn][Hh][Ee][Rr][Ii][Tt][Ss]
LET        		let|Let|lEt
LOOP       		[lL][oO][Oo][pP]
POOL       		[Pp][oO][Oo][lL]
THEN       		[Tt][hH][Ee][nN]
WHILE      		while|whIle
CASE 			case
ESAC 			e[Ss]a[Cc]
OF 			of
NEW			new
ISVOID			[Ii][Ss][Vv][Oo][Ii][Dd]

/* 
* otros caracteres y operadores
*/

INT_CONST 		[0-9]+
TYPEID     	[A-Z][A-Za-z0-9_]*
OBJECTID   	[a-z][A-Za-z0-9_]*
ASSIGN 		<-
NOT 		not|NOT
LE 		<=
DARROW		=>
WHITESPACE 	[ \t\r]*
INVISIABLE_CHAR [\r\f\v]
OTHER      [{};:,\.()<=\+\-~@\*/]
NEWLINE 	\n

%x Comentario
%x STRING
%x ERRORSTRINGLARGA
%x NULLSTRING

%%

 /*
  *  Nested comments
  */


 /*
  *  The multiple-character operators.
  * Al parecer la funcion "cool_yylval.symbol = inttable.add_string(yytext);" permite agregar lo que se esta analizando a symbol de la variable global cool_yylval
  *Se trabaja directamente con los TOKENS
  */
 
{DARROW}		{ return (DARROW); }
{CLASS}			{ return (CLASS);}
{ELSE}			{ return (ELSE);}
{FI}			{ return (FI);}
{IF}			{ return (IF);}
{IN}			{ return (IN);}
{INHERITS}		{ return (INHERITS);}
{LET}			{ return (LET);}
{LOOP}			{ return (LOOP);}
{POOL}			{ return (POOL);}
{THEN}			{ return (THEN);}
{WHILE}			{ return (WHILE);}
{CASE}			{ return (CASE);}
{ESAC}			{ return (ESAC);}
{OF}			{ return (OF);}
{NEW}			{ return (NEW);}
{ISVOID}		{ return (ISVOID);}
{ASSIGN}		{ return (ASSIGN);}
{LE}			{ return (LE);}
{NOT}			{ return (NOT);}

 /*
  * Son TOKENS que requieren mas trabajo, se empieza a trabajar con cool_yylval
  */
  
{FALSE}			{ 
				cool_yylval.boolean = false;
				return (BOOL_CONST);}

{TRUE}			{ 
				cool_yylval.boolean = true;
				return (BOOL_CONST );}

{TYPEID} 		{
				cool_yylval.symbol = idtable.add_string(yytext);
				return (TYPEID);}
				
{OBJECTID} 		{
			cool_yylval.symbol = idtable.add_string(yytext);
			return OBJECTID;
			}

{INT_CONST}		{
			cool_yylval.symbol = inttable.add_string(yytext);
			return (INT_CONST);
			}
{OTHER} {
	return (char)*yytext;
}
 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */  

"(*"	string_buf_ptr = string_buf; BEGIN(Comentario);curr_lineno++;
				
<Comentario>{
	\(\* tamComent++;curr_lineno++;			
	[^\*\)] /* mata todo lo que no sea "*)" */
	[^\*\n\(]* /* mata lo que no sea un * con un cambio de linea */
	"*"[^\*\)\n]* /* mata las lineas de que empiezan con * y tienen lo que sea */
	\\\n curr_lineno++;
	\n curr_lineno++;
	[\w]*\) curr_lineno++;/* mata las palabras seguidas de ) */
}
<Comentario>"*)"  	{
			if (tamComent>0){
				tamComent--;
				curr_lineno++;
			}
			else{
				BEGIN(INITIAL);
			}			
			}
<Comentario><<EOF>>  	{
			BEGIN(INITIAL);
			cool_yylval.error_msg = "EOF in comment";
			return ERROR;
			}

\"			{
			BEGIN(STRING);
			string_buf_ptr = string_buf;
			string_buf[0] = '\0';
			}
<ERRORSTRINGLARGA>.*\n	{
				resetString();
				BEGIN(INITIAL);
    				cool_yylval.error_msg = "String constant too long";
    				return ERROR;
				}
 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c. 
  *
  */
<STRING>(\0|\\\0)	{
			cool_yylval.error_msg = "String contains null character.";
			BEGIN(NULLSTRING);
			return ERROR;
			}
<NULLSTRING>.*[\"\n] 	{
			BEGIN(INITIAL);
			}
<STRING>\\\n		{
			agregString("\n");
			curr_lineno++;
			}
<STRING>\n		{
			cool_yylval.error_msg = "String sin terminar";
			curr_lineno++; 
			resetString();
			BEGIN(INITIAL);
			return ERROR;
			}
<STRING><<EOF>>		{
			curr_lineno++;
			BEGIN(INITIAL);
			cool_yylval.error_msg = "EOF in String";
			return ERROR;
			}
<STRING>\"  		{ 
			cool_yylval.symbol = stringtable.add_string(string_buf);
			resetString(); 
			BEGIN(INITIAL); 
			return STR_CONST;
			}
<STRING>\\n {agregString("\n");}
<STRING>\\t {agregString("\t");}
<STRING>\\b {agregString("\b");}
<STRING>\\f {agregString("\f");}
<STRING>\\. {agregString(&strdup(yytext)[1]);}
<STRING>. {agregString(yytext);}
\\			{
			BEGIN(INITIAL);
			cool_yylval.error_msg = "\\";
			return ERROR;
			}
{NEWLINE} 		{ ++curr_lineno; }
{INVISIABLE_CHAR} 	{;}			
"--".*\n		{curr_lineno++;}
"--".*			{curr_lineno++;}
"*)"			{
			cool_yylval.error_msg = "*) Solo, sin pareja";
			return ERROR;
			}
{WHITESPACE} {;}
. {
	BEGIN(INITIAL);
	cool_yylval.error_msg = yytext;
	return ERROR;
}


%%

void agregString(char* str) {
	if (tamString + 1 >= MAX_STR_CONST) {
		BEGIN(ERRORSTRINGLARGA);
	}
	else{
		strcat(string_buf, str);
		tamString++;
	}
}
void resetString(){
    tamString = 0;
    string_buf[0] = '\0';
}