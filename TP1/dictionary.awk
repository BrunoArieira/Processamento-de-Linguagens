BEGIN		{ FS = "\t" }
/^[a-zA-Z]+/	{ 	word = tolower($1) ;
			if (array[word] == 0) {
				array[word]++;
				print $1"\t\t"$4"\t\t"$5;
			}
		}
END		{ }
