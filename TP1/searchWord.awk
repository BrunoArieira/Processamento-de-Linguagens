BEGIN			{ RS = "<ext " ; expression = "\n"var }
$0 ~ expression		{ print $1 }
END			{ } 
