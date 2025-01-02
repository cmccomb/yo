# Yo 

[![Installation](https://github.com/cmccomb/yo/actions/workflows/installation.yml/badge.svg)](https://github.com/cmccomb/yo/actions/workflows/installation.yml)
[![Tests](https://github.com/cmccomb/yo/actions/workflows/run_tests.yml/badge.svg)](https://github.com/cmccomb/yo/actions/workflows/run_tests.yml)

Yo is a command-line assistant that interacts with the user and provides information about the system and recent commands.

> "Hello! I'm Yo, your friendly assistant here to help with any questions or tasks you might have. I'm designed to be efficient and accurate, providing concise responses to make your interactions as smooth as possible."
> 
> \- Yo ✌️

## Installation

To install `yo`, simply run this command:
```zsh
zsh <(curl -s https://cmccomb.com/yo/install)
```

And when its time to say goodbye and uninstall, here's what you need:
```shell
$ yo uninstall
```

## Usage
Get a quick answer
```shell,no_run
$ yo what is the capital of france
 Paris ✌️
```

Start an interactive session:
```shell,no_run
$ yo

> what is the capital of france
The capital of France is Paris.
```

Integrate information from a file or URL:
```shell,no_run
$ yo --file README.md how can I improve this source readme
 Review the README.md file for consistency and clarity, and consider adding examples and usage instructions. ✌️
```

```shell,no_run
$ yo --website https://en.wikipedia.org/wiki/Paris how big is paris
 Paris has an area of approximately 105 square kilometers. ✌️
```

Integrate Google search results:
```shell,no_run
$ yo --surf what is the capital of trinidad and tobago
 Port of Spain ✌️
```

```shell,no_run
$ yo --search "trinidad and tobago major cities" what is the capital of trinidad and tobago
 Port of Spain ✌️
```