citaDEVT="U:/"
stage ("win_%VERSION%") {
  node ("CITA&&Windows") {
    [%BITS%].each { BITS -> 
      [%EDITIONS%].each { EDITION ->
        // catchError(buildResult: "UNSTABLE", stageResult: "FAILURE") {
        try {
          echo "NODE_NAME = ${env.NODE_NAME}"            
          E = EDITION.take(1)
          EDITION = EDITION.capitalize()
          echo "EDITION=${EDITION}"
          path = "/Windows/explorer.exe"
          exists = fileExists(path)          
          if (exists) {
            echo "PLATFORM=win, path=${path}: File exists!"
          } else {
            echo "File $path does not exist"
          }
        echo "win-1"

          if (BITS==32) {
        echo "win-2"
            path = "/Program Files (x86)/Dyalog/Dyalog APL %VERSION% ${EDITION}"
          } else {
        echo "win-3"
            path = "/Program Files/Dyalog/Dyalog APL-64 %VERSION% ${EDITION}"
          }
        echo "win-4"
          path = "${path}/dyalog.exe"
        echo "win-5"
          exists = fileExists(path)          
        echo "win-6"
          if (exists) {
        echo "win-7"
            echo "PLATFORM=win, path=${path}: File exists!"
          } else {
        echo "win-8"
            echo "File ${path} does not exist"
            error "Found no interpreter for ${E}_${BITS} on ${env.NODE_NAME}. Labels: ${env.NODE_LABELS}"
          }



        echo "win-9"
          testPath="%xinD%win_%VERSION%_${E}${BITS}/"
        echo "win-10"
          cmdline = "%CMDLINE% citaDEVT=${citaDEVT} CONFIGFILE=${testPath}cita.dcfg CITA_Log=${testPath}CITA.log"
        echo "win-11"
            cmdline = "${cmdline} > ${testPath}ExecuteLocalTest.log"
        echo "win-12"
          echo "Launching ${path} ${cmdline} "
        echo "win-13"
          rjc = bat(script: "\"${path}\" ${cmdline}" , returnStatus: true)
        echo "win-13"
          exists = fileExists("${testPath}CITA.log.ok") 
        echo "win-14"
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
        echo "rc=${rc}"
        bat "exit ${rc}"
      }
    }
  }
}