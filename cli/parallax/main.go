package main

import "github.com/ItsNotAILABS/PARRALAX-AIHFTFUND/cli/parallax/cmd"

var version = "dev"

func main() {
	cmd.SetVersion(version)
	cmd.Execute()
}
