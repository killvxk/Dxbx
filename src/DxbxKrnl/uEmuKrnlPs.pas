(*
    This file is part of Dxbx - a XBox emulator written in Delphi (ported over from cxbx)
    Copyright (C) 2007 Shadow_tj and other members of the development team.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*)
unit uEmuKrnlPs;

{$INCLUDE ..\Dxbx.inc}

interface

uses
  // Delphi
  SysUtils,
  // Jedi
  JwaWinType,
  JwaWinBase,
  JwaWinNT,
  JwaNative,
  JwaNTStatus,
  // OpenXDK
  XboxKrnl,
  // Dxbx
  uLog,
  uEmuFS,
  uEmuFile,
  uEmuXapi,
  uEmuKrnl,
  uDxbxKrnl;

var
  {259}xboxkrnl_PsThreadObjectType: POBJECT_TYPE; // Source: OpenXDK - Uncertain

function {254} xboxkrnl_PsCreateSystemThread(
(* XBMC says :
 ThreadHandle: PHANDLE; // OUT
 ThreadId: PULONG; // OUT, OPTIONAL
 StartContext1: PVOID;
 StartContext2: PVOID;
 DebugStack: LONGBOOL
*)
  lpThreadAttributes: PULONG; // SD
  dwStackSize: DWORD; // initial stack size
  lpStartAddress: PKSTART_ROUTINE; // thread function
  lpParameter: PVOID; // thread argument
  dwCreationFlags: DWORD; // creation option
  lpThreadId: PULONG // thread identifier
  ): NTSTATUS; stdcall; // Source: Cxbx - TODO : Should we use XBMC's version?
function {255} xboxkrnl_PsCreateSystemThreadEx(
  ThreadHandle: PHANDLE; // out
  ThreadExtraSize: ULONG; // XBMC Says : ObjectAttributes: PVOID; // OPTIONAL
  KernelStackSize: ULONG;
  TlsDataSize: ULONG;
  ThreadId: PULONG; // out, optional
  StartContext1: PVOID;
  StartContext2: PVOID;
  CreateSuspended: LONGBOOL;
  DebugStack: LONGBOOL;
  StartRoutine: PKSTART_ROUTINE
  ): NTSTATUS; stdcall; // Source: Cxbx / XBMC
function {256} xboxkrnl_PsQueryStatistics(): NTSTATUS; stdcall; // UNKNOWN_SIGNATURE
function {257} xboxkrnl_PsSetCreateThreadNotifyRoutine(
  NotifyRoutine: PCREATE_THREAD_NOTIFY_ROUTINE
  ): NTSTATUS; stdcall; // Source: ReactOS
function {258} xboxkrnl_PsTerminateSystemThread(
  ExitStatus: NTSTATUS
  ): NTSTATUS; stdcall; // Source : XBMC

implementation

// Global Variable(s)
var
  g_pfnThreadNotification: PVOID = nil;

type
  // PsCreateSystemThread proxy parameters
  PPCSTProxyParam = ^PCSTProxyParam;
  PCSTProxyParam = packed record
    StartContext1: PVOID;
    StartContext2: PVOID;
    StartRoutine: PKSTART_ROUTINE;
    StartSuspended: BOOL;
    hStartedEvent: HANDLE;
  end;

// PsCreateSystemThread(Ex) proxy procedure
//pragma warning(push)
//pragma warning(disable: 4731)  // disable ebp modification warning

function {WINAPI} PCSTProxy(Parameter: PPCSTProxyParam): Integer; stdcall; //Word;
label
  callComplete;
var
  StartContext1: PVOID;
  StartContext2: PVOID;
  StartRoutine: PKSTART_ROUTINE;
  StartSuspended: BOOL;
  pfnNotificationRoutine: XTHREAD_NOTIFY_PROC;
begin
  StartContext1 := Parameter.StartContext1;
  StartContext2 := Parameter.StartContext2;
  StartRoutine := Parameter.StartRoutine;
  StartSuspended := Parameter.StartSuspended;

  DbgPrintf('EmuKrnl : PCSTProxy' +
    #13#10'(' +
    #13#10'   StartContext1       : 0x' + IntToHex(Integer(StartContext1), 8) +
    #13#10'   StartContext2       : 0x' + IntToHex(Integer(StartContext2), 8) +
    #13#10'   StartRoutine        : 0x' + IntToHex(Integer(Addr(StartRoutine)), 8) +
    #13#10');');

  if StartSuspended then
    SuspendThread(GetCurrentThread());

  EmuGenerateFS(CxbxKrnl_TLS, CxbxKrnl_TLSData);

  // call thread notification routine(s)
  if Assigned(g_pfnThreadNotification) then
  begin
    pfnNotificationRoutine := {XTL.} XTHREAD_NOTIFY_PROC(g_pfnThreadNotification);

    DbgPrintf('EmKrnl : Calling pfnNotificationRoutine (0x%.08x)', [Addr(pfnNotificationRoutine)]);

    EmuSwapFS(); // Xbox FS

    pfnNotificationRoutine(True);

    EmuSwapFS(); // Win2k/XP FS
  end;

  // use the special calling convention
  try
    SetEvent(Parameter.hStartedEvent);

    DbgPrintf('EmuKrnl : PCSTProxy : DEBUG, this thread hangs somewhere after this line!');

    EmuSwapFS(); // Xbox FS

    asm
        mov         esi, StartRoutine
        push        StartContext2
        push        StartContext1
        push        offset callComplete
        lea         ebp, [esp-4]
//        jmp near    esi
        jmp         esi
    end;
  except
    on E: Exception do
      DbgPrintf('EmuKrnl : PCSTProxy : Catched an exception : ' + E.Message);
//  __except(EmuException(GetExceptionInformation()))
//    EmuWarning('Problem with ExceptionFilter!');
  end;

  callComplete:

  EmuSwapFS(); // Win2k/XP FS

  // call thread notification routine(s)
  if Assigned(g_pfnThreadNotification) then
  begin
    pfnNotificationRoutine := {XTL.} XTHREAD_NOTIFY_PROC(g_pfnThreadNotification);

    EmuSwapFS(); // Xbox FS

    pfnNotificationRoutine(False);

    EmuSwapFS(); // Win2k/XP FS
  end;

  CxbxKrnlTerminateThread();

  Result := 0;
end;
//pragma warning(pop)

////

// PsCreateSystemThread:
// Creates a system thread.  Same as:
// PsCreateSystemThreadEx(ThreadHandle, NULL, 0x3000, 0, ThreadId, StartContext1,
//     StartContext2, FALSE, DebugStack, PspSystemThreadStartup);
//
// New to the XBOX.  (It is too different from NT to be considered the same)

function {254} xboxkrnl_PsCreateSystemThread(
(* XBMC says :
 ThreadHandle: PHANDLE; // OUT
 ThreadId: PULONG; // OUT, OPTIONAL
 StartContext1: PVOID;
 StartContext2: PVOID;
 DebugStack: LONGBOOL
*)
  lpThreadAttributes: PULONG; // SD
  dwStackSize: DWORD; // initial stack size
  lpStartAddress: PKSTART_ROUTINE; // thread function
  lpParameter: PVOID; // thread argument
  dwCreationFlags: DWORD; // creation option
  lpThreadId: PULONG // thread identifier
  ): NTSTATUS; stdcall; // Source: Cxbx - TODO : Should we use XBMC's version?
var
  ThreadHandle: HANDLE;
  ThreadExtraSize: ULONG;
  KernelStackSize: ULONG;
  TlsDataSize: ULONG;
  StartContext1: PVOID;
  StartContext2: PVOID;
  CreateSuspended: LONGBOOL;
  DebugStack: LONGBOOL;
begin
  EmuSwapFS(); // Win2k/XP FS

  // TODO : How to apply the local arguments like lpThreadAttributes ?
  ThreadHandle := 0;
  ThreadExtraSize := dwStackSize; // ??
  KernelStackSize := dwStackSize; // ??
  TlsDataSize := 0; // ??
  StartContext1 := lpParameter; // ??
  StartContext2 := nil; // ??
  CreateSuspended := (dwCreationFlags and CREATE_SUSPENDED) > 0;
  DebugStack := False; // ??

  DbgPrintf('EmuKrnl : PsCreateSystemThread' +
    #13#10'(' +
    #13#10'   lpThreadAttributes  : 0x' + IntToHex(lpThreadAttributes^, 8) +
    #13#10'   dwStackSize         : 0x' + IntToHex(dwStackSize, 8) +
    #13#10'   lpStartAddress      : 0x' + IntToHex(Integer(Addr(lpStartAddress)), 8) +
    #13#10'   lpParameter         : 0x' + IntToHex(Integer(lpParameter), 8) +
    #13#10'   dwCreationFlags     : 0x' + IntToHex(Integer(dwCreationFlags), 8) +
    #13#10'   ThreadId            : 0x' + IntToHex(Integer(Addr(lpThreadId)), 8) +
    #13#10');');
// PsCreateSystemThreadEx(ThreadHandle, NULL, 0x3000, 0, ThreadId, StartContext1,
//     StartContext2, FALSE, DebugStack, PspSystemThreadStartup);

  // Pass-through to Ex-implementation :
  Result := xboxkrnl_PsCreateSystemThreadEx(
    {dummy}@ThreadHandle,
    ThreadExtraSize,
    KernelStackSize,
    TlsDataSize,
    {ThreadId=}lpThreadId,
    StartContext1,
    StartContext2,
    CreateSuspended,
    DebugStack,
    {StartRoutine=}lpStartAddress
    );

  EmuSwapFS(); // Xbox FS
end;

// PsCreateSystemThreadEx:
// Creates a system thread.
// ThreadHandle: Receives the thread handle
// ObjectAttributes: Unsure how this works (everything I've seen uses NULL)
// KernelStackSize: Size of the allocation for both stack and TLS data
// TlsDataSize: Size within KernelStackSize to use as TLS data
// ThreadId: Receives the thread ID number
// StartContext1: Parameter 1 to StartRoutine
// StartContext2: Parameter 2 to StartRoutine
// CreateSuspended: TRUE to create the thread as a suspended thread
// DebugStack: TRUE to allocate the stack from Debug Kit memory
// StartRoutine: Called when the thread is created
//
// New to the XBOX.

function {255} xboxkrnl_PsCreateSystemThreadEx(
  ThreadHandle: PHANDLE; // out
  ThreadExtraSize: ULONG; // XBMC Says : ObjectAttributes: PVOID; // OPTIONAL
  KernelStackSize: ULONG;
  TlsDataSize: ULONG;
  ThreadId: PULONG; // out, optional
  StartContext1: PVOID;
  StartContext2: PVOID;
  CreateSuspended: LONGBOOL;
  DebugStack: LONGBOOL;
  StartRoutine: PKSTART_ROUTINE
  ): NTSTATUS; stdcall; // Source: Cxbx / XBMC
var
  dwThreadId: DWORD;
  hDupHandle: THandle;
  iPCSTProxyParam: PCSTProxyParam;
begin
  EmuSwapFS(); // Win2k/XP FS

  DbgPrintf('EmuKrnl : PsCreateSystemThreadEx' +
    #13#10'(' +
    #13#10'   ThreadHandle        : 0x' + IntToHex(Integer(ThreadHandle^), 8) +
    #13#10'   ThreadExtraSize     : 0x' + IntToHex(ThreadExtraSize, 8) +
    #13#10'   KernelStackSize     : 0x' + IntToHex(KernelStackSize, 8) +
    #13#10'   TlsDataSize         : 0x' + IntToHex(TlsDataSize, 8) +
    #13#10'   ThreadId            : 0x' + IntToHex(Integer(Addr(ThreadId)), 8) +
    #13#10'   StartContext1       : 0x' + IntToHex(Integer(StartContext1), 8) +
    #13#10'   StartContext2       : 0x' + IntToHex(Integer(StartContext2), 8) +
    #13#10'   CreateSuspended     : 0x' + IntToHex(Integer(CreateSuspended), 8) +
    #13#10'   DebugStack          : 0x' + IntToHex(Integer(DebugStack), 8) +
    #13#10'   StartRoutine        : 0x' + IntToHex(Integer(Addr(StartRoutine)), 8) +
    #13#10');');

  // create thread, using our special proxy technique
  begin
    // PCSTProxy is responsible for cleaning up this pointer
    iPCSTProxyParam.StartContext1 := StartContext1;
    iPCSTProxyParam.StartContext2 := StartContext2;
    iPCSTProxyParam.StartRoutine := StartRoutine;
    iPCSTProxyParam.StartSuspended := CreateSuspended;
    iPCSTProxyParam.hStartedEvent := CreateEvent(nil, False, False, nil);

    ThreadHandle^ := BeginThread(nil, 0, @PCSTProxy, @iPCSTProxyParam, 0, {var} dwThreadId);

    WaitForSingleObject(iPCSTProxyParam.hStartedEvent, 1000);

    DbgPrintf('EmuKrnl : ThreadHandle : 0x' + IntToHex(ThreadHandle^, 1) + ', ThreadId : 0x' + IntToHex(dwThreadId, 8));

    // we must duplicate this handle in order to retain Suspend/Resume thread rights from a remote thread
    begin
      hDupHandle := 0;

      if not DuplicateHandle(GetCurrentProcess(), ThreadHandle^, GetCurrentProcess(), @hDupHandle, 0, FALSE, DUPLICATE_SAME_ACCESS) then
        DbgPrintf('EmuKrnl : PsCreateSystemThreadEx - Couldn''t duplicate handle!');

      CxbxKrnlRegisterThread(hDupHandle);
    end;

    if Assigned(ThreadId) then
      {out}ThreadId^ := dwThreadId;
  end;

  EmuSwapFS(); // Xbox FS

  Result := STATUS_SUCCESS;
end;

function {256} xboxkrnl_PsQueryStatistics(): NTSTATUS; stdcall;
begin
  EmuSwapFS(); // Win2k/XP FS
  Result := Unimplemented('PsQueryStatistics');
  EmuSwapFS(); // Xbox FS
end;

function {257} xboxkrnl_PsSetCreateThreadNotifyRoutine(
  NotifyRoutine: PCREATE_THREAD_NOTIFY_ROUTINE
  ): NTSTATUS; stdcall; // Source: ReactOS
begin
  EmuSwapFS(); // Win2k/XP FS
  Result := Unimplemented('PsSetCreateThreadNotifyRoutine');
  EmuSwapFS(); // Xbox FS
end;

// PsTerminateSystemThread:
// Exits the current system thread.  Must be called from a system thread.
//
// Differences from NT: None.

function {258} xboxkrnl_PsTerminateSystemThread(
  ExitStatus: NTSTATUS
  ): NTSTATUS; stdcall; // Source : XBMC
begin
  EmuSwapFS(); // Win2k/XP FS
  Result := Unimplemented('PsTerminateSystemThread');
  EmuSwapFS(); // Xbox FS
end;

end.