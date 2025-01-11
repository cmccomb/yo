#!/usr/bin/env sh
# shellcheck enable=all

########################################################################################################################
### THE YO #############################################################################################################
########################################################################################################################

### Define the Yo ######################################################################################################
readonly YO="✌️"

### All versioning follows semver as defined at https://semver.org/ ####################################################
readonly VERSION="0.1.1"

### Display version information ########################################################################################
show_version() {
	echo "yo v${VERSION}"
}

### Display help instructions ##########################################################################################
show_help() {
	cat <<-EOF
		yo - A command-line AI assistant where you control the context ${YO}

		Usage:
		  yo [flags] [question]
		  yo <subcommand> [options]

		Description:
		  If a question is provided, Yo will answer the question. Otherwise, Yo will enter an interactive session.

		Context Flags:
		  These options allow you to control the information that Yo uses to answer your question.

		  First, we have static local flags that introduce specific predefined knowledge:
		    -u, --usage             Load this help message into Yo's context.

		  Next, we have dynamic local flags that pull in fresh information from the local system:
		    -c, --clipboard         Copy the contents of the clipboard into Yo's context.
		    -d, --directory         Include a list of the files in the current directory in Yo's context.
		    -f, --file "PATH"       Extract the specified file into Yo's context. Supports a variety of file formats,
		                            including .pdf, .docx, images (.png, .jpeg, .tiff, etc.), and any text file (.txt, .md,
		                            .py, .zsh, etc.). This flag can be repeated to bring in several files.
		    -y, --system            Run a few system commands and integrate the information into Yo's context.

		  Finally, we have several flags that require an internet connection:
		    -s, --search "TERMS"    Perform a web search using the specified quoted terms and integrate the results into
		                            Yo's context. This flag can be repeated to perform several searches.
		    -S, --surf              Perform a web search using LLM-chosen terms based on the question and integrate the
		                            results into Yo's context.
		    -w, --website "URL"     Extract the specified website into Yo's context. This flag can be repeated to bring in
		                            multiple sites.

		Model Size Flags:
		  Yo uses four distinct models. In order of increasing size, they are: a task model (1B), a casual model (3B), a
		  balanced model (7B), and a serious model (14B). By default, Yo uses the task model for summarization and other
		  small tasks, the casual model for one-off questions, and the serious model for interactive sessions. You can
		  override the default model by using the following flags:
		    -tm, --task-model       Use the task model
		    -cm, --casual-model     Use the casual model
		    -bm, --balanced-model   Use the balanced model
		    -sm, --serious-model    Use the serious model

		General Purpose Flags:
		  These flags provide general functionality.
		    -h, --help              Show this help message and exit.
		    -q, --quiet             Suppress all output except the answer.
		    -v, --verbose           Enable verbose mode for detailed output.
		    -V, --version           Show the version and exit.

		Subcommands:
		  A portion of the yo syntax is reserved for subcommands that make Yo perform specific tasks. The following subcommands
		  are available:
		    yo download <model>          Download the Yo internal language models prior to use. Options are task, casual,
		                                 balanced, serious, or everything.
		        yo settings                  Display the current settings.
		        yo settings SETTING          Read a setting from the settings file. SETTING should use dot notation to reference
		                                     nested dictionaries in ~/.yo.yaml (e.g., model.task.temperature).
		        yo settings SETTING [VALUE]  Write a setting to the settings file.
		        yo settings reset            Restore factor default settings.
		    yo update                    Update Yo to the latest version.
		    yo uninstall                 Uninstall Yo from your system.

		Examples:
		  * Answer a question:
		    $ yo "What is the capital of France?"

		  * For simple cases, you can omit the quotes:
		    $ yo what is the capital of france

		  * Start an interactive session:
		    $ yo

		  * Integrate information from a file:
		    $ yo --file src "How can I improve this source code?"

		  * Integrate information from a URL:
		    $ yo --website "https://en.wikipedia.org/wiki/Paris" how big is paris

		  * Use LLM-selected search terms:
		    $ yo --surf tell me about renewable energy trends.
	EOF
	return 0
}
