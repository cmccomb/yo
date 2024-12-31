#!/usr/bin/env zsh
# shellcheck enable=all

########################################################################################################################
### THE YO #############################################################################################################
########################################################################################################################

### Define the Yo ######################################################################################################
readonly YO="✌️"

### All versioning follows semver as defined at https://semver.org/ ####################################################
readonly VERSION="0.1.0"

### Display version information ########################################################################################
function show_version() {
	echo "yo v${VERSION}"
}

### Display help instructions ##########################################################################################
function show_help() {
	cat <<-EOF
		yo - A command-line AI assistant where you control the context ${YO}

		Usage:
		  yo [options] [question]

		Description:
		  If a question is provided, Yo will answer the question. Otherwise, Yo will enter an interactive session.

		Context Options:
		  These options allow you to control the information that Yo uses to answer your question.

		  First, we have static local options that introduce specific predefined knowledge:
		    -u, --usage             Load this help message into Yo's context.

		  Next, we have dynamic local options that pull in fress information from the local system:
		    -c, --clipboard         Copy the contents of the clipboard into Yo's context.
		    -d, --directory         Include a list of the files in the current directory in Yo's context.
		    -f, --file "PATH"       Extract the specified file into Yo's context. Supports a variety of file formats,
		                            including .pdf, .docx, .txt, .md, .py, .zsh. This flag can be repeated multiple times
		                            to bring in multiple files.
		    -y, --system            Run a few system commands and integrate the information into Yo's context.

		  Finally, we have several option that require an internet connection:
		    -s, --search "TERMS"    Perform a web search using the specified quoted terms and integrate the results into
		                            Yo's context. This flag can be repeated multiple times to perform unique searches.
		    -S, --surf              Perform a web search using LLM-chosen terms based on the question and integrate the
		                            results into Yo's context.
		    -w, --website "URL"     Extract the specified website into Yo's context. This flag can be repeated multiple
		                            times to bring in multiple sites.

		Model Size Options:
		  Yo uses four distinct models. In order of increasing size, they are: a task model (1B), a casual model (3B), a
		  balanced model (7B), and a serious model (14B). By default, Yo uses the task model for summarization and other
		  small tasks, the casual model for one-off questions, and the serious model for interactive sessions. You can
		  override the default model by using the following options:
		    -tm, --task-model       Use the task model
		    -cm, --casual-model     Use the casual model
		    -bm, --balanced-model   Use the balanced model
		    -sm, --serious-model    Use the serious model

		General Purpose Options:
		  These options provide general functionality.
		    -h, --help              Show this help message and exit.
		    -q, --quiet             Suppress all output except the answer.
		    -v, --verbose           Enable verbose mode for detailed output.
		    -V, --version           Show the version and exit.
		    -U, --update            Update Yo to the latest version.
		    -X, --uninstall         Uninstall Yo from your system.

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
