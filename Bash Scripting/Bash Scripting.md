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
			`echo -e "\nWelcome to Age Calculator, your current age is..." $entered_age`
	- Script 4
			`while read line`
			`do`
			 `echo $line`
			`done < output.txt`
	- Command Line Arguments
			`#!/bin/bash`
			`echo "Yo, $7!"`
	- Writing a file
			`echo "Send to File..." > file.txt`
	- Appending to a file
			`echo "Some more to send to File..." >> file.txt
	- Redirecting outputs to a file
			`pwd > pwd_save.txt`
			`pwd >> pwd_appended_save.txt`
	- List of basic bash commands to save here:
		- 1. `cd`: Change the directory to a different location.
		- `ls`: List the contents of the current directory.
		- `mkdir`: Create a new directory
		- `touch`: Create a new file.
		- `rm`: Remove a file or directory.
		- `cp`: Copy a file or directory.
		- `mv`: Move or rename a file or directory.
		- `echo`: Print text to the terminal.
		- `cat`: Concatenate and print the contents of a file.
		- `grep`: Search for a pattern in a file.
		- `chmod`: Change the permissions of a file or directory.
		- `sudo`: Run a command with administrative privileges.
		- `df`: Display the amount of disk space available.
		- `history`: Show a list of previously executed commands.
		- `ps`: Display information about running processes.
	- Template Conditional Bash statements for scripting
			- ```bash
				if [[ condition ]];
				then
				    statement
				elif [[ condition ]]; then
				    statement 
				else
				    do this by default
				fi
	- Script 5 - Script that takes User input and understands if a number is positive or negative
			```bash
				#!/bin/bash
				echo "Please enter a number, can be positive or negative: "
				read num
				if [ $num -gt 0 ]; then
				  echo "$num is positive"
				elif [ $num -lt 0 ]; then
				  echo "$num is negative"
				else
				  echo "$num is zero"
				fi
	- While loop in bash
	- For loop in bash
	- Case statements & loops in bash
	- Scheduling Scripts using Cron
	- Using the Crontab
	- Use the Set option
	- Check the Exit Code
	- 