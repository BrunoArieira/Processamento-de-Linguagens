%option noyywrap yylineno

%%
[\{\}\:\,]	return yytext[0];
@song		return SONG;
title		return TITLE;
lyrics		return LYRICS;
music		return MUSIC;
singer		return SINGER;
from		return FROM;
in		return IN;
type		return TYPE;
letra		return LETRA;
[a-zA-Z]+	{ yylval.s = strdup(yytext); return WORD; }
\{[^\{\}]*\}    { yylval.s = strdup(yytext); return TEXT; }
[ \t\n]+	;
.		{ yyerror("Invalid char\n"); }
%%
