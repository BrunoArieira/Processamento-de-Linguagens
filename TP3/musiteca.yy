%{

#include <stdio.h>
#include <string.h>
#include <glib.h>

int asprintf(char** strp, const char *fmt, ...);
int yylex();
void yyerror(char* c);
FILE * out;

typedef struct Song {
	char* title;
	char* lyrics;
	char* music;
	char* singer;
	char* from;
	char* in;
	char* letra;
	GArray* types;
} * song;

GArray* types_search;
GArray* list_songs; 
char* curr_title;
char* curr_lyrics;
char* curr_music;
char* curr_singer;
char* curr_from;
char* curr_in;
char* curr_letra;
char* curr_type;
GArray* curr_types;

void initSong(song new_song) {
	new_song = malloc(sizeof(struct Song));
	new_song->title = NULL;
	new_song->lyrics = NULL;
	new_song->music = NULL;
	new_song->singer = NULL;
	new_song->from = NULL;
	new_song->in = NULL;
	new_song->letra = NULL;
	new_song->types = g_array_new(FALSE, FALSE, sizeof(char *));
}

void updateSong(song song) {
	song->title = curr_title;
	curr_title = NULL;
	song->lyrics = curr_lyrics;
	curr_lyrics = NULL;
	song->music = curr_music;
	curr_music = NULL;
	song->singer = curr_singer;
	curr_singer = NULL;
	song->from = curr_from;
	curr_from = NULL;
	song->in = curr_in;
	curr_in = NULL;
	song->letra = curr_letra;
	curr_letra = NULL;
	song->types = curr_types;
	curr_types = g_array_new(FALSE, FALSE, sizeof(char*));
}

void topntail(char *str) {
    size_t len = strlen(str);
    memmove(str, str+1, len-2);
    str[len-2] = 0;
}

void printGraph() {

 	int hasNoTypes = 1;
	song temp_song;
	char* temp_type;
	
	fprintf(out, "digraph Song {\n");
	fprintf(out, "	ranksep = 4.0\n\n");

	for (int i = 0; i < list_songs->len; i++) {
		temp_song = g_array_index(list_songs, song, i);

		for (int j = 0; hasNoTypes && j < types_search->len; j++) {
			temp_type = g_array_index(types_search, char*, j);
			
			for (int k = 0; hasNoTypes && k < (temp_song->types)->len; k++)
				hasNoTypes = strcmp((g_array_index(temp_song->types, char*, k)), temp_type);
		}

		if (!hasNoTypes)
			fprintf(out, "	\"Musiteca\" -> \"%s\" [arrowhead = none]\n", temp_song->title);
		
		hasNoTypes = 1;
	}

	fprintf(out, "}");
}

%}

%union {char* s;}
%token SONG TITLE TEXT LYRICS MUSIC SINGER FROM IN TYPE LETRA WORD
%type <s> TEXT WORD

%%

init	: prog 			{  }

prog	: 			{  }
     	| song prog		{  }
;

song 	: SONG '{' cont '}'	{  
				  song curr_song = malloc(sizeof(struct Song));
				  updateSong(curr_song);
				  g_array_append_val(list_songs, curr_song);
      				}
;

cont 	: elem 			{  } 
        | elem cont		{  }
;

elem 	: TITLE ':' TEXT	{ topntail($3); curr_title = strdup($3); }
	| LYRICS ':' TEXT 	{ topntail($3); curr_lyrics = strdup($3); }
	| MUSIC ':' TEXT 	{ topntail($3); curr_music = strdup($3); }
	| SINGER ':' TEXT 	{ topntail($3); curr_singer = strdup($3); }
	| FROM ':' TEXT		{ topntail($3); curr_from = strdup($3); }
	| IN ':' TEXT 		{ topntail($3); curr_in = strdup($3); }
	| LETRA ':' TEXT 	{ topntail($3); curr_letra = strdup($3); }
	| TYPE ':' list  	{  }
;

list 	: WORD ',' list		{ curr_type = strdup($1); 
      				  g_array_append_val(curr_types, curr_type); 
				}
      	| WORD			{ curr_type = strdup($1);
				  g_array_append_val(curr_types, curr_type); 
				}
;

%%

#include "lex.yy.c"

int main(int argc, char** argv) {
	
	++argv, --argc;  /* skip over program name */
        if ( argc > 0 )
                yyin = fopen( argv[0], "r" );
	else
                yyin = stdin;

	if ( argc > 1 ) {
		types_search = g_array_new(FALSE, FALSE, sizeof(char*));
		for (int i = 1; i < argc; i++)
			g_array_append_val(types_search, argv[i]);
	}

     	list_songs = g_array_new(FALSE, FALSE, sizeof(song)); 
	curr_types = g_array_new(FALSE, FALSE, sizeof(char*));

	yyparse();

	out = fopen( "graph.dot", "w" );
	printGraph();

	return 0;
}

void yyerror(char* s) {
	fprintf(stderr, "%s, '%s', line %d\n", s, yytext, yylineno);
}
