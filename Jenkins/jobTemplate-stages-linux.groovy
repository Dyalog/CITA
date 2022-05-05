stage ("run test") {
    script {
        [%EXTRAS%].each { DISTRO ->
            stage ("test on ${DISTRO}") {
                agent {
                    docker {
                        label "docker"
                       // image "${DISTRO}"
                       image "dyalog/dyalog"
                        args '-v %xinD%:/app/'
                        args '-v /devt:/devt'
                    }
                }
                steps {
                    script {
                    echo "NODE_NAME = ${env.NODE_NAME}"
                    def testPathO=""   // Our path
                    def testPathC=""  // "Container path"
                    echo "copy  %xinD%/CITA/install-dyalog /app/" // copy installer into test-folder
                    [%BITS%].each { BITS ->
                        [ %EDITIONS%].each { EDITION ->
                                // catchError(buildResult: "UNSTABLE", stageResult: "FAILURE") {
                                try {
                                    sh "/app/install-dyalog %VERSION% %EDITION% %BITS%"
                                    exePath = "/opt/mdyalog/%VERSION%/${BITS}/${EDITION}/mapl"
                                    E = EDITION.take(1)
                                    exists = fileExists(exePath)
                                    if (exists) {
                                        echo "PLATFORM=linux, exePath=${exePath}: File exists!"
                                    } else {
                                        error "Found no interpreter for ${env.NODE_NAME}. Labels: ${env.NODE_LABELS}"
                                    }
                                    testPathC = "/app/linux_%VERSION%${E}${BITS}/"
                                    testPathO = "%xinD%/linux_%VERSION%${E}${BITS}/"
                                    cmdline = "%CMDLINE% citaDEVT=${citaDEVT} CONFIGFILE=${testPathC}cita.dcfg CITA_Log=${testPathC}CITA.log LOG_FILE=${testPathC}CITA_Session.dlf"
                                    cmdline = "$cmdline > ${testPathC}ExecuteLocalTest.log"

                                    echo "Launching $exePath $cmdline "
                                    rjc = sh(script: "$exePath $cmdline", returnStatus: true)
                                    exists = fileExists("${testPathO}CITA.log.ok")
                                    if (exists) {
                                        echo "Test succeeded"
                                        rc = 0
                                    } else {
                                        echo "Test did not end with status file ${testPathO}CITA_LOG.ok"
                                        rc = 1
                                    }
                                } catch (err) {
                                    echo "Caught error: ${err}"
                                    // unstable("Stage failed!")
                                    rc = 1
                                }
                                if (rc != 0) {
                                    unstable("Stage failed!")
                                    rc = 0
                                }
                                echo "rc=$rc"
                                sh "exit $rc"
                            }
                        }
                    }
                }
            }
        }
    }
}