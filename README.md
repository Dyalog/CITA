# CITA - Continuous Integration Tool for APL

Currently this is used internally @ dyalog, but open for anyone to
pick up and use. Local testing (as opposed to "remote testing with Jenkins")
is currently beta-tested internally, the remote functionality is still under
discussion & development.

Most documentation is on the developers harddrive atm ;)  Please feel free to
ask for any details that are not obvious.

## Installation

Requires v18. If you want to use ]DTest or the ]GetTools4CITA User commands,
you need [DBuildTest](https://github.com/Dyalog/DBuildTest) v1.46 onwards!

## Interaction with Jenkins

(Preliminary doc - pls. expect changes and be prepared to find bugs! If you have
problems, pls. email mbaas@dyalog.com - it's too early for Issues, I think)

To launch tests via Jenkins, use the UCMD `]TestRepo {name} -jenkins`  (we currently expect the name
of a Dyalog repository).

This all is also possible from the shell using cmdline `dyalog {RunCITA} RunUCMD="TestRepo {name} -jenkins"`.
Replace `{RunCITA}` with {path to this repository}/client/RunCITA.dws`.

### Configuration

For this command to work, CITA needs various pieces of data that can be passed either through EnvVars
or by using a .dcfg file. We need the following:

* `DYALOGCITAWORKDIR` - this is the folder in which CITA will run its tests. 
Should point to `u:\apltools\CITA\CITA-Tests\` or `/devt/apltools/CITA/CITA-Tests/' under unix or macos<sup>1</sup>.


## Footnotes

1. mac3 addresses this path a `/Volumes/devt/apltools...` - but since we don't know if we will be running on mac3 or not,
   the Jenkins-script will prefix `/Volumes` itself when needed (when node is recognized as "mac3"). Also, an environment variable `citaDEVT` is available which contains the correct way of addressing /devt/ on the current node.
