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
          citaDEVT="U:/"

          echo "NODE_NAME = ${env.NODE_NAME}"
          ed = EDITION.take(1)
          EDITION = EDITION.capitalize()
          echo "EDITION=${EDITION}"

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
            error "Found no interpreter for ${ed}_${BITS} on ${env.NODE_NAME}. Labels: ${env.NODE_LABELS}"
          }
          testPath="%xinD%win_%VERSION%${ed}${BITS}/"
          citaLOG="${testPath}CITA.log"
          //cmdline = "%CMDLINE% citaDEVT=${citaDEVT} CONFIGFILE=${testPath}cita.dcfg CITA_Log=${testPath}CITA.log"
          cmdline = "%CMDLINE% citaDEVT=${citaDEVT} CONFIGFILE=${testPath}cita.dcfg CITA_Log=${citaLOG}"
          cmdline = "${cmdline} > ${testPath}ExecuteLocalTest.log"
          echo "Launching ${path} ${cmdline} "
          rjc = bat(script: "\"${path}\" ${cmdline}" , returnStatus: true)
          echo "citaLOG=$citaLOG"

          citaLOG="${testPath}CITA.log.json"
          exists = fileExists(citaLOG)
          echo "citaLOG=$citaLOG, exists=$exists"
          rc = 0
          if (exists){
            props = readJSON file: "${citaLOG}"
            echo "R="
            props.each { key, value ->
              // echo "$key .rc=" . props["$key"]['rc'].toString()
              if (props["$key"]['rc'] != 0) {
                rc = 1
              }
            }
          } else {
            echo "Test did not end with JSON log ${citaLOG}"
            rc = 1
          }
        } catch (err)
        {
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
