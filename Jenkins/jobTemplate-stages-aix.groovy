stage ("aix_%CITA_VERSION%_%VERSION%") {
  node ("aix&&%CITA_VERSION%&&%VERSION%") {
    [%BITS%].each { BITS ->
      [%EDITIONS%].each { EDITION ->
        [%EXTRAS%].each { P ->
          //catchError(buildResult: "UNSTABLE", stageResult: "FAILURE") {
          try {
            echo "NODE_NAME = ${env.NODE_NAME}"
            exePath = "/opt/mdyalog/%VERSION%/${BITS}/${EDITION}/${P}/mapl"
            exists = fileExists(exePath)
            if (!exists) {
              error "Found no interpreter for ${env.NODE_NAME}. Labels: ${env.NODE_LABELS}"
            }
            cmdlinePre = '%CMDLINEPRE%'
            if (cmdlinePre != "")
            {
              sh "$cmdlinePre"
            }
            if ("$EDITION" == "classic") {
              cmdlinePre = "APLT1=utf8 APLT2=utf8 APLK0=utf8 "
            }
            ed = EDITION.take(1)
            testPath = "%xinD%aix-${P}_%VERSION%${ed}${BITS}/"
            citaLOG="${testPath}CITA.log"
            cmdline = "%CMDLINE%  citaDEVT=${citaDEVT} CONFIGFILE=${testPath}cita.dcfg CITA_Log=${citaLOG}"
            cmdline = "$cmdline > ${testPath}ExecuteLocalTest.log"

            echo "Launching $cmdlinePre $exePath $cmdline "
            // sh "$exePath $cmdline"
            rc =  sh(script: "$cmdlinePre $exePath $cmdline" , returnStatus: true)
            echo "returncode=$rc"
            exists = fileExists("${citaLOG}.json")
            echo "%xinD%,testPath=${testPath}, citaLOG=${citaLOG}, exists=${exists}"
            rc = 0
            if (exists){
              props = readJSON file: "${citaLOG}.json"
              echo "R="
              props.each { key, value ->
                // echo "$key .rc=" . props["$key"]['rc'].toString()
                if (props["$key"]['rc'] != 0) {
                  rc = 1
                }
              }
            } else {
              echo "Test did not end with JSON log ${ci}/CITA.log.json"
              rc = 1
            }
          } catch (err)
          {
            echo "Caught error: ${err}"
            rc = 1
          }
          }
        }
      }
    if (rc != 0)
    {
      unstable("Stage failed!")
      rc = 0
    }
      echo "rc=$rc"
      sh "exit $rc"
    }
   }
