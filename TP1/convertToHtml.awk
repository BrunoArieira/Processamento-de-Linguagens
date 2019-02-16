#! /usr/local/bin/gawk -f

BEGIN						{ FS = "\t" ; quotes = 0 ; nospace = 0 ;
						  print "<html>" ;
						  print "<head>" ;
						  print "<meta charset=\"utf-8\">" ;
						  print "<title>"FILENAME"</title>" ;
						  print "</head>" ;
						  print "<body>"
						}

/^(<\/t)/					{ printf("</h3>\n") }
/^(<\/p)/					{ printf("</p>\n") }
/^(<\/li>)/					{ printf("</li></ul>\n") }
/^(<\/a>)/					{ printf("</address>\n") }

/^[^[:punct:]]/					{ if ( nospace ) { nospace = 0 ; printf("%s", $1) } 
						  else printf(" %s", $1)
						}

/^\"/						{ if ( quotes ) printf("%s", $1) 
						  else { quotes = 1 ; nospace = 1 ; printf(" %s", $1) }
						}

/^[\!|\%|\'|\)|\,|\.|\:|\;|\?|\»]/		{ printf("%s", $1) }
/^[\(|\`|\«]/					{ nospace = 1 ; printf(" %s", $1) }
/^[\&|\+|\-|\=]/				{ printf(" %s", $1) }
/^\//						{ printf("%s", $1) ; nospace = 1 }

/^<t/						{ printf("\n<h3>") }			
/^<p/						{ printf("\n<p>") }
/^(<li>)/					{ printf("\n<ul><li>") }
/^(<a>)/					{ printf("\n<address>") }

END						{ print "</body>" ;
						  print "</html>"
						}
