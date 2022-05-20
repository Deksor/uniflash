unit amibios; { Unit to use AMI's flash interface when exists }
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
uses dos;

var
   reg : registers;
   CSMemory : array[0..4095] of byte;
   Cache : array[0..16384] of byte;

Procedure AMICallFunction(fnc : byte; var regs : registers);
begin
regs.ah:=$E0;
regs.al:=fnc;
intr($16,regs);
end;

function AMICheckFor : boolean;
begin
AMICheckFor:=false;
AMICallFunction($00,reg);
if (reg.al = $fa) and (reg.bx>=$0200) then AMICheckFor:=True;
end;


function AMISaveChipsetState : boolean;
begin
AMISaveChipsetState:=false;
reg.es:=seg(CSMemory);
reg.di:=ofs(CSMemory);
AMICallFunction($02,reg);
if (reg.flags and fcarry = 0) then AMISaveChipsetState:=true;
end;

function AMIRestoreChipsetState : boolean;
begin
AMIRestoreChipsetState:=false;
reg.es:=seg(CSMemory);
reg.di:=ofs(CSMemory);
AMICallFunction($03,reg);
if (reg.flags and fcarry = 0) then AMIRestoreChipsetState:=true;
end;


function AMILowerVpp : boolean;
begin
AMILowerVpp:=false;
AMICallFunction($04,reg);
if (reg.flags and fcarry = 0) then AMILowerVpp:=true;
end;

function AMIRaiseVpp : boolean;
begin
AMIRaiseVpp:=false;
AMICallFunction($05,reg);
if (reg.flags and fcarry = 0) then AMIRaiseVpp:=true;
end;

function AMIFlashProtect : boolean;
begin
AMIFlashProtect:=false;
AMICallFunction($06,reg);
if (reg.flags and fcarry = 0) then AMIFlashProtect:=true;
end;

function AMIFlashUNProtect : boolean;
begin
AMIFlashUnProtect:=false;
AMICallFunction($07,reg);
if (reg.flags and fcarry = 0) then AMIFlashUnProtect:=true;
end;

function AMISaveCacheState : boolean;
begin
AMISaveCacheState:=false;
reg.es:=seg(Cache);
reg.di:=ofs(Cache);
AMICallFunction($0B,reg);
if (reg.flags and fcarry = 0) then AMISaveCacheState:=true;
end;

function AMIRestoreCacheState : boolean;
begin
AMIRestoreCacheState:=false;
reg.es:=seg(Cache);
reg.di:=ofs(Cache);
AMICallFunction($0C,reg);
if (reg.flags and fcarry = 0) then AMIRestoreCacheState:=true;
end;



procedure AMIEnable;
begin
if Not AMICheckFor then exit;
AMISaveChipsetState;
AMISaveCacheState;
AMIRaiseVpp;
AMIFlashUnprotect;
end;

procedure AMIDisable;
begin
if Not AMICheckFor then exit;
AMIRestoreChipsetState;
AMIRestoreCacheState;
AMILowerVpp;
AmiFlashProtect;
end;


end.