:namespace _cita

    ∇ Write2Log txt;file
      ⍝ needs name of test
      file←GetCITA_Log
      :If ~⎕NEXISTS file
          txt ⎕NPUT file
      :Else ⍝ q&d "append":
          old←1⊃⎕NGET file
          (⊂old,⊂txt)⎕NPUT file 1
      :EndIf
    ∇

    ∇ R←GetCITA_Log
      :If 0=≢R←'.log',⍨2 ⎕NQ'.' 'GetEnvironment' 'CITA_Log'
          ⎕←2 ⎕NQ'.' 'GetCommandLine'   ⍝ spit out commandline into the session - maybe it help diagnosing the problem...
          'Found no CITA_Log in Environment - this dws is supposed to be called from CITA which should have passed the right commandline'⎕SIGNAL 11
      :EndIf
    ∇

    ∇ {msg}_LogStatus status;file
⍝ A step (setup|test|teardown) is finished, report its status to the engine.
⍝ msg allows inject of a message into the file, otherwise an empty file will be created.
⍝ options:
⍝ fail  | ok
⍝ err   | success
⍝ no    | yes
⍝ 0     | 1
      :If 0=⎕NC'msg' ⋄ msg←'' ⋄ :EndIf
      file←GetCITA_Log
      :If isChar status  ⍝ decode status from character-string
          :If ∨/(⊂lc status){(0<''⍴⍴⍺)∧⍺≡(''⍴⍴⍺)↑⍵}¨'failure' 'error' 'no'
              status←0
          :ElseIf ∨/(⊂lc status){(0<''⍴⍴⍺)∧⍺≡(''⍴⍴⍺)↑⍵}¨'success' 'ok' 'yes'
              status←1
          :Else
          :EndIf
      :Else
          status←1∊status
      :EndIf
      status←(1+status)⊃'err' 'ok'
    ⍝ we're intentionally not passing ⍵[2]as 1 to force overwrite - because this is supposed to be called once only!
    ⍝ So if it crashes...that is well deserved...
      (⊂msg) ⎕NPUT file,'.',status
      ⎕off
    ∇

⍝ Define Success'blablabla' and Failure'blabla' as shortcuts to 'blabla'_LogStatus 1|0
    Success←_LogStatus∘1
    Failure←_LogStatus∘0

:endnamespace
