--http://forum.farmanager.com/viewtopic.php?f=60&t=8546
--requires FAR 3 build >=3854 (EF_OPENMODE_USEEXISTING)
local F = far.Flags
local _name = "alias.doskey"
local _filename = Macro and ... or _filename:match[[^\\%?\(.+)$]]
local _aliasfile = _filename:match[[(.+\).+$]].._name
local cmd_edit = "a"
local cmd_reload = "rr"

local flags = {EF_DISABLEHISTORY=1,EF_NONMODAL=1,EF_IMMEDIATERETURN=1,EF_OPENMODE_USEEXISTING=1}
local function EditAlias(str)
  editor.Editor (_aliasfile, _name, nil, nil, nil, nil, flags, line, nil, win.GetOEMCP()) --todo check CP
  if not Area.Editor or not str or str=="" then return end
  local n,pattern = str:len(),"^%s*"..str:lower().."%s*=" --todo find spec symbols []()%.?+-*
  for i=1,editor.GetInfo().TotalLines do
    local line = editor.GetString(nil,i,3):lower()
    if line:match(pattern) then
      editor.SetPosition (nil, i, n, nil, i-2, 1)
      editor.Select (nil, "BTYPE_STREAM", i, line:find(str), n, 1)
      Editor.Set(2,1) --Persistent blocks
      return
      editor.Redraw()
    end
  end
  far.Message(("Could not find the string\n%q"):format(str),"Search",nil,"w")
end

if not Macro then -- Aliases: open in editor from cmdline
  EditAlias(...)
  return
end

local function Utf8ToAnsi(str)
  return win.WideCharToMultiByte(win.Utf8ToUtf16(str),win.GetACP())
end

local cmds = {
  string.format('doskey %s=lua:@"%s" "$*"',cmd_edit,_filename),
  string.format('doskey %s=doskey/macrofile="%s"',cmd_reload,Utf8ToAnsi(_aliasfile)),
  string.format('doskey/macrofile="%s"',Utf8ToAnsi(_aliasfile)),
}

local function Reload()
  local info = win.GetFileInfo(_aliasfile)
  if not info then
    far.Message(("File is absent: '%s'"):format(_aliasfile),"Console aliases",nil,"w")
    return
  end
  local scr,time = far.SaveScreen(),Far.UpTime
  far.Message("Loading...","Console aliases","")
  for i=1,#cmds do os.execute(cmds[i]) end
  local delay = 200-(Far.UpTime-time)
  if delay>0 then win.Sleep(delay) end
  far.RestoreScreen()
  far.RestoreScreen(scr)
end

Event { description="Aliases: reload on edit";
  group="EditorEvent"; filemask=_name;
  condition=function(id,Event) return Event==F.EE_CLOSE end;
  action=function() 
    local EditorInfo = editor.GetInfo()
    if EditorInfo.FileName:lower()==_aliasfile:lower()
        and band(EditorInfo.CurState,F.ECSTATE_MODIFIED)~=0 then
      Reload(_aliasfile)
    end
  end;
}

--Reload()
Macro { description="Aliases: Load on start";
  area="Shell"; key="auto"; flags="RunAfterFARStart";
  action=Reload;
}
