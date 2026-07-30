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
	- To open script editing interface ***vi <"script-name">.sh***
	- Script 1
			`#!/bin/bash # the shebang sets the shell, for this script it is bash`
			`echo "Today is " `date` # the Echo command, displays a specific ASCII`
			`echo -e "\nenter the path to directory" #`
			`read the_path # `
			`echo -e "\n you path has the following files and folders: " #`
			`ls $the_path # `
	- Script 2
			`#!/bin/bash`
			`alias testing="echo "Hello World, My Name is Sam""`
			`testing`
			`redo="Great Sucess"`
			`echo $redo`
	- To be able to have the Read, Write and Execute permissions by User, Group, etc.
		- you must run the following command 
				`chmod +x <"script-name">.sh`
		- This gives you the correct permissions to your current user to Execute that script file.
	- Variables are stored on your shell typically on the ***.bashrc*** file on linux and are prefaced with the ***'$'*** character before the name of the variable to be able to execute it and call for it for example with the '***echo***' command.
	- Script 3
			`#!/bin/bash`
			`echo "How old are you?"`
			`read entered_age`