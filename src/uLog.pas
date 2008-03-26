unit uLog;

interface

uses
  uEnums;

var
  m_DxbxDebug: DebugMode = DM_NONE;
  m_DxbxDebugFilename: string = '';
  m_KrnlDebug: DebugMode = DM_CONSOLE;
  m_KrnlDebugFilename: string = '';

procedure CreateLogs(aLogType: LogType = ltKernel);
procedure CloseLogs;
procedure WriteLog(aText: string);


implementation

uses
  uLogConsole, Dialogs;

var
  LogMode     : DebugMode = DM_NONE;
  LogFileOpen : Boolean = False;
  LogFile     : TextFile;

procedure CreateLogs(aLogType: LogType);
begin
  case aLogType of
    ltGui    : begin
                 case m_DxbxDebug of
                   DM_NONE    : begin
                                  CloseLogs;
                                end;
                   DM_CONSOLE : begin
                                  try
                                    frm_LogConsole := Tfrm_LogConsole.Create(nil);
                                    frm_LogConsole.Caption := 'DXBX : Debug Console';
                                    frm_LogConsole.Show;
                                    LogMode := DM_CONSOLE;
                                  finally
                                  end;
                                end;
                   DM_FILE    : begin
                                  try
                                    AssignFile(LogFile, m_DxbxDebugFilename);
                                    Rewrite(LogFile);
                                    LogFileOpen := True;
                                    LogMode := DM_FILE;
                                  except
                                    ShowMessage('Could not create log file');
                                    LogMode := DM_NONE;
                                  end;
                                end;
                 end;
               end;
    ltKernel : begin
                 case m_KrnlDebug of
                   DM_NONE    : begin
                                  CloseLogs;
                                end;
                   DM_CONSOLE : begin
                                  frm_LogConsole := Tfrm_LogConsole.Create(nil);
                                  frm_LogConsole.Caption := 'DXBX : Kernel Debug Console';
                                  frm_LogConsole.Show;
                                  LogMode := DM_CONSOLE;
                                end;
                   DM_FILE    : begin
                                  try
                                    AssignFile(LogFile, m_KrnlDebugFilename);
                                    Rewrite(LogFile);
                                    LogFileOpen := True;
                                    LogMode := DM_FILE;
                                  except
                                    ShowMessage('Could not create log file');
                                    LogMode := DM_NONE;
                                  end;
                                end;
                 end;
               end;
  end;
end;

procedure CloseLogs;
begin
  if frm_LogConsole <> nil then begin
    frm_LogConsole.Release;
    frm_LogConsole := nil;
  end;
  if LogFileOpen then begin
    CloseFile(LogFile);
    LogFileOpen := False;
  end;
  LogMode := DM_NONE;
End;

procedure WriteLog(aText: string);
begin
    case LogMode of
      DM_CONSOLE : frm_LogConsole.Log.Lines.Add(aText);
      DM_FILE    : WriteLn(LogFile, aText);
    end;
end;

end.