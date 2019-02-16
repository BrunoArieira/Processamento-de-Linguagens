%option noyywrap
%x STR KEY CAT CONTENT AUT TIT

%{

#include <unistd.h>
#include <stdio.h>
#include <glib.h>
#include <glib/gprintf.h>

FILE* out;
gchar* author_search = NULL;

typedef struct Category {
	int count;
	FILE* out;
} * catInfo;

typedef struct Author {
	GArray* list_keys;
	int count_keys; 
} * autInfo;

void openHTML(FILE* file) {
	fprintf(file, "<!DOCTYPE html>\n<html>\n");
	fprintf(file, "<head>\n<meta charset=\"utf-8\">\n</head>\n");
	fprintf(file, "<body>\n");
}

void openGraph(FILE* file) {
	fprintf(file, "digraph Author {\n");
	fprintf(file, "   ranksep = 4.0\n\n");
}

void closeGraph(FILE* file) {
	fprintf(file, "}\n");
}

void closeHTML(FILE* file) {
	fprintf(file, "</body>\n</html>\n");
}

gboolean printGraph(gpointer author, gpointer count, gpointer data) {
	
	g_fprintf(out, "   \"%s\" -> \"%s\" [ label = \"%d\" , arrowhead = none ]\n", author_search, author, (int)count);
	g_free(author);
	return FALSE;
}

gboolean printCategories(gpointer category, gpointer category_info, gpointer data) {
	
	g_fprintf(out, "<a href=\"%s.html\">%s</a> = %d\n<br>\n", 
		g_ascii_strdown(category,-1), 
		g_ascii_strdown(category,-1), 
		(((catInfo)category_info)->count));

	return FALSE;
}

gboolean printAuthors(gpointer author, gpointer author_info, gpointer data) {

	GArray* list = ((autInfo)author_info)->list_keys;
	int count = ((autInfo)author_info)->count_keys;
	
	g_fprintf(out, "Autor: %s\n<br>\n", author);

	g_fprintf(out, "<ul>\n");
	for (int i = 0; i < count; i++)
	{
		g_fprintf(out, "<li>%s</li>\n", g_array_index(list, gchar*, i));
		g_free( g_array_index(list, gchar*, i) );
	}		
	g_fprintf(out, "</ul>\n");

	g_array_free(list, FALSE);
	free((autInfo)author_info);

	return FALSE;
}

gboolean closeFiles(gpointer category, gpointer category_info, gpointer data) {
	
	FILE* file = ((catInfo)category_info)->out;
	closeHTML(file);
	fclose(file);
	free(category_info);
	return FALSE;
}

void addCategory(char* category, int catleng, GTree *t) {

	gpointer* value = g_tree_lookup(t, category);
	
	if (!value) {
		
		catInfo category_info = malloc(sizeof(struct Category));
		char filename[100];

		sprintf(filename, "%s.html", g_ascii_strdown(category,-1));
		
		category_info->count = 1; 
		category_info->out = fopen(filename, "w");
		
		out = category_info->out;
		openHTML(out);
		
		g_tree_insert(t, g_strdup(category), category_info);
	}
	else {
		((catInfo)value)->count++;
		out = ((catInfo)value)->out;
	}
}

void addKeyToAuthor(gchar* author, gchar* key, GTree * t) {

	gchar * keyval = g_strdup(key);	
	gpointer* value = g_tree_lookup(t, author);

	if (!value) {
		
		autInfo author_info = malloc(sizeof(struct Author));

		author_info->list_keys = g_array_new(FALSE, FALSE, sizeof(gchar*));
		author_info->count_keys = 1;
	
		g_array_append_val(author_info->list_keys, keyval);

		g_tree_insert(t, g_strdup(author), author_info);
	}
	else {
		((autInfo)value)->count_keys++;
		g_array_append_val(((autInfo)value)->list_keys, keyval);
	}
}

void searchAuthor(GArray* list_aut, int size, GTree* t) {
	
	int found = 1, pos;

	for (pos = 0; pos < size && found != 0; pos++)
		found = g_ascii_strcasecmp(author_search, g_array_index(list_aut, gchar*, pos));

	pos--;

	if (found == 0) 
	{
		for (int i = 0; i < size; i++)
			if (i != pos) {
				gchar * aut = g_array_index(list_aut, gchar*, i);
				gpointer* value = g_tree_lookup(t, aut);
				
				if (!value)
					g_tree_insert(t, aut, (gpointer*)1);
				else
					g_tree_replace(t, aut, (int)value + 1);
			}
	}
	else
		for (int i = 0; i < size; i++)
			g_free( g_array_index(list_aut, gchar*, i) );
	
	g_array_free(list_aut, FALSE);
}

%}

space	[\ \t]+
alpha 	[a-zA-Z]
author 	(?i:author){space}?\={space}?(\"|\{)
title	[^a-zA-Z](?i:title){space}?\={space}?(\"|\{)
and 	[^a-zA-Z0-9]and[^a-zA-Z0-9]
	
%%

	GTree* cat_tree = g_tree_new((GCompareFunc)g_ascii_strcasecmp);
	GTree* aut_tree = g_tree_new((GCompareFunc)g_ascii_strcasecmp);
	GTree* list_aut_tree = g_tree_new((GCompareFunc)g_ascii_strcasecmp);
	int delim = 0, pos = 0, size_list_aut;
	gchar* curr_author = malloc(sizeof(gchar) * 500);
	gchar* curr_title = malloc(sizeof(gchar) * 500);
	gchar* curr_key; // = malloc(sizeof(gchar) * 50);
	GArray* list_aut;

\@string\{.*\n			{ }

"@"				BEGIN CAT;

<STR>{	
	"}"			BEGIN 0;
	.|\n			{ }
}		


<CAT>{
	[a-zA-Z0-9]+		{ addCategory(yytext, yyleng, cat_tree); } 
	"{"			BEGIN KEY;
	.|\n			{ }
}

<KEY>{
	[^\,]+	 		{ fprintf(out, "Chave: %s\n<br>\n", yytext);
				  curr_key = g_strdup(yytext);
				}
	"," 			{ delim = 0; BEGIN CONTENT; }
}

<CONTENT>{	
	{author}		{ fprintf(out, "Autores:\n<ul>\n");
				  list_aut = g_array_new(FALSE, FALSE, sizeof(gchar*));
				  size_list_aut = 0;
				  BEGIN AUT; 
				}
	{title}			BEGIN TIT;
	\{			delim++;
	\}			{ if (delim > 0)
					delim--;
				  else {
					fprintf(out, "<hr>\n"); 
				  	BEGIN 0;
				  } 
				}
	.|\n 			{ }
}

<AUT>{	
	{and}			{ curr_author[pos] = '\0'; 
				  curr_author = g_strstrip(curr_author);

				  addKeyToAuthor(curr_author, curr_key, aut_tree);
				  
				  if (author_search != NULL) {
				  	gchar* author = g_strdup(curr_author);
				  	g_array_append_val(list_aut, author);
				  	size_list_aut++;
				  }
				  
				  g_fprintf(out, "<li>%s</li>\n", curr_author); 
				  pos = 0; 
				}

	[\n\t\r ]+/[A-Za-z] 	{ curr_author[pos++] = ' '; }
	[\n\t\r ]+ 		{ }
        \\\"                    { curr_author[pos++] = yytext[0]; 
				  curr_author[pos++] = yytext[1]; 
				}
	"{"			{ delim++; 
				  curr_author[pos++] = yytext[0]; 
				}
	
	"}"			{ if (delim > 0) { 
					delim--; 
					curr_author[pos++] = yytext[0]; 
				  } 
				  else { 
					curr_author[pos] = '\0'; 
					curr_author = g_strstrip(curr_author);
					
					addKeyToAuthor(curr_author, curr_key, aut_tree);
				  	
				  	if (author_search != NULL) {
						gchar* author = g_strdup(curr_author);
						g_array_append_val(list_aut, author);
				  		size_list_aut++;				

						searchAuthor(list_aut, size_list_aut, list_aut_tree); 
					}					

					g_fprintf(out, "<li>%s</li>\n</ul>\n", curr_author); 
					pos = 0; 
					BEGIN CONTENT; 
				  } 
				}
	\"			{ if (delim > 0) 
					curr_author[pos++] = yytext[0]; 
				  else { 
					curr_author[pos] = '\0'; 
					curr_author = g_strstrip(curr_author);
		
					addKeyToAuthor(curr_author, curr_key, aut_tree);
	 
				  	if (author_search != NULL) {
				  		gchar* author = g_strdup(curr_author);
						g_array_append_val(list_aut, author);
				  		size_list_aut++;

						searchAuthor(list_aut, size_list_aut, list_aut_tree); 
					}				
	
					g_fprintf(out, "<li>%s</li>\n</ul>\n", curr_author); 
					pos = 0; 
					BEGIN CONTENT; 
				  } 
				}
	\(\~a\)			{ curr_author[pos++] = 'a'; }
	.			curr_author[pos++] = yytext[0];		
	
}

<TIT>{
	\n|\t			{ }
        \\\"                    { curr_title[pos++] = yytext[0]; 
				  curr_title[pos++] = yytext[1]; 
				}
	"{"			{ delim++; 
				  curr_title[pos++] = yytext[0]; 
				}
	"}"			{ if (delim > 0) { 
					delim--; 
					curr_title[pos++] = yytext[0]; 
				  } 
				  else { 
					curr_title[pos] = '\0'; 
					curr_title = g_strstrip(curr_title);
					g_fprintf(out, "Título: %s\n<br>\n", curr_title); 
					pos = 0;
					BEGIN CONTENT; 
				  } 
				}
	\"			{ if (delim > 0) 
					curr_title[pos++] = yytext[0]; 
				  else { 
					curr_title[pos] = '\0'; 
					curr_title = g_strstrip(curr_title); 
					g_fprintf(out, "Título: %s\n<br>\n", curr_title); 
					pos = 0; 
					BEGIN CONTENT; 
				  } 
				}
	.			curr_title[pos++] = yytext[0];		
	
}

<<EOF>> {			out = fopen("index.html", "w");
				openHTML(out);
				g_tree_foreach(cat_tree, (GTraverseFunc)printCategories, NULL);
				closeHTML(out);
				g_tree_foreach(cat_tree, (GTraverseFunc)closeFiles, NULL);
				fclose(out);
				
				out = fopen("authorindex.html", "w");
				openHTML(out);
				g_tree_foreach(aut_tree, (GTraverseFunc)printAuthors, NULL);
				closeHTML(out);
				fclose(out);

				if (author_search != NULL) {
					out = fopen("graph.dot", "w");
					openGraph(out);
					g_tree_foreach(list_aut_tree, (GTraverseFunc)printGraph, NULL);
					closeGraph(out);
				}				
				
				g_free(curr_key);
				g_free(curr_title);
				g_free(curr_author);		

				g_tree_destroy(list_aut_tree);
				g_tree_destroy(cat_tree);
				g_tree_destroy(aut_tree);

				fclose(out);
				yyterminate();
}

.|\n 				{ }
	
%%

int main(int argc, char** argv){

	++argv, --argc;  /* skip over program name */
        if ( argc > 0 ) {
                yyin = fopen( argv[0], "r" );
		if (argc > 1) {
			author_search = malloc( sizeof(gchar) );
			g_stpcpy( author_search, argv[1] );
		}
        }
	else
                yyin = stdin;


	yylex();
}
