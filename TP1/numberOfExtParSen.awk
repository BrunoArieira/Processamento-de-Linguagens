BEGIN		{ contaEXT = 0; contaPAR = 0; contaFRA = 0; }
/^<ext/		{ contaEXT++ }
/^<p/		{ contaPAR++ }
/^<s/		{ contaFRA++ }
END		{ 
		  print "Extratos = " contaEXT; 
		  print "Paragrafos = " contaPAR;
		  print "Frases = " contaFRA;
		}		
