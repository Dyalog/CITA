# CITA - Continuous Integration Tool for APL

Currently this is used internally @ dyalog, but open for anyone to
pick up and use. Local testing (as opposed to "remote testing with Jenkins")
is currently beta-tested internally, the remote functionality is still under
discussion & development.

Documentation is a work in progress and will eventually be hosted  in the [Wiki](https://github.com/Dyalog/CITA/wiki). Please feel free to ask for any details that are not obvious.

## Installation
* Requires v18.0 or later
* Clone the CITA repository (we'll assume it's in /git/CITA/)
* Add the path `/git/CITA/SALT/spice` to the User Commands `cmddir` setting 
* Rebuild your user command cache using `]UReset`
* If you want to use ]DTest, you need [DBuildTest](https://github.com/Dyalog/DBuildTest) v1.46 or later
* 
## Testing locally with `]DTest`
* Identify the installed Dyalog versions using `]CITA.APLVersions -update`.  This creates the file `interpreters.json5`.
* For any versions for which you want to enable testing, in `interpreters.json5`, add an empty "disabled" element. (`"disabled" : ""`) 
* In the repository you want to test, create a file named `CITA.json5` that looks something like:
```
/* MyRepository CITA */
{
    Tests: [{
        "DyalogVersions": "18+",
        "Test": "./tests/unit.dyalogtest",
    }, ]
}
```
* "Tests" is an array of 0 or more testing specifications where:
  * "DyalogVersions" are the versions you want your repository tested with. Make sure to enable them as described above.
  * "Test" is the name of the test file to execute. It is recommended to use DTests (and .dyalogtest files), but you may as well use .dyalog or .aplf to define a function. However, that function has to communicate with CITA to pass the result of the tests. To do so, it should `⎕SE.UCMD'GetTool4CITA'` and, when done, call `⎕SE._cita.Success'optional msg'` or `⎕SE._cita.Failure'msg'` (it can also log errors using `⎕SE._cita.Error'msg'`.
  
* Use `]CITA.ExecuteLocalTest` to execute the test(s).
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

