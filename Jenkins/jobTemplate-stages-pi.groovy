stage ("pi_%CITA_VERSION%_%VERSION%") {
  node ("pi&&%CITA_VERSION%&&%VERSION%") {
    [%BITS%].each { BITS -> 
      [%EDITIONS%].each { EDITION ->
        // catchError(buildResult: "UNSTABLE", stageResult: "FAILURE") {
        try {
          echo "NODE_NAME = ${env.NODE_NAME}"            
          exePath = "/opt/mdyalog/%VERSION%/${BITS}/${EDITION}/mapl"
          ed = EDITION.take(1)
          exists = fileExists(exePath)          
          if (exists) {
            echo "PLATFORM=pi, exePath=${exePath}: File exists!"
          } else {
            error "Found no interpreter for ${env.NODE_NAME}. Labels: ${env.NODE_LABELS}"
          }
          testPath="%xinD%pi_%VERSION%${ed}${BITS}/"
          cmdline = "%CMDLINE% citaDEVT=${citaDEVT} CONFIGFILE=${testPath}cita.dcfg CITA_Log=${testPath}CITA.log LOG_FILE=${testPath}CITA_Session.dlf"
        //cmdline = "$cmdline > ${testPath}ExecuteLocalTest.log"
          
          echo "Launching $exePath $cmdline "
          rc = sh(script: "$exePath $cmdline" , returnStatus: true)
                exists = fileExists(citaLOG)
          echo "citaLOG=$citaLOG, exists=$exists"
          rc = 0
          if (exists){
            props = readJSON file: "${testPath}/CITA.log.json"
            echo "R="
            props.each { key, value ->
              // echo "$key .rc=" . props["$key"]['rc'].toString()
              if (props["$key"]['rc'] != 0) {
                rc = 1
              }
            }
          } else {
            echo "Test did not end with JSON log ${testPath}/CITA.log.json"
            rc = 1
          }
        } catch (err)
        {
          echo "Caught error: ${err}"
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