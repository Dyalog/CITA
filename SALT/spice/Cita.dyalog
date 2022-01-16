:Namespace Cita
   ⍝ UCMDs for CITA.
   ⍝ The individual commands and their syntax are API-Fns,
   ⍝ whose comments describe syntax and provide documentation.
   ⍝ So this file will hopefully never need to be updated!

    ∇ r←List
      Init
      r←⎕SE.CITA.UCMD.List
    ∇

    ∇ r←level Help cmd
      Init
      r←level ⎕SE.CITA.UCMD.Help cmd
    ∇

    ∇ r←Run(cmd args)
      Init
      r←⎕SE.CITA.UCMD.Run(cmd args)
    ∇

    ∇ Init;Home
    :trap 0
      :If 0=⎕NC'⎕SE.CITA.UCMD._List'
          :If 0=⎕NC'⎕SE.CITA'
          :if 2=##.⎕nc't'  ⍝ lets see if we can work out where came from
          :andif ⎕nexists ##.t  ⍝ lets see if we can work out where came from (this works during List...)
          Home←(({1⊃⎕nparts ¯1↓⍵})⍣3)##.t),'/StartupSession/CITA'
          :if ⎕nexists Home 
          'CITA'⎕SE.⎕ns''  
          ⎕se.Link.Import  ⎕se.Link.CITA Home
          :else 
              ⎕←'Computed home-folder for CITA ("',Home,'" did not exist - please contact mbaas@dyalog.com!'
              →0
          :endif
          :else
              ⎕←'Could not find ⎕SE.CITA - please check your StartupSession-Folder!'
              →0
          :EndIf
          ⎕SE.CITA.API._InitUCMDs
      :EndIf
      :else 
⎕←'Error initialising CITA UCMD:'
⎕←(⎕json⎕opt'Compact'0)⎕dmx
→0

      :endif
    ∇

:endnamespace
