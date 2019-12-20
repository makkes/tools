package main

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
)

func client() (*github.Client, error) {
	token := os.Getenv("GITHUB_TOKEN")
	if token == "" {
		fmt.Fprintf(os.Stderr, "Please set the GITHUB_TOKEN environment variable\n")
		os.Exit(1)
	}
	ctx := context.Background()
	ts := oauth2.StaticTokenSource(&oauth2.Token{AccessToken: token})
	tc := oauth2.NewClient(ctx, ts)
	return github.NewClient(tc), nil
}

func help() string {
	return fmt.Sprintf(`Usage: %s l|d
`, os.Args[0])
}

func listWatchedRepos(c *github.Client) {
	page := 1
	for page != 0 {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		watched, resp, err := c.Activity.ListWatched(ctx, "", &github.ListOptions{
			Page:    page,
			PerPage: 100,
		})
		cancel()
		if err != nil {
			panic(err)
		}
		for _, repo := range watched {
			fmt.Printf("w %s\n", repo.GetFullName())
		}
		page = resp.NextPage
	}
}

func deleteWatchedRepos(c *github.Client) {
	stdin := bufio.NewScanner(os.Stdin)
	for stdin.Scan() {
		line := stdin.Text()
		parts := strings.Split(line, " ")
		if len(parts) != 2 {
			fmt.Fprintf(os.Stderr, "Unexpected line format: '%s'\n", line)
			continue
		}
		switch parts[0] {
		case "u":
			repo := strings.Split(parts[1], "/")
			if len(repo) != 2 {
				fmt.Fprintf(os.Stderr, "Unexpected repository format: '%s'\n", parts[1])
				continue
			}
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			_, err := c.Activity.DeleteRepositorySubscription(ctx, repo[0], repo[1])
			cancel()
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error unwatching %s: %v\n", parts[1], err)
				continue
			}
			fmt.Printf("unwatched %s\n", parts[1])
		case "w":
			// just skip this
		default:
			fmt.Fprintf(os.Stderr, "Unknown action: '%s'\n", parts[0])
		}
	}
}

func main() {
	client, err := client()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error initializing GitHub client: %s\n", err)
		os.Exit(1)
	}

	if len(os.Args) != 2 {
		fmt.Fprintf(os.Stderr, "%s", help())
		os.Exit(1)
	}

	switch os.Args[1] {
	case "l":
		listWatchedRepos(client)
	case "d":
		deleteWatchedRepos(client)
	default:
		fmt.Fprintf(os.Stderr, "%s", help())
		os.Exit(1)
	}
}
