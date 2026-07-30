This whole section will be done inside the Ubuntu VM
Ref "https://www.freecodecamp.org/news/bash-scripting-tutorial-linux-shell-script-and-command-line-for-beginners/"
- **Below are a list of basic command and how I used them**
		- date
		- pwd
		- ls
		- cat
		- echo
		- what is #!/bin/bash
		- what is .sh
		- bash
		- which
		- vi
- Making a basic bash script
	- Script 1
			```#!/bin/bash
			echo "Today is " `date`
			echo -e "\nenter the path to directory"
			read the_path 
			echo -e "\n you path has the following files and folders: "
			ls $the_path```
			