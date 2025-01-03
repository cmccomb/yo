#!/usr/bin/env zsh
# shellcheck enable=all
# Since this script is sourced into another script, many of the variables aren't used. For that reason, we disable SC2034
# to hide the warnings.
# shellcheck disable=SC2034

########################################################################################################################
### CONSTANTS AND SETTINGS #############################################################################################
########################################################################################################################

# Common parameters
GENERAL_USERNAME="bartowski"
GENERAL_FINETUNING_STYLE="Instruct"
GENERAL_MODEL_FILETYPE="gguf"

# Estimating lengths
TOKEN_ESTIMATION_CORRECTION_FACTOR=1.2
CHARACTERS_PER_TOKEN=4

# Generation lengths
SEARCH_TERM_GENERATION_LENGTH=8
ONEOFF_GENERATION_LENGTH=128
INTERACTIVE_GENERATION_LENGTH=512
COMPRESSION_GENERATION_LENGTH=128
COMPRESSION_CHUNK_LENGTH=4096
COMPRESSION_TRIGGER_LENGTH=4096

# Context lengths
SEARCH_TERM_CONTEXT_LENGTH=-1 # custom fit to prompt and generation length
ONEOFF_CONTEXT_LENGTH=-1      # custom fit to prompt and generation length
INTERACTIVE_CONTEXT_LENGTH=$((8 * INTERACTIVE_GENERATION_LENGTH))

### Define parameters for the task model ###############################################################################

# Model parameters
TASK_MODEL_USERNAME=${GENERAL_USERNAME}
TASK_MODEL_SERIES="Llama-3.2"
TASK_MODEL_FINETUNING_STYLE=${GENERAL_FINETUNING_STYLE}
TASK_MODEL_SIZE="1B"
TASK_MODEL_QUANT="Q4_K_M"
TASK_MODEL_FILETYPE=${GENERAL_MODEL_FILETYPE}

# Generation parameters
TASK_MODEL_TEMP=0.1

### Define parameters for the casual model #############################################################################

# Model parameters
CASUAL_MODEL_USERNAME=${GENERAL_USERNAME}
CASUAL_MODEL_SERIES="Qwen2.5"
CASUAL_MODEL_FINETUNING_STYLE=${GENERAL_FINETUNING_STYLE}
CASUAL_MODEL_SIZE="3B"
CASUAL_MODEL_QUANT="Q4_K_M"
CASUAL_MODEL_FILETYPE=${GENERAL_MODEL_FILETYPE}

# Generation parameters
CASUAL_MODEL_TEMP=0.2

### Define parameters for the balanced model ###########################################################################
BALANCED_MODEL_USERNAME=${GENERAL_USERNAME}
BALANCED_MODEL_SERIES="Qwen2.5"
BALANCED_MODEL_FINETUNING_STYLE=${GENERAL_FINETUNING_STYLE}
BALANCED_MODEL_SIZE="7B"
BALANCED_MODEL_QUANT="Q4_K_M"
BALANCED_MODEL_FILETYPE=${GENERAL_MODEL_FILETYPE}

# Generation parameters
BALANCED_MODEL_TEMP=0.2

### Define the serious model parameters #################################################################################
SERIOUS_MODEL_USERNAME=${GENERAL_USERNAME}
SERIOUS_MODEL_SERIES="Qwen2.5-Coder"
SERIOUS_MODEL_FINETUNING_STYLE=${GENERAL_FINETUNING_STYLE}
SERIOUS_MODEL_SIZE="14B"
SERIOUS_MODEL_QUANT="IQ4_XS"
SERIOUS_MODEL_FILETYPE=${GENERAL_MODEL_FILETYPE}

# Generation parameters
SERIOUS_MODEL_TEMP=0.2

### Custom search API key ##############################################################################################
GOOGLE_CSE_API_KEY="AIzaSyBBXNq-DX1ENgFAiGCzTawQtWmRMSbDljk"
GOOGLE_CSE_ID="003333935467370160898:f2ntsnftsjy"
GOOGLE_CSE_BASE_URL="https://customsearch.googleapis.com/customsearch/v1"
readonly GOOGLE_CSE_API_KEY GOOGLE_CSE_ID GOOGLE_CSE_BASE_URL

### Maximum length of file content to extract ##########################################################################
MAX_FILE_CONTENT_LENGTH=300000
