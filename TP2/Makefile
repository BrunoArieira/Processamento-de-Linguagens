all: procbibtex

lex.yy.c: procbibtex.lex
	flex procbibtex.lex

procbibtex: lex.yy.c
	gcc -o bibtexpro -I/usr/local/Cellar/glib/2.56.1/include/glib-2.0 -I/usr/local/Cellar/glib/2.56.1/lib/glib-2.0/include -I/usr/local/opt/gettext/include -I/usr/local/Cellar/pcre/8.42/include lex.yy.c -L/usr/local/Cellar/glib/2.56.1/lib -L/usr/local/opt/gettext/lib -lglib-2.0 -lintl -Wl,-framework -Wl,CoreFoundation 

twopi:
	twopi -ograph.png -Tpng -Gcharset=latin1 graph.dot 

graph: twopi
	open -a Preview graph.png

clean:
	$(RM) lex.yy.c bibtexpro *.html graph.*
