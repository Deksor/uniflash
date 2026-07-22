
Unit AMIBios; { Unit to use AMI's flash interface when exists }


{ This interface is used to help the flash utility to prepare the system
for a BIOS upgrade. It can be found in all new AMI WinBIOSes. These functions
are common to every chipset.
Uniflash can use these functions if user wants and the BIOS is recent AMIBIOS}

Interface
Function AMICheckFor : boolean;
Function AMISaveChipsetState : boolean;
Function AMIRestoreChipsetState : boolean;
Function AMILowerVpp : boolean;
Function AMIRaiseVpp : boolean;
Function AMIFlashProtect : boolean;
Function AMIFlashUNProtect : boolean;
Function AMISaveCacheState : boolean;
Function AMIRestoreCacheState : boolean;

Procedure AMIEnable;          {MAP}
Procedure AMIDisable;         {UNMAP}

Implementation

Uses Dos;

Var 
  reg : registers;
  CSMemory : array[0..4095] Of byte;
  Cache : array[0..16384] Of byte;

Procedure AMICallFunction(Fnc : Byte; Var Regs : Registers);
Begin
  Regs.AH := $E0;
  Regs.AL := Fnc;
  Intr($16,Regs);
End;

Function AMICheckFor : Boolean;
Begin
  AMICheckFor := False;
  AMICallFunction($00,Reg);
  If (Reg.AL = $fA) And (Reg.BX>=$0200) Then AMICheckFor := True;
End;


Function AMISaveChipsetState : Boolean;
Begin
  AMISaveChipsetState := False;
  Reg.ES := Seg(CSMemory);
  Reg.DI := Ofs(CSMemory);
  AMICallFunction($02,Reg);
  If (Reg.Flags And FCarry = 0) Then AMISaveChipsetState := True;
End;

Function AMIRestoreChipsetState : Boolean;
Begin
  AMIRestoreChipsetState := False;
  Reg.ES := Seg(CSMemory);
  Reg.DI := Ofs(CSMemory);
  AMICallFunction($03,Reg);
  If (Reg.Flags And FCarry = 0) Then AMIRestoreChipsetState := True;
End;


Function AMILowerVpp : Boolean;
Begin
  AMILowerVpp := False;
  AMICallFunction($04,Reg);
  If (Reg.Flags And FCarry = 0) Then AMILowerVpp := True;
End;

Function AMIRaiseVpp : Boolean;
Begin
  AMIRaiseVpp := False;
  AMICallFunction($05,Reg);
  If (Reg.Flags And FCarry = 0) Then AMIRaiseVpp := True;
End;

Function AMIFlashProtect : Boolean;
Begin
  AMIFlashProtect := False;
  AMICallFunction($06,Reg);
  If (Reg.Flags And FCarry = 0) Then AMIFlashProtect := True;
End;

Function AMIFlashUNProtect : Boolean;
Begin
  AMIFlashUnProtect := False;
  AMICallFunction($07,Reg);
  If (Reg.Flags And FCarry = 0) Then AMIFlashUnProtect := True;
End;

Function AMISaveCacheState : Boolean;
Begin
  AMISaveCacheState := False;
  Reg.ES := Seg(Cache);
  Reg.DI := Ofs(Cache);
  AMICallFunction($0B,Reg);
  If (Reg.Flags And FCarry = 0) Then AMISaveCacheState := True;
End;

Function AMIRestoreCacheState : Boolean;
Begin
  AMIRestoreCacheState := False;
  Reg.ES := Seg(Cache);
  Reg.DI := Ofs(Cache);
  AMICallFunction($0C,Reg);
  If (Reg.Flags And FCarry = 0) Then AMIRestoreCacheState := True;
End;



Procedure AMIEnable;
Begin
  If Not AMICheckFor Then Exit;
  AMISaveChipsetState;
  AMISaveCacheState;
  AMIRaiseVpp;
  AMIFlashUnprotect;
End;

Procedure AMIDisable;
Begin
  If Not AMICheckFor Then Exit;
  AMIRestoreChipsetState;
  AMIRestoreCacheState;
  AMILowerVpp;
  AmiFlashProtect;
End;

{begin}
End.
