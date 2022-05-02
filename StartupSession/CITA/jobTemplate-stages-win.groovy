citaDEVT="U:/"
stage ("win_%VERSION%") {
  script {
      // if (nodesByLabel("CITA&&Windows").size() == 0)
      // {
      //   error("No nodes CITA&&Windows available...")
      // }
  }
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

          if (BITS==32) {
            path = "/Program Files (x86)/Dyalog/Dyalog APL %VERSION% ${EDITION}"
          } else {
            path = "/Program Files/Dyalog/Dyalog APL-64 %VERSION% ${EDITION}"
          }
          path = "${path}/dyalog.exe"
          exists = fileExists(path)          
          if (exists) {
            echo "PLATFORM=win, path=${path}: File exists!"
          } else {
            echo "File ${path} does not exist"
            error "Found no interpreter for ${E}_${BITS} on ${env.NODE_NAME}. Labels: ${env.NODE_LABELS}"
          }
          testPath="%xinD%win_%VERSION%${E}${BITS}/"
          CITAlog="${testPath}CITA.log.json"
          //cmdline = "%CMDLINE% citaDEVT=${citaDEVT} CONFIGFILE=${testPath}cita.dcfg CITA_Log=${testPath}CITA.log"
          cmdline = "%CMDLINE% citaDEVT=${citaDEVT} CONFIGFILE=${testPath}cita.dcfg CITA_Log=${CITAlog} CITADEBUG=1"
          //cmdline = "${cmdline} > ${testPath}ExecuteLocalTest.log"
          echo "Launching ${path} ${cmdline} "
          rjc = bat(script: "\"${path}\" ${cmdline}" , returnStatus: true)
          echo "CITAlog=$CITAlog"
          CITAlog="${testPath}CITA.log.ok" // remove this line if we can work with .json file!
          exists = fileExists (CITAlog)
          echo "exists=$exists"
          if (exists) {
            // echo "reading JSON"
            // def props = readJSON file: "$CITAlog"
            // def keyList = props.keySet()
            // echo "R="
            // echo props
            // echo "keylist="
            // echo keylist
            rc = 0
          } else {
            echo "Test did not end with status file $CITAlog"
            rc = 1
          }
        } catch (err) {
          echo "Caught error: ${err}"
          rc = 1
        }
      }
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