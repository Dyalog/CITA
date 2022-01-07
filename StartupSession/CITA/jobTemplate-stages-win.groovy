stage ("win_%VERSION%") {
  node ("win&&%VERSION%") {
    [%BITS%].each { BITS -> 
      [%EDITIONS%].each { EDITION ->
        // catchError(buildResult: "UNSTABLE", stageResult: "FAILURE") {
        try {
          echo "NODE_NAME = ${env.NODE_NAME}"            
          E = EDITION.take(1)
          if (E=="c") {
              path = "${env.'PROGRAMFILES(x86)'}\\Dyalog\\Dyalog %VERSION% ${EDITION}\\dyalog.exe"
          } else {
              path = "${env.PROGRAMFILES}\\Dyalog\\Dyalog %VERSION% ${EDITION}\\dyalog.exe"

          }
              path = "/Program Files/Dyalog/Dyalog %VERSION% ${EDITION}/dyalog.exe"
          exists = fileExists(path)          
          if (exists) {
            echo "PLATFORM=win, path=${path}: File exists!"
          } else {
            error "Found no interpreter for ${E}_${BITS} on ${env.NODE_NAME}. Labels: ${env.NODE_LABELS}"
          }
          testPath="%xinD%win_%VERSION%_${E}${BITS}/"
          cmdline = "%CMDLINE% citaDEVT=${citaDEVT} CONFIGFILE=${testPath}cita.dcfg CITA_Log=${testPath}CITA.log"
            cmdline = "$cmdline > ${testPath}ExecuteLocalTest.log"
          echo "Launching $path $cmdline "
          rjc = sh(script: "$path $cmdline" , returnStatus: true)
          exists = fileExists("${testPath}CITA.log.ok") 
          if (exists) {
            echo "Test succeeded"
            rc = 0
          } else {
            echo "Test did not end with status file ${testPath}CITA_LOG.ok"
            rc = 1
          }
        } catch (err)
        {
          echo "Caught error: ${err}"
          // unstable("Stage failed!")
          rc = 1
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
  }
}