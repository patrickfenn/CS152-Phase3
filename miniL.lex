/* cs152-miniL phase1 */

%{ 

#pragma once
#include <stdio.h>
#include "miniL-parser.hpp"
#include "lib.h"


int currLine = 1;
int currCol = 1;
void increaseCol();
void increaseLine();
extern void yyerror(const char *s);

%}

COMMENT			##.*
DIGIT           [0-9]
M_DIGIT         {DIGIT}+
LETTER          [a-zA-Z]
M_LETTER        {LETTER}+
U_SCORE         "_"
IDENT		    {M_LETTER}|{M_LETTER}({M_DIGIT}|{M_LETTER})*|{M_LETTER}({M_LETTER}|{M_DIGIT}|{U_SCORE})*
BAD_IDENT		{IDENT}{U_SCORE}|{M_DIGIT}{IDENT}



%%

"function"      {increaseCol(); return FUNCTION;}
"beginparams"   {increaseCol(); return BEGIN_PARAMS;}
"endparams"     {increaseCol(); return END_PARAMS;}
"beginlocals"   {increaseCol(); return BEGIN_LOCALS;}
"endlocals"     {increaseCol(); return END_LOCALS;}
"beginbody"     {increaseCol(); return BEGIN_BODY;}
"endbody"       {increaseCol(); return END_BODY;}
"integer"       {increaseCol(); return INTEGER;}
"array"         {increaseCol(); return ARRAY;}
"enum"          {increaseCol(); return ENUM;}
"of"            {increaseCol(); return OF;}
"if"            {increaseCol(); return IF;}
"then"          {increaseCol(); return THEN;}
"endif"         {increaseCol(); return ENDIF;}
"else"          {increaseCol(); return ELSE;}
"while"         {increaseCol(); return WHILE;}
"do"            {increaseCol(); return DO;}
"beginloop"     {increaseCol(); return BEGINLOOP;}
"endloop"      {increaseCol(); return ENDLOOP;}
"continue"      {increaseCol(); return CONTINUE;}
"read"          {increaseCol(); return READ;}
"write"         {increaseCol(); return WRITE;}
"and"           {increaseCol(); return AND;}
"or"            {increaseCol(); return OR;}
"not"           {increaseCol(); return NOT;}
"true"          {increaseCol(); return TRUE;}
"false"         {increaseCol(); return FALSE;}
"return"        {increaseCol(); return RETURN;}
"-"             {increaseCol(); return SUB;}
"+"             {increaseCol(); return ADD;}
"*"             {increaseCol(); return MULT;}
"/"             {increaseCol(); return DIV;}
"%"             {increaseCol(); return MOD;}
"=="            {increaseCol(); return EQ;}
"<>"            {increaseCol(); return NEQ;}
"<"             {increaseCol(); return LT;}
">"             {increaseCol(); return GT;}
"<="            {increaseCol(); return LTE;}
">="            {increaseCol(); return GTE;}
";"             {increaseCol(); return SEMICOLON;}
":"             {increaseCol(); return COLON;}
","             {increaseCol(); return COMMA;}
"("             {increaseCol(); return L_PAREN;}
")"             {increaseCol(); return R_PAREN;}
"["             {increaseCol(); return L_SQUARE_BRACKET;}
"]"             {increaseCol(); return R_SQUARE_BRACKET;}
":="            {increaseCol(); return ASSIGN;}
" "+             {increaseCol();}
"\n"+            {increaseLine();}
"\t"+            {increaseCol();}
{COMMENT}		{increaseLine();}
{BAD_IDENT}		{increaseCol(); yyerror(("Bad Identifier: " + string(yytext)).c_str());}
{IDENT}			{increaseCol(); yylval.str_val = yytext; return IDENT;}
{M_DIGIT}		{increaseCol(); yylval.str_val = yytext; return NUMBER;}
.               {yyerror(("Error at line: " + to_string(currLine) + " , Col: " + to_string(currCol) + '\n').c_str()); }//error
%%


void increaseLine(){
	currCol = 1;
	currLine += 1;
}

void increaseCol(){
	currCol += yyleng;
}


