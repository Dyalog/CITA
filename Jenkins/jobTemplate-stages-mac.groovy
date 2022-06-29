stage ('mac_%CITA_VERSION%_%VERSION%') {
  node ('mac&&%CITA_VERSION%&&%VERSION%') {
    // no looping over bits/editions - mac is always unicode 64 
    // catchError(buildResult: "UNSTABLE", stageResult: "FAILURE") {
    try {
      echo "NODE_NAME = ${env.NODE_NAME}"
      exePath = '/Dyalog/Dyalog-%VERSION%.app/Contents/Resources/Dyalog/mapl'
      exists = fileExists(exePath)
      if (exists) {
        echo "PLATFORM=mac, exePath=${exePath}: File exists!"
      } else {
        echo "PLATFORM=mac, exePath=${exePath}: File does not exist, trying another exePath"
        exePath = '/Applications/Dyalog-%VERSION%.app/Contents/Resources/Dyalog/mapl'
        exists = fileExists(exePath)
        if (exists) {
          echo "PLATFORM=mac, exePath=${exePath}: File exists!"
        } else {
          error "PLATFORM=mac, exePath=${exePath}: File does not exist, giving it up!"
        }
      }

      if ("${env.NODE_NAME}" == 'mac3') {
        echo 'replacing for mac3'
        citaDEVT = '/Volumes/devt/'
      } else {
        citaDEVT = '/devt/'
      }

      testPath = "%xinD%mac_%VERSION%u64/"
      citaLOG = "${testPath}CITA.log"
      echo "testPath=$testPath"
      echo "citaDEVT=$citaDEVT"
      cmdline = "%CMDLINE% citaDEVT=${citaDEVT} CONFIGFILE=${testPath}cita.dcfg CITA_Log=${citaLOG}"
      cmdline = "$cmdline > ${testPath}ExecuteLocalTest.log"

      echo "cmdline=$cmdline"
      echo "citaLOG=$citaLOG"
      echo "Launching $exePath $cmdline"
      rc = sh(script: "$exePath $cmdline" , returnStatus: true)
      echo "rc=$rc"

      exists = fileExists("${citaLOG}.json")
      echo "citaLOG=$citaLOG, exists=$exists"
      rc = 0
      if (exists){
        props = readJSON file: "${citaLOG}.json"
        echo "R="
        props.each { key, value ->
           //echo "$key / $value" . props["$key"]['rc'].toString()
          if (props["$key"]['rc'] != 0) {
            rc = 1
          }
        }
      } else {
        echo "Test did not end with JSON log ${citaLOG}.json"
        rc = 1
      }
    } catch (err)
    {
      echo "Caught error: ${err}"
      rc = 1
    }
    if (rc != 0){
      unstable('Stage failed!')
      rc = 0
    }
    // sh "ps -fu jenkins | awk '%xinD% {print $2}' | while read PID
    //     do
    //       sudo kill -9 $PID
    //     done"

    echo "rc=$rc"
    sh "exit $rc"
  }
}