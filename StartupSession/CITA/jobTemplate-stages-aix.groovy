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
            E = EDITION.take(1)
            testPath="%xinD%aix_%VERSION%${P}${E}${BITS}/"
            //cmdline = "%CMDLINE% citaDEVT=${citaDEVT} USERCONFIGFILE=${testPath}cita.dcfg CITA_Log=${testPath}CITA.log"
            cmdline = "%CMDLINE% citaDEVT=${citaDEVT} USERCONFIGFILE=${testPath}cita.dcfg CITA_Log=${testPath}CITA.log CITADEBUG=1"
            cmdline = "$cmdline > ${testPath}ExecuteLocalTest.log"

            echo "Launching $cmdlinePre $exePath $cmdline "
            // sh "$exePath $cmdline" 
            rc =  sh(script: "$cmdlinePre $exePath $cmdline" , returnStatus: true)
            echo "returncode=$rc"      
            exists = fileExists("${testPath}CITA.log.ok")     
            if (exists) {
              echo "Test succeeded"
              rc = (rc < 1)?0:1
            } else {
              echo "Testing %VERSION%${E}${BITS}-${P} did not end with status file ${testPath}CITA.log.ok"
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
      rc=0
    }
    echo "rc=$rc"
    sh "exit $rc"
  }
}