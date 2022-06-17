// steps {
    // script {
        // [%EXTRAS%].each { DISTRO ->

    // stage ("test on ${DISTRO}") {
    agent {
        docker {
        ///    label "docker"
        // image "${DISTRO}"
            image "ubuntu:22.04"  // seems we can't loop over editions inside the script, need to create segments repeatedly
            args '-v /devt:/devt'
            args "-v %xinD%:/app/"
        }
    }
    steps {
        script {
            echo "NODE_NAME = ${env.NODE_NAME}"
            echo "/app = %xinD%"
            int rc = -1

            String citaDEVT = '/devt/'
            String citaLOG = ''
            String cmdline = '%CMDLINE%'
            String ed = ''
            String exePath = ''
            String testPath = ''

            Boolean exists = false
            String testPathO = ''   // Our path
            String testPathC = ''  // "Container path"
            [%BITS%].each { bits ->
                [%EDITIONS%].each { edition ->
                    // catchError(buildResult: "UNSTABLE", stageResult: "FAILURE") {
                    try {
                        sh 'ls -l /app/CITA'
                        sh "/app/CITA/install-dyalog %VERSION% ${edition} ${bits}"
                        exePath = "/opt/mdyalog/%VERSION%/${bits}/${edition}/mapl"
                        ed = edition.take(1)
                        exists = fileExists(exePath)
                        if (exists) {
                            echo "PLATFORM=linux, exePath=${exePath}: File exists!"
                        } else {
                            error "Found no interpreter ${env.NODE_NAME}. Labels: ${env.NODE_LABELS}"
                        }
                        testPathO = "%xinD%"
                        testPathO = "${testPathO}/linux_%VERSION%${ed}${bits}/"
                        testPathC = "/app/linux_%VERSION%${ed}${bits}/"
                        cmdline = "%CMDLINE%"
                        cmdline = "${cmdline} citaDEVT=${citaDEVT}"
                        cmdline = "${cmdline} CONFIGFILE=${testPathC}cita.dcfg"
                        cmdline = "${cmdline} CITA_Log=${testPathC}CITA.log"
                        cmdline = "${cmdline} LOG_FILE=${testPathC}CITA_Session.dlf"
                        cmdline = "$cmdline > ${testPathC}ExecuteLocalTest.log"
                        citaLOG = "${testPath}CITA.log.json"

                        echo "Launching $exePath $cmdline "
                        rjc = sh(script: "$exePath $cmdline", returnStatus: true)
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
                    if (rc != 0) {
                        unstable('Stage failed!')
                        rc = 0
                    }
                    echo "rc=$rc"
                    sh "exit $rc"
                    }
                }
            }
    //          }
    //       }
    //     }
    //   }
    }
