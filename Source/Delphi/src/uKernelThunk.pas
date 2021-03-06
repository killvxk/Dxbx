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
unit uKernelThunk;

{$INCLUDE Dxbx.inc}

interface

uses
  // Delphi
  Windows, // for ULONG
  Types, // for DWord
  SysUtils, // for IntToStr
  // OpenXdk
  XboxKrnl,
  // Dxbx
  uTypes,
  uDxbxUtils,
  uEmuKrnl,
  uEmuKrnlAv,
  uEmuKrnlDbg,
  uEmuKrnlEx,
  uEmuKrnlFs,
  uEmuKrnlHal,
  uEmuKrnlIo,
  uEmuKrnlKd,
  uEmuKrnlKe,
  uEmuKrnlMm,
  uEmuKrnlNt,
  uEmuKrnlOb,
  uEmuKrnlPs,
  uEmuKrnlRtl,
  uEmuKrnlXbox,
  uEmuKrnlXc,
  uEmuKrnlXe;

var
  // Dxbx note : Thunks reviewed using http://www.remnantmods.com/archive/applications/Halo%202%20Xbox%20Apps/Yelo%20Debugger/Yelo%20Debugger/YeloDebug/XboxKernel.cs
  KernelThunkTable: array [0..NUMBER_OF_THUNKS - 1] of Pointer = (
    {000}@xboxkrnl_UnknownAPI000,
    {001}@xboxkrnl_AvGetSavedDataAddress,
    {002}@xboxkrnl_AvSendTVEncoderOption,
    {003}@xboxkrnl_AvSetDisplayMode,
    {004}@xboxkrnl_AvSetSavedDataAddress,
    {005}@xboxkrnl_DbgBreakPoint,
    {006}@xboxkrnl_DbgBreakPointWithStatus,
    {007}@xboxkrnl_DbgLoadImageSymbols,
    {008}@xboxkrnl_DbgPrint,
    {009}@xboxkrnl_HalReadSMCTrayState,
    {010}@xboxkrnl_DbgPrompt,
    {011}@xboxkrnl_DbgUnLoadImageSymbols,
    {012}@xboxkrnl_ExAcquireReadWriteLockExclusive,
    {013}@xboxkrnl_ExAcquireReadWriteLockShared,
    {014}@xboxkrnl_ExAllocatePool,
    {015}@xboxkrnl_ExAllocatePoolWithTag,
    {016}@xboxkrnl_ExEventObjectType, // variable
    {017}@xboxkrnl_ExFreePool,
    {018}@xboxkrnl_ExInitializeReadWriteLock,
    {019}@xboxkrnl_ExInterlockedAddLargeInteger,
    {020}@xboxkrnl_ExInterlockedAddLargeStatistic,
    {021}@xboxkrnl_ExInterlockedCompareExchange64,
    {022}@xboxkrnl_ExMutantObjectType, // variable
    {023}@xboxkrnl_ExQueryPoolBlockSize,
    {024}@xboxkrnl_ExQueryNonVolatileSetting,
    {025}@xboxkrnl_ExReadWriteRefurbInfo,
    {026}@xboxkrnl_ExRaiseException,
    {027}@xboxkrnl_ExRaiseStatus,
    {028}@xboxkrnl_ExReleaseReadWriteLock,
    {029}@xboxkrnl_ExSaveNonVolatileSetting,
    {030}@xboxkrnl_ExSemaphoreObjectType, // variable
    {031}@xboxkrnl_ExTimerObjectType, // variable
    {032}@xboxkrnl_ExfInterlockedInsertHeadList,
    {033}@xboxkrnl_ExfInterlockedInsertTailList,
    {034}@xboxkrnl_ExfInterlockedRemoveHeadList,
    {035}@xboxkrnl_FscGetCacheSize,
    {036}@xboxkrnl_FscInvalidateIdleBlocks,
    {037}@xboxkrnl_FscSetCacheSize,
    {038}@xboxkrnl_HalClearSoftwareInterrupt,
    {039}@xboxkrnl_HalDisableSystemInterrupt,
    {040}@xboxkrnl_HalDiskCachePartitionCount, // variable. A.k.a. "IdexDiskPartitionPrefixBuffer"
    {041}@xboxkrnl_HalDiskModelNumber, // variable
    {042}@xboxkrnl_HalDiskSerialNumber, // variable
    {043}@xboxkrnl_HalEnableSystemInterrupt,
    {044}@xboxkrnl_HalGetInterruptVector,
    {045}@xboxkrnl_HalReadSMBusValue,
    {046}@xboxkrnl_HalReadWritePCISpace,
    {047}@xboxkrnl_HalRegisterShutdownNotification,
    {048}@xboxkrnl_HalRequestSoftwareInterrupt,
    {049}@xboxkrnl_HalReturnToFirmware,
    {050}@xboxkrnl_HalWriteSMBusValue,
    {051}@xboxkrnl_InterlockedCompareExchange,
    {052}@xboxkrnl_InterlockedDecrement,
    {053}@xboxkrnl_InterlockedIncrement,
    {054}@xboxkrnl_InterlockedExchange,
    {055}@xboxkrnl_InterlockedExchangeAdd,
    {056}@xboxkrnl_InterlockedFlushSList,
    {057}@xboxkrnl_InterlockedPopEntrySList,
    {058}@xboxkrnl_InterlockedPushEntrySList,
    {059}@xboxkrnl_IoAllocateIrp,
    {060}@xboxkrnl_IoBuildAsynchronousFsdRequest,
    {061}@xboxkrnl_IoBuildDeviceIoControlRequest,
    {062}@xboxkrnl_IoBuildSynchronousFsdRequest,
    {063}@xboxkrnl_IoCheckShareAccess,
    {064}@xboxkrnl_IoCompletionObjectType, // variable
    {065}@xboxkrnl_IoCreateDevice,
    {066}@xboxkrnl_IoCreateFile,
    {067}@xboxkrnl_IoCreateSymbolicLink,
    {068}@xboxkrnl_IoDeleteDevice,
    {069}@xboxkrnl_IoDeleteSymbolicLink,
    {070}@xboxkrnl_IoDeviceObjectType, // variable
    {071}@xboxkrnl_IoFileObjectType, // variable
    {072}@xboxkrnl_IoFreeIrp,
    {073}@xboxkrnl_IoInitializeIrp,
    {074}@xboxkrnl_IoInvalidDeviceRequest,
    {075}@xboxkrnl_IoQueryFileInformation,
    {076}@xboxkrnl_IoQueryVolumeInformation,
    {077}@xboxkrnl_IoQueueThreadIrp,
    {078}@xboxkrnl_IoRemoveShareAccess,
    {079}@xboxkrnl_IoSetIoCompletion,
    {080}@xboxkrnl_IoSetShareAccess,
    {081}@xboxkrnl_IoStartNextPacket,
    {082}@xboxkrnl_IoStartNextPacketByKey,
    {083}@xboxkrnl_IoStartPacket,
    {084}@xboxkrnl_IoSynchronousDeviceIoControlRequest,
    {085}@xboxkrnl_IoSynchronousFsdRequest,
    {086}@xboxkrnl_IofCallDriver,
    {087}@xboxkrnl_IofCompleteRequest,
    {088}@xboxkrnl_KdDebuggerEnabled, // variable
    {089}@xboxkrnl_KdDebuggerNotPresent, // variable
    {090}@xboxkrnl_IoDismountVolume,
    {091}@xboxkrnl_IoDismountVolumeByName,
    {092}@xboxkrnl_KeAlertResumeThread,
    {093}@xboxkrnl_KeAlertThread,
    {094}@xboxkrnl_KeBoostPriorityThread,
    {095}@xboxkrnl_KeBugCheck,
    {096}@xboxkrnl_KeBugCheckEx,
    {097}@xboxkrnl_KeCancelTimer,
    {098}@xboxkrnl_KeConnectInterrupt,
    {099}@xboxkrnl_KeDelayExecutionThread,
    {100}@xboxkrnl_KeDisconnectInterrupt,
    {101}@xboxkrnl_KeEnterCriticalRegion,
    {102}@xboxkrnl_MmGlobalData, // variable
    {103}@xboxkrnl_KeGetCurrentIrql,
    {104}@xboxkrnl_KeGetCurrentThread,
    {105}@xboxkrnl_KeInitializeApc,
    {106}@xboxkrnl_KeInitializeDeviceQueue,
    {107}@xboxkrnl_KeInitializeDpc,
    {108}@xboxkrnl_KeInitializeEvent,
    {109}@xboxkrnl_KeInitializeInterrupt,
    {110}@xboxkrnl_KeInitializeMutant,
    {111}@xboxkrnl_KeInitializeQueue,
    {112}@xboxkrnl_KeInitializeSemaphore,
    {113}@xboxkrnl_KeInitializeTimerEx,
    {114}@xboxkrnl_KeInsertByKeyDeviceQueue,
    {115}@xboxkrnl_KeInsertDeviceQueue,
    {116}@xboxkrnl_KeInsertHeadQueue,
    {117}@xboxkrnl_KeInsertQueue,
    {118}@xboxkrnl_KeInsertQueueApc,
    {119}@xboxkrnl_KeInsertQueueDpc,
    {120}nil, //@xboxkrnl_KeInterruptTime, //variable
    {121}@xboxkrnl_KeIsExecutingDpc,
    {122}@xboxkrnl_KeLeaveCriticalRegion,
    {123}@xboxkrnl_KePulseEvent,
    {124}@xboxkrnl_KeQueryBasePriorityThread,
    {125}@xboxkrnl_KeQueryInterruptTime,
    {126}@xboxkrnl_KeQueryPerformanceCounter,
    {127}@xboxkrnl_KeQueryPerformanceFrequency,
    {128}@xboxkrnl_KeQuerySystemTime,
    {129}@xboxkrnl_KeRaiseIrqlToDpcLevel,
    {130}@xboxkrnl_KeRaiseIrqlToSynchLevel,
    {131}@xboxkrnl_KeReleaseMutant,
    {132}@xboxkrnl_KeReleaseSemaphore,
    {133}@xboxkrnl_KeRemoveByKeyDeviceQueue,
    {134}@xboxkrnl_KeRemoveDeviceQueue,
    {135}@xboxkrnl_KeRemoveEntryDeviceQueue,
    {136}@xboxkrnl_KeRemoveQueue,
    {137}@xboxkrnl_KeRemoveQueueDpc,
    {138}@xboxkrnl_KeResetEvent,
    {139}@xboxkrnl_KeRestoreFloatingPointState,
    {140}@xboxkrnl_KeResumeThread,
    {141}@xboxkrnl_KeRundownQueue,
    {142}@xboxkrnl_KeSaveFloatingPointState,
    {143}@xboxkrnl_KeSetBasePriorityThread,
    {144}@xboxkrnl_KeSetDisableBoostThread,
    {145}@xboxkrnl_KeSetEvent,
    {146}@xboxkrnl_KeSetEventBoostPriority,
    {147}@xboxkrnl_KeSetPriorityProcess,
    {148}@xboxkrnl_KeSetPriorityThread,
    {149}@xboxkrnl_KeSetTimer,
    {150}@xboxkrnl_KeSetTimerEx,
    {151}@xboxkrnl_KeStallExecutionProcessor,
    {152}@xboxkrnl_KeSuspendThread,
    {153}@xboxkrnl_KeSynchronizeExecution,
    {154}nil, //@xboxkrnl_KeSystemTime, //variable
    {155}@xboxkrnl_KeTestAlertThread,
    {156}@xboxkrnl_KeTickCount, // variable
    {157}@xboxkrnl_KeTimeIncrement, // variable
    {158}@xboxkrnl_KeWaitForMultipleObjects,
    {159}@xboxkrnl_KeWaitForSingleObject,
    {160}@xboxkrnl_KfRaiseIrql,
    {161}@xboxkrnl_KfLowerIrql,
    {162}@xboxkrnl_KiBugCheckData, // variable
    {163}@xboxkrnl_KiUnlockDispatcherDatabase,
    {164}@xboxkrnl_LaunchDataPage, // variable
    {165}@xboxkrnl_MmAllocateContiguousMemory,
    {166}@xboxkrnl_MmAllocateContiguousMemoryEx,
    {167}@xboxkrnl_MmAllocateSystemMemory,
    {168}@xboxkrnl_MmClaimGpuInstanceMemory,
    {169}@xboxkrnl_MmCreateKernelStack,
    {170}@xboxkrnl_MmDeleteKernelStack,
    {171}@xboxkrnl_MmFreeContiguousMemory,
    {172}@xboxkrnl_MmFreeSystemMemory,
    {173}@xboxkrnl_MmGetPhysicalAddress,
    {174}@xboxkrnl_MmIsAddressValid,
    {175}@xboxkrnl_MmLockUnlockBufferPages,
    {176}@xboxkrnl_MmLockUnlockPhysicalPage,
    {177}@xboxkrnl_MmMapIoSpace,
    {178}@xboxkrnl_MmPersistContiguousMemory,
    {179}@xboxkrnl_MmQueryAddressProtect,
    {180}@xboxkrnl_MmQueryAllocationSize,
    {181}@xboxkrnl_MmQueryStatistics,
    {182}@xboxkrnl_MmSetAddressProtect,
    {183}@xboxkrnl_MmUnmapIoSpace,
    {184}@xboxkrnl_NtAllocateVirtualMemory,
    {185}@xboxkrnl_NtCancelTimer,
    {186}@xboxkrnl_NtClearEvent,
    {187}@xboxkrnl_NtClose,
    {188}@xboxkrnl_NtCreateDirectoryObject,
    {189}@xboxkrnl_NtCreateEvent,
    {190}@xboxkrnl_NtCreateFile,
    {191}@xboxkrnl_NtCreateIoCompletion,
    {192}@xboxkrnl_NtCreateMutant,
    {193}@xboxkrnl_NtCreateSemaphore,
    {194}@xboxkrnl_NtCreateTimer,
    {195}@xboxkrnl_NtDeleteFile,
    {196}@xboxkrnl_NtDeviceIoControlFile,
    {197}@xboxkrnl_NtDuplicateObject,
    {198}@xboxkrnl_NtFlushBuffersFile,
    {199}@xboxkrnl_NtFreeVirtualMemory,
    {200}@xboxkrnl_NtFsControlFile,
    {201}@xboxkrnl_NtOpenDirectoryObject,
    {202}@xboxkrnl_NtOpenFile,
    {203}@xboxkrnl_NtOpenSymbolicLinkObject,
    {204}@xboxkrnl_NtProtectVirtualMemory,
    {205}@xboxkrnl_NtPulseEvent,
    {206}@xboxkrnl_NtQueueApcThread,
    {207}@xboxkrnl_NtQueryDirectoryFile,
    {208}@xboxkrnl_NtQueryDirectoryObject,
    {209}@xboxkrnl_NtQueryEvent,
    {210}@xboxkrnl_NtQueryFullAttributesFile,
    {211}@xboxkrnl_NtQueryInformationFile,
    {212}@xboxkrnl_NtQueryIoCompletion,
    {213}@xboxkrnl_NtQueryMutant,
    {214}@xboxkrnl_NtQuerySemaphore,
    {215}@xboxkrnl_NtQuerySymbolicLinkObject,
    {216}@xboxkrnl_NtQueryTimer,
    {217}@xboxkrnl_NtQueryVirtualMemory,
    {218}@xboxkrnl_NtQueryVolumeInformationFile,
    {219}@xboxkrnl_NtReadFile,
    {220}@xboxkrnl_NtReadFileScatter,
    {221}@xboxkrnl_NtReleaseMutant,
    {222}@xboxkrnl_NtReleaseSemaphore,
    {223}@xboxkrnl_NtRemoveIoCompletion,
    {224}@xboxkrnl_NtResumeThread,
    {225}@xboxkrnl_NtSetEvent,
    {226}@xboxkrnl_NtSetInformationFile,
    {227}@xboxkrnl_NtSetIoCompletion,
    {228}@xboxkrnl_NtSetSystemTime,
    {229}@xboxkrnl_NtSetTimerEx,
    {230}@xboxkrnl_NtSignalAndWaitForSingleObjectEx,
    {231}@xboxkrnl_NtSuspendThread,
    {232}@xboxkrnl_NtUserIoApcDispatcher,
    {233}@xboxkrnl_NtWaitForSingleObject,
    {234}@xboxkrnl_NtWaitForSingleObjectEx,
    {235}@xboxkrnl_NtWaitForMultipleObjectsEx,
    {236}@xboxkrnl_NtWriteFile,
    {237}@xboxkrnl_NtWriteFileGather,
    {238}@xboxkrnl_NtYieldExecution,
    {239}@xboxkrnl_ObCreateObject,
    {240}@xboxkrnl_ObDirectoryObjectType, // variable
    {241}@xboxkrnl_ObInsertObject,
    {242}@xboxkrnl_ObMakeTemporaryObject,
    {243}@xboxkrnl_ObOpenObjectByName,
    {244}@xboxkrnl_ObOpenObjectByPointer,
    {245}@xboxkrnl_ObpObjectHandleTable, // variable
    {246}@xboxkrnl_ObReferenceObjectByHandle,
    {247}@xboxkrnl_ObReferenceObjectByName,
    {248}@xboxkrnl_ObReferenceObjectByPointer,
    {249}@xboxkrnl_ObSymbolicLinkObjectType, // variable
    {250}@xboxkrnl_ObfDereferenceObject,
    {251}@xboxkrnl_ObfReferenceObject,
    {252}@xboxkrnl_PhyGetLinkState,
    {253}@xboxkrnl_PhyInitialize,
    {254}@xboxkrnl_PsCreateSystemThread,
    {255}@xboxkrnl_PsCreateSystemThreadEx,
    {256}@xboxkrnl_PsQueryStatistics,
    {257}@xboxkrnl_PsSetCreateThreadNotifyRoutine,
    {258}@xboxkrnl_PsTerminateSystemThread,
    {259}@xboxkrnl_PsThreadObjectType,
    {260}@xboxkrnl_RtlAnsiStringToUnicodeString,
    {261}@xboxkrnl_RtlAppendStringToString,
    {262}@xboxkrnl_RtlAppendUnicodeStringToString,
    {263}@xboxkrnl_RtlAppendUnicodeToString,
    {264}@xboxkrnl_RtlAssert,
    {265}@xboxkrnl_RtlCaptureContext,
    {266}@xboxkrnl_RtlCaptureStackBackTrace,
    {267}@xboxkrnl_RtlCharToInteger,
    {268}@xboxkrnl_RtlCompareMemory,
    {269}@xboxkrnl_RtlCompareMemoryUlong,
    {270}@xboxkrnl_RtlCompareString,
    {271}@xboxkrnl_RtlCompareUnicodeString,
    {272}@xboxkrnl_RtlCopyString,
    {273}@xboxkrnl_RtlCopyUnicodeString,
    {274}@xboxkrnl_RtlCreateUnicodeString,
    {275}@xboxkrnl_RtlDowncaseUnicodeChar,
    {276}@xboxkrnl_RtlDowncaseUnicodeString,
    {277}@xboxkrnl_RtlEnterCriticalSection,
    {278}@xboxkrnl_RtlEnterCriticalSectionAndRegion,
    {279}@xboxkrnl_RtlEqualString,
    {280}@xboxkrnl_RtlEqualUnicodeString,
    {281}@xboxkrnl_RtlExtendedIntegerMultiply,
    {282}@xboxkrnl_RtlExtendedLargeIntegerDivide,
    {283}@xboxkrnl_RtlExtendedMagicDivide,
    {284}@xboxkrnl_RtlFillMemory,
    {285}@xboxkrnl_RtlFillMemoryUlong,
    {286}@xboxkrnl_RtlFreeAnsiString,
    {287}@xboxkrnl_RtlFreeUnicodeString,
    {288}@xboxkrnl_RtlGetCallersAddress,
    {289}@xboxkrnl_RtlInitAnsiString,
    {290}@xboxkrnl_RtlInitUnicodeString,
    {291}@xboxkrnl_RtlInitializeCriticalSection,
    {292}@xboxkrnl_RtlIntegerToChar,
    {293}@xboxkrnl_RtlIntegerToUnicodeString,
    {294}@xboxkrnl_RtlLeaveCriticalSection,
    {295}@xboxkrnl_RtlLeaveCriticalSectionAndRegion,
    {296}@xboxkrnl_RtlLowerChar,
    {297}@xboxkrnl_RtlMapGenericMask,
    {298}@xboxkrnl_RtlMoveMemory,
    {299}@xboxkrnl_RtlMultiByteToUnicodeN,
    {300}@xboxkrnl_RtlMultiByteToUnicodeSize,
    {301}@xboxkrnl_RtlNtStatusToDosError,
    {302}@xboxkrnl_RtlRaiseException,
    {303}@xboxkrnl_RtlRaiseStatus,
    {304}@xboxkrnl_RtlTimeFieldsToTime,
    {305}@xboxkrnl_RtlTimeToTimeFields,
    {306}@xboxkrnl_RtlTryEnterCriticalSection,
    {307}@xboxkrnl_RtlUlongByteSwap,
    {308}@xboxkrnl_RtlUnicodeStringToAnsiString,
    {309}@xboxkrnl_RtlUnicodeStringToInteger,
    {310}@xboxkrnl_RtlUnicodeToMultiByteN,
    {311}@xboxkrnl_RtlUnicodeToMultiByteSize,
    {312}@xboxkrnl_RtlUnwind,
    {313}@xboxkrnl_RtlUpcaseUnicodeChar,
    {314}@xboxkrnl_RtlUpcaseUnicodeString,
    {315}@xboxkrnl_RtlUpcaseUnicodeToMultiByteN,
    {316}@xboxkrnl_RtlUpperChar,
    {317}@xboxkrnl_RtlUpperString,
    {318}@xboxkrnl_RtlUshortByteSwap,
    {319}@xboxkrnl_RtlWalkFrameChain,
    {320}@xboxkrnl_RtlZeroMemory,
    {321}@xboxkrnl_XboxEEPROMKey, // variable
    {322}@xboxkrnl_XboxHardwareInfo, // variable
    {323}@xboxkrnl_XboxHDKey, // variable
    {324}@xboxkrnl_XboxKrnlVersion, // variable
    {325}@xboxkrnl_XboxSignatureKey, // variable
    {326}@xboxkrnl_XeImageFileName, // variable
    {327}@xboxkrnl_XeLoadSection,
    {328}@xboxkrnl_XeUnloadSection,
    {329}@xboxkrnl_READ_PORT_BUFFER_UCHAR,
    {330}@xboxkrnl_READ_PORT_BUFFER_USHORT,
    {331}@xboxkrnl_READ_PORT_BUFFER_ULONG,
    {332}@xboxkrnl_WRITE_PORT_BUFFER_UCHAR,
    {333}@xboxkrnl_WRITE_PORT_BUFFER_USHORT,
    {334}@xboxkrnl_WRITE_PORT_BUFFER_ULONG,
    {335}@xboxkrnl_XcSHAInit,
    {336}@xboxkrnl_XcSHAUpdate,
    {337}@xboxkrnl_XcSHAFinal,
    {338}@xboxkrnl_XcRC4Key,
    {339}@xboxkrnl_XcRC4Crypt,
    {340}@xboxkrnl_XcHMAC,
    {341}@xboxkrnl_XcPKEncPublic,
    {342}@xboxkrnl_XcPKDecPrivate,
    {343}@xboxkrnl_XcPKGetKeyLen,
    {344}@xboxkrnl_XcVerifyPKCS1Signature,
    {345}@xboxkrnl_XcModExp,
    {346}@xboxkrnl_XcDESKeyParity,
    {347}@xboxkrnl_XcKeyTable,
    {348}@xboxkrnl_XcBlockCrypt,
    {349}@xboxkrnl_XcBlockCryptCBC,
    {350}@xboxkrnl_XcCryptService,
    {351}@xboxkrnl_XcUpdateCrypto,
    {352}@xboxkrnl_RtlRip,
    {353}@xboxkrnl_XboxLANKey, // variable
    {354}@xboxkrnl_XboxAlternateSignatureKeys, // variable
    {355}@xboxkrnl_XePublicKeyData, // variable
    {356}@xboxkrnl_HalBootSMCVideoMode, // variable
    {357}@xboxkrnl_IdexChannelObject, // variable
    {358}@xboxkrnl_HalIsResetOrShutdownPending,
    {359}@xboxkrnl_IoMarkIrpMustComplete,
    {360}@xboxkrnl_HalInitiateShutdown,
    {361}@xboxkrnl_RtlSnprintf,
    {362}@xboxkrnl_RtlSprintf,
    {363}@xboxkrnl_RtlVsnprintf,
    {364}@xboxkrnl_RtlVsprintf,
    {365}@xboxkrnl_HalEnableSecureTrayEject,
    {366}@xboxkrnl_HalWriteSMCScratchRegister,
    {367}@xboxkrnl_UnknownAPI367,
    {368}@xboxkrnl_UnknownAPI368,
    {369}@xboxkrnl_UnknownAPI369,
    {370}@xboxkrnl_UnknownAPI370, // XProfpControl
    {371}@xboxkrnl_UnknownAPI371, // XProfpGetData
    {372}@xboxkrnl_UnknownAPI372, // IrtClientInitFast
    {373}@xboxkrnl_UnknownAPI373, // IrtSweep
    {374}@xboxkrnl_MmDbgAllocateMemory,
    {375}@xboxkrnl_MmDbgFreeMemory, // Returns number of pages released.
    {376}@xboxkrnl_MmDbgQueryAvailablePages,
    {377}@xboxkrnl_MmDbgReleaseAddress,
    {378}@xboxkrnl_MmDbgWriteCheck
    );

implementation

procedure ConnectWindowsTimersToThunkTable();
begin
  // Couple the xbox thunks for xboxkrnl_KeInterruptTime and xboxkrnl_KeSystemTime
  // to their actual counterparts on Windows, this way we won't have to spend any
  // time on updating them ourselves, and still get highly accurate timers!
  // See http://www.dcl.hpi.uni-potsdam.de/research/WRK/2007/08/getting-os-information-the-kuser_shared_data-structure/

  xboxkrnl_KeInterruptTimePtr := DxbxNtSystemTime;
  xboxkrnl_KeSystemTimePtr := DxbxNtInterruptTime;

  KernelThunkTable[120] := xboxkrnl_KeInterruptTimePtr;
  KernelThunkTable[154] := xboxkrnl_KeSystemTimePtr;

  // Note that we can't do the same for TickCount, as that timer
  // updates slower on the xbox. See EmuThreadUpdateTickCount().
end;

initialization

  ConnectWindowsTimersToThunkTable();

end.
