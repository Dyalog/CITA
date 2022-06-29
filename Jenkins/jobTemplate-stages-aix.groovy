stage ('aix_%CITA_VERSION%_%VERSION%') {
  node ('aix&&%CITA_VERSION%&&%VERSION%') {
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
            if ("$EDITION" == 'classic') {
              cmdlinePre = 'APLT1=utf8 APLT2=utf8 APLK0=utf8 '
            }
            ed = EDITION.take(1)
            testPath = "%xinD%aix-${P}_%VERSION%${ed}${BITS}/"
            testPath = "${testPath}"
            echo "testPath = ${testPath}"
            citaLOG="${testPath}CITA.log"
            cmdline = "%CMDLINE%  citaDEVT=${citaDEVT} CONFIGFILE=${testPath}cita.dcfg CITA_Log=${citaLOG}"
            cmdline = "${cmdline} > ${testPath}ExecuteLocalTest.log"

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
                //  echo "$key .rc=" . props["$key"]['rc'].toString()
                if (props["$key"]['rc'] != 0) {
                  rc = 1
                  echo "aix-${P}${key}_%VERSION%${ed}${BITS}: rc is not 0!"
                }
              }
            } else {
              ed = "Test did not end with JSON log ${citaLOG}.json"
              echo ed
              writeFile(file: "${citaLOG}.json", text: "{\"rc\":2,\"Log\":\"${ed}\"}", encoding: 'UTF-8')
              rc = 2
            }
          } catch (err) {
            if ("${err}".startsWith('org.jenkinsci.plugins.workflow.steps.FlowInterruptedException')) {
              // Build was aborted
              echo "Caught interrupt"
              rc = 1
              writeFile(file: "${citaLOG}.json", text: "{\"rc\":10,\"Log\":,\"${err}\"}", encoding: 'UTF-8')
            } else {
            // Build failed
              echo "Caught error: ${err}"
              rc = 1
              writeFile(file: "${citaLOG}.json", text: "{\"rc\":10,\"Log\":,\"${err}\"}", encoding: 'UTF-8')
            }
          } finally  {
            testPath = testPath.replace('/','\\/')
            sh """
            ps -fu jenkins | awk \'/${testPath}/ {print \$2}\' | while read PID
            do kill -9 \$PID
            done
            """
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
