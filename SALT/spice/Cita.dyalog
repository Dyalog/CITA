:Namespace Cita
   ⍝ UCMDs for CITA.
   ⍝ The individual commands and their syntax are API-Fns,
   ⍝ whose comments describe syntax and provide documentation.
   ⍝ So this file will hopefully never need to be updated!
    ⎕ml←⎕io←1

    ∇ r←List
      :If 2<+/∊(⊂'.Cita')⍷¨⎕NSI
          r←0 5⍴''    ⍝ return empty list if this is called multiple times (if we see ".Cita" in ⎕nsi multiple times), as that could end up with infinite recursion...
        ⍝   ⎕←'Cita.List returning empty array for call from '⋄⎕←((⊂⍕⎕this),¯1↓⎕nsi),⎕si,[1.5]⎕lc
          →0
      :Else
        ⍝   ⎕←'Cita.List regular processing '⋄⎕←((⊂⍕⎕this),¯1↓⎕nsi),⎕si,[1.5]⎕lc
      :EndIf
      Init 0
      r←⎕SE.CITA.UCMD.List
    ∇

    ∇ r←level Help cmd
      Init 1
      r←level ⎕SE.CITA.UCMD.Help cmd
    ∇

    ∇ r←Run(cmd args)
      Init 1
      r←⎕SE.CITA.UCMD.Run(cmd args)
    ∇

    ∇ Init ureset;Home;t
      :Trap 0/0
          ⍝ MB: initialising API (loading it) is no longer optional, as it only takes a neglectable 300ms and adds a lot of convenience while developing
          ⍝ (if we get complaints, it can still be made optional depending on an envvar etc.)
          ⍝ :If 0=⎕NC'⎕SE.CITA.UCMD._List'
              ⍝ :If 0=⎕NC'⎕SE.CITA'
          :If 2=##.⎕NC't' ⍝ lets see if we can work out where came from
          :AndIf ⎕NEXISTS ##.t,'.dyalog'   ⍝ lets see if we can work out where came from (this works during List...)
              Home←((({1⊃⎕NPARTS ¯1↓⍵})⍣3)##.t),'API'
          :Else
              Home←(1⊃⎕RSI).##.##.List{0::'' ⋄ 7⊃(⍺⍪⊂'')[⍺[;1]⍳⊂⍵;]}'cita'    ⍝ we're called during Run - get location from cached list
              Home←∊1 ⎕NPARTS(1⊃⎕NPARTS Home),'../../API'
          :EndIf
          :If ⎕NEXISTS Home
              :If ~ureset                        ⍝ if ureset is optional
              :AndIf 2=⎕NC'⎕SE.CITA.UCMD.List'   ⍝ and the list of UCMDs exists (which is a sign we've initialised before)
                  →0                             ⍝ do not bother to initialise (again) - probably we're called during List
              :EndIf
              ⎕SE.⎕EX'CITA'
              'CITA'⎕SE.⎕NS''
              {}⎕SE.Link.Break ⎕SE.CITA
     
                      ⍝(⎕json'{"overwrite":1}')⎕SE.Link.Import ⎕SE.CITA Home   ⍝ don't assume it'll be in the session...
              :If 0<≢t←2 ⎕NQ'.' 'GetEnvironment' 'CITA_APIDEV'   ⍝ this needs to be in environment
              :orIf 1≡⍥,2⊃⎕VFI t
                  :Trap 0/0
                      {}⎕SE.Link.Create ⎕SE.CITA Home
                  :Else
                      ⎕←'Trapped error during LINK.Create'
                      ⎕←(⎕JSON ⎕OPT'Compact' 0)⎕DMX
                  :EndTrap
              :Else
                  :Trap 0
                      {}⎕SE.Link.Import ⎕SE.CITA Home
                  :Else
                      ⎕←'Trapped error during LINK.Import'
                      ⎕←(⎕JSON ⎕OPT'Compact' 0)⎕DMX
                  :EndTrap
              :EndIf
              :If 0=⎕NC'⎕SE.CITA.API'  ⍝ if we had any issues using LINK
                  :Trap 0              ⍝ use ]LOAD instead
                      'CITA'⎕SE.⎕NS''
                      ⎕SE.CITA{
                          '*'∊⍵:(⊂⍺)∇¨⊃0(⎕NINFO ⎕OPT'Wildcard' 1)⍵
                          1=⊃1 ⎕NINFO ⍵:(((⍕⍺),'.',2⊃⎕NPARTS ⍵)⎕NS'')∇ ⍵,'/*'  ⍝ recursively load subdirs into new ns
                          (2=⊃1 ⎕NINFO ⍵)∧(⎕NPARTS ⍵)[3]∊'.aplf.' '.dyalog' '.aplc' '.apln':⎕SE.SALT.Load ⍵,' -target=',(⍕⍺),(0<≢t←2 ⎕NQ'.' 'GetEnvironment' 'DYALOGCITA_APIDEV')/' -nolink'
                      }Home,'/*'
                  :Else
                      ⎕←'Error loading CITA namespaces...'
                      ⎕←(⎕JSON ⎕OPT'Compact' 0)⎕DMX
                      →0
                  :EndTrap
                  ⎕SE.CITA.DYALOGCITASRCDIR←Home
              :EndIf
              ⎕SE.SALT.Load Home,'/../deps/HttpCommand/source/HttpCommand.dyalog'
            ⍝   :If 0<≢2 ⎕NQ'.' 'GetEnvironment' 'CITA_APIDEV' ⍝ temporaily to use bjorns latest DLLs
            ⍝       HttpCommand.CongaPath←'/git/CITA/'
            ⍝   :EndIf
              :If 0=⎕SE.CITA.⎕NC'APLProcess'  ⍝ it probably no longer exists in the API folder, so we use what we got with the interpreter...
                  ⎕SE.SALT.Load'APLProcess -target=⎕SE.CITA'
              :EndIf
            ⎕SE.SALT.Load Home,'/../deps/DCL/Crypt.dyalog -target=#'
            #.Crypt.Init Home,'/../deps/DCL/'              
              ⎕SE.CITA.API._InitUCMDs
              :If ureset
                  ⎕SE.SALTUtils.ResetUCMDcache 1  ⍝ avoid calling ]UReset, as that would add another call to List etc...
              :EndIf
              ⎕SE.CITA.Config←(⎕se.CITA.⎕JSON ⎕OPT'Dialect' 'JSON5')1⊃⎕NGET Home,'/../CITA_Config.json5'
     
     
          :Else
              ⎕←'Computed home-folder for CITA ("',Home,'" did not exist - please contact mbaas@dyalog.com!'
              →0
          :EndIf
      :Else
          ⎕←'Error initialising CITA UCMD:'
          ⎕←(⎕JSON ⎕OPT'Compact' 0)⎕DMX
          →0
      :EndTrap
    ∇

:endnamespace
