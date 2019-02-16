musiteca: musiteca.yy musiteca.lex
	flex musiteca.lex
	yacc musiteca.yy
	gcc -o musiteca -I/usr/local/Cellar/glib/2.56.1/include/glib-2.0 -I/usr/local/Cellar/glib/2.56.1/lib/glib-2.0/include -I/usr/local/opt/gettext/include -I/usr/local/Cellar/pcre/8.42/include y.tab.c -L/usr/local/Cellar/glib/2.56.1/lib -L/usr/local/opt/gettext/lib -lglib-2.0 -lintl -Wl,-framework -Wl,CoreFoundation

graph:
	twopi -ograph.png -Tpng -Gcharset=utf-8 graph.dot
	open -a Preview graph.png

clean:
	rm musiteca lex.yy.c y.tab.c graph.dot graph.png
