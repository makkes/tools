# Manage GitHub watches

A tool to list and and unwatch GitHub repos.

## Installation

```
$ go get github.com/makkes/tools/watches
```

## Usage

All of the commands require the environment variable `GITHUB_TOKEN` to be set to
a [personal access token](https://github.com/settings/tokens) with appropriate
permissions.

### List watched repos

This command will print a list of all the repos you are watching to stdout:

```
$ watches l
```

To be able to unwatch some or all of those repos, redirect the output to a file:

```
$ watches l > watches.txt
```

### Unwatch repos

Open the file `watches.txt` that you created in the last step and replace each
`w` at the beginning of each line containing the name of the repo you want to
unwatch with a `u` and run this command:

```
$ cat watches.txt | watches d
```
