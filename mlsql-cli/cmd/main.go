package main

import (
	"github.com/urfave/cli/v2"
	"log"
	"mlsql.tech/allwefantasy/mlsql-lang-cli/pkg/utils"
	"mlsql.tech/allwefantasy/mlsql-lang-cli/pkg/version"
	"os"
)

var logger = utils.GetLogger("mlsql")

func globalFlags() []cli.Flag {
	return []cli.Flag{
		&cli.BoolFlag{
			Name:    "verbose",
			Aliases: []string{"debug", "v"},
			Usage:   "enable debug log",
		},
		&cli.BoolFlag{
			Name:    "quiet",
			Aliases: []string{"q"},
			Usage:   "only warning and errors",
		},
		&cli.BoolFlag{
			Name:  "trace",
			Usage: "enable trace log",
		},
	}
}

func main() {
	cli.VersionFlag = &cli.BoolFlag{
		Name: "version", Aliases: []string{"V"},
		Usage: "print only the version",
	}

	app := cli.App{
		Name:                 "mlsql lang cli",
		Usage:                "Cli to run mlsql script",
		Version:              version.Version(),
		Copyright:            "Apache License V2",
		EnableBashCompletion: true,
		Flags:                globalFlags(),
		Commands: []*cli.Command{
			runFlags(),
		},
	}

	err := app.Run(os.Args)
	if err != nil {
		log.Fatal(err)
	}

}
