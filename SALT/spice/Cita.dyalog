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
      :Trap 0
          :If 0=⎕NC'⎕SE.CITA.UCMD._List'
              :If 0=⎕NC'⎕SE.CITA'
                  :If 2=##.⎕NC't' ⍝ lets see if we can work out where came from
                  :AndIf ⎕NEXISTS ##.t,'.dyalog'   ⍝ lets see if we can work out where came from (this works during List...)
                      Home←((({1⊃⎕NPARTS ¯1↓⍵})⍣3)##.t),'StartupSession/CITA'
                  :Else
                      Home←(1⊃⎕RSI).##.##.List{0::'' ⋄ 7⊃(⍺⍪⊂'')[⍺[;1]⍳⊂⍵;]}'cita'    ⍝ we're called during Run - get location from cached list 
                  :EndIf
                  :If ⎕NEXISTS Home
                      'CITA'⎕SE.⎕NS''
                      {}⎕SE.Link.Import ⎕SE.CITA Home
                    ⍝   ⎕←'Link.imported ⎕SE.CITA from ',Home
                      ⎕SE.CITA.DYALOGCITASRCDIR←Home
                  :Else
                      ⎕←'Computed home-folder for CITA ("',Home,'" did not exist - please contact mbaas@dyalog.com!'
                      →0
                  :EndIf
              :EndIf
              ⎕SE.CITA.API._InitUCMDs
          :EndIf
      :Else
          ⎕←'Error initialising CITA UCMD:'
          ⎕←(⎕JSON ⎕OPT'Compact' 0)⎕DMX
          →0
      :EndTrap
    ∇

:endnamespace
