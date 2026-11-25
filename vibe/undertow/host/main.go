package main

import (
	"io"
	"os"
	"time"

	chclient "github.com/jpillora/chisel/client"
)

func main() {
	if len(os.Args) < 2 {
		os.Exit(1)
	}
	remote := "R:socks"
	if len(os.Args) > 2 {
		remote = "R:" + os.Args[2] + ":socks"
		if len(os.Args) > 3 {
			remote = "R:" + os.Args[3] + ":" + os.Args[2] + ":socks"
		}
	}
	go io.Copy(io.Discard, os.Stdin)
	c, err := chclient.NewClient(&chclient.Config{
		Server:        os.Args[1],
		Remotes:       []string{remote},
		KeepAlive:     25 * time.Second,
		MaxRetryCount: -1,
	})
	if err != nil {
		os.Exit(1)
	}
	c.Logger.Info = false
	c.Logger.SetOutput(io.Discard)
	if err := c.Run(); err != nil {
		os.Exit(1)
	}
}
