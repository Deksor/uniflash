unit AMIBios; { Unit to use AMI's flash interface when exists }
{ This interface is used to help the flash utility to prepare the system
for a BIOS upgrade. It can be found in all new AMI WinBIOSes. These functions
are common to every chipset.
Uniflash can use these functions if user wants or when chipset is unknown and
the BIOS is a recent AMIBIOS}

interface
function AMICheckFor : boolean;
function AMISaveChipsetState : boolean;
function AMIRestoreChipsetState : boolean;
function AMILowerVpp : boolean;
function AMIRaiseVpp : boolean;
function AMIFlashProtect : boolean;
function AMIFlashUNProtect : boolean;
function AMISaveCacheState : boolean;
function AMIRestoreCacheState : boolean;

procedure AMIEnable;          {MAP}
procedure AMIDisable;         {UNMAP}
implementation
uses Dos;

var
   reg : registers;
   CSMemory : array[0..4095] of byte;
   Cache : array[0..16384] of byte;

procedure AMICallFunction(Fnc : Byte; var Regs : Registers);
begin
 Regs.AH:=$E0;
 Regs.AL:=Fnc;
 Intr($16,Regs);
end;

function AMICheckFor : Boolean;
begin
 AMICheckFor:=False;
 AMICallFunction($00,Reg);
 if (Reg.AL = $fA) and (Reg.BX>=$0200) then AMICheckFor:=True;
end;


function AMISaveChipsetState : Boolean;
begin
 AMISaveChipsetState:=False;
 Reg.ES:=Seg(CSMemory);
 Reg.DI:=Ofs(CSMemory);
 AMICallFunction($02,Reg);
 if (Reg.Flags and FCarry = 0) then AMISaveChipsetState:=True;
end;

function AMIRestoreChipsetState : Boolean;
begin
 AMIRestoreChipsetState:=False;
 Reg.ES:=Seg(CSMemory);
 Reg.DI:=Ofs(CSMemory);
 AMICallFunction($03,Reg);
 if (Reg.Flags and FCarry = 0) then AMIRestoreChipsetState:=True;
end;


function AMILowerVpp : Boolean;
begin
 AMILowerVpp:=False;
 AMICallFunction($04,Reg);
 if (Reg.Flags and FCarry = 0) then AMILowerVpp:=True;
end;

function AMIRaiseVpp : Boolean;
begin
 AMIRaiseVpp:=False;
 AMICallFunction($05,Reg);
 if (Reg.Flags and FCarry = 0) then AMIRaiseVpp:=True;
end;

function AMIFlashProtect : Boolean;
begin
 AMIFlashProtect:=False;
 AMICallFunction($06,Reg);
 if (Reg.Flags and FCarry = 0) then AMIFlashProtect:=True;
end;

function AMIFlashUNProtect : Boolean;
begin
 AMIFlashUnProtect:=False;
 AMICallFunction($07,Reg);
 if (Reg.Flags and FCarry = 0) then AMIFlashUnProtect:=True;
end;

function AMISaveCacheState : Boolean;
begin
 AMISaveCacheState:=False;
 Reg.ES:=Seg(Cache);
 Reg.DI:=Ofs(Cache);
 AMICallFunction($0B,Reg);
 if (Reg.Flags and FCarry = 0) then AMISaveCacheState:=True;
end;

function AMIRestoreCacheState : Boolean;
begin
 AMIRestoreCacheState:=False;
 Reg.ES:=Seg(Cache);
 Reg.DI:=Ofs(Cache);
 AMICallFunction($0C,Reg);
 if (Reg.Flags and FCarry = 0) then AMIRestoreCacheState:=True;
end;



procedure AMIEnable;
begin
 if Not AMICheckFor then Exit;
 AMISaveChipsetState;
 AMISaveCacheState;
 AMIRaiseVpp;
 AMIFlashUnprotect;
end;

procedure AMIDisable;
begin
 if Not AMICheckFor then Exit;
 AMIRestoreChipsetState;
 AMIRestoreCacheState;
 AMILowerVpp;
 AmiFlashProtect;
end;


end.