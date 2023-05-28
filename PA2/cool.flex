/*
 *  The scanner definition for COOL.
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


bool buffer_overflow();
int buffer_length();
int throw_overflow_error();

static int nested_count = 0;
%}


%x STRING
%x COMMENT
%x DASHCOMMENT
%x STRING_ERROR

LETTER      [a-zA-Z_]
DIGIT       [0-9]
WHITE_SPACE [ \f\r\t\v]*
NEWLINE     \r\n|\n

A [Aa]
B [Bb]
C [Cc]
D [Dd]
E [Ee]
F [Ff]
G [Gg]
H [Hh]
I [Ii]
J [Jj]
K [Kk]
L [Ll]
M [Mm]
N [Nn]
O [Oo]
P [Pp]
Q [Qq]
R [Rr]
S [Ss]
T [Tt]
U [Uu]
V [Vv]
W [Ww]
X [Xx]
Y [Yy]
Z [Zz]

CLASS       {C}{L}{A}{S}{S}
ELSE        {E}{L}{S}{E}
FI          {F}{I}
IF          {I}{F}
IN          {I}{N}
INHERITS    {I}{N}{H}{E}{R}{I}{T}{S}
ISVOID      {I}{S}{V}{O}{I}{D}
LET         {L}{E}{T}
LOOP        {L}{O}{O}{P}
POOL        {P}{O}{O}{L}
THEN        {T}{H}{E}{N}
WHILE       {W}{H}{I}{L}{E}
CASE        {C}{A}{S}{E}
ESAC        {E}{S}{A}{C}
NEW         {N}{E}{W}
OF          {O}{F}
NOT         {N}{O}{T}
TRUE        t{R}{U}{E}
FALSE       f{A}{L}{S}{E}

INT_CONST   {DIGIT}+
TYPEID      [A-Z]({LETTER}|{DIGIT})*
OBJECTID    [a-z]({LETTER}|{DIGIT})*

%%

"(*"                    { BEGIN(COMMENT); nested_count++; }
"*)"                    {
    BEGIN(INITIAL);
    cool_yylval.error_msg = "Unmatched *)";
    return ERROR;
}
<COMMENT>"*)"           { 
    if (--nested_count == 0) 
        BEGIN(INITIAL); 
}
<COMMENT>"(*"           {
    nested_count++;
}
<COMMENT>"\\*)"         {}
<COMMENT>"\\(*"         {}
<COMMENT>\n             { curr_lineno++; }
<COMMENT><<EOF>>        {   
    BEGIN(INITIAL);
    cool_yylval.error_msg = "EOF in comment";
    return ERROR;
}
<COMMENT>.              {}

"--"                  { BEGIN(DASHCOMMENT); }
<DASHCOMMENT><<EOF>>  { BEGIN(INITIAL); }
<DASHCOMMENT>\n       { BEGIN(INITIAL); curr_lineno++; }
<DASHCOMMENT>.        {}


\"                { 
    BEGIN(STRING);
    string_buf_ptr = string_buf;
}
<STRING>\"        { 
    BEGIN(INITIAL); 
    if (buffer_overflow()) {
        cool_yylval.error_msg = "String constant too long";
        return ERROR;
    }
    *string_buf_ptr = 0;
    cool_yylval.symbol = stringtable.add_string(string_buf);
    return STR_CONST;    
}
<STRING><<EOF>>   {
    BEGIN(INITIAL);
    cool_yylval.error_msg = "EOF in string constant";
    return ERROR;
}
<STRING>\n        {
    BEGIN(INITIAL);
    curr_lineno++;
    cool_yylval.error_msg = "Unterminated string constant";
    return ERROR;
}
<STRING>\\\0           {
    BEGIN(STRING_ERROR);
    cool_yylval.error_msg = "String contains escaped null character";
}
<STRING>\0           {
    BEGIN(STRING_ERROR);
    cool_yylval.error_msg = "String escaped null character";
}
<STRING>\\[n]       {
    if (buffer_overflow())
        throw_overflow_error();
    else
        *string_buf_ptr++ = '\n';
}      
<STRING>\\[b]       {
    if (buffer_overflow())
        throw_overflow_error();
    else
        *string_buf_ptr++ = '\b';
}
<STRING>\\[t]       {
    if (buffer_overflow())
        throw_overflow_error();
    else
        *string_buf_ptr++ = '\t';
}
<STRING>\\[f]       {
    if (buffer_overflow())
        throw_overflow_error();
    else
        *string_buf_ptr++ = '\f';
}

<STRING>\\[\n]      {
    curr_lineno++;
    if (buffer_overflow())
        throw_overflow_error();
    else
        *string_buf_ptr++ = '\n';
}

<STRING>\\[^nbtf] {
    if (buffer_overflow())
        throw_overflow_error();
    else
        *string_buf_ptr++ = yytext[1];
}


<STRING>.         {
    if (buffer_overflow()) 
        throw_overflow_error();
    else
        *string_buf_ptr++ = yytext[0];
}

<STRING_ERROR>\"        {
    BEGIN(INITIAL);
    return ERROR;
}

<STRING_ERROR>\n        { 
    BEGIN(INITIAL);
    curr_lineno++; 
    return ERROR;
}

<STRING_ERROR><<EOF>>   {
    BEGIN(INITIAL);
    return ERROR;
}

<STRING_ERROR>.         {}


{INT_CONST}             {
    cool_yylval.symbol = inttable.add_string(yytext);
    return INT_CONST;
}

":"               { return ':'; }
";"               { return ';'; }
"{"               { return '{'; }
"}"               { return '}'; }
"("               { return '('; }
")"               { return ')'; }
"+"               { return '+'; }
"-"               { return '-'; }
"/"               { return '/'; }
"*"               { return '*'; }
"~"               { return '~'; }
"."               { return '.'; }
","               { return ','; }
"@"               { return '@'; }
"<"               { return '<'; }
"="               { return '='; }
"'"               { return '\''; }

{NEWLINE}         { curr_lineno++; }
{WHITE_SPACE}     {}  

{FALSE}             {
    cool_yylval.boolean = false;
    return (BOOL_CONST);
}
{TRUE}              {
    cool_yylval.boolean = true;
    return (BOOL_CONST);
}

"=>"              { return (DARROW); }
"<="              { return (LE); }
"<-"              { return (ASSIGN); }

{CLASS}           { return (CLASS); }
{ELSE}            { return (ELSE); }
{FI}              { return (FI); }
{IF}              { return (IF); }
{IN}              { return (IN); }
{INHERITS}        { return (INHERITS); }
{ISVOID}          { return (ISVOID); }
{LET}             { return (LET); }
{LOOP}            { return (LOOP); }
{POOL}            { return (POOL); }
{THEN}            { return (THEN); }
{WHILE}           { return (WHILE); }
{CASE}            { return (CASE); }
{ESAC}            { return (ESAC); }
{NEW}             { return (NEW); }
{OF}              { return (OF); }
{NOT}             { return (NOT); }

{TYPEID}          {   
    cool_yylval.symbol = idtable.add_string(yytext);
    return (TYPEID);
}

{OBJECTID}        {
    cool_yylval.symbol = idtable.add_string(yytext);
    return (OBJECTID);
}

.                 {
    cool_yylval.error_msg = strdup(yytext);
    return ERROR;
}


%%
int buffer_length() {
    return (int)(string_buf_ptr - string_buf);
}

bool buffer_overflow() {
    return buffer_length() >= MAX_STR_CONST;
}

int throw_overflow_error() {
    BEGIN(STRING_ERROR);
    cool_yylval.error_msg = "String constant too long";
}

