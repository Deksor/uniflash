{$M 16384, 0, 16384}
{$I-}
{$S-}
{$R-}
{$G+}
Program Uniflash;

Uses Crt, Dos,
     Flash, PCI, PCICards, Tools, GenFlash, CT_Flash,
     Intel, Atmel, SST, Winbond, AMD, Catalyst, Macronix, AMIC, Alliance,
     ISSI, Mosel, EON, PMC, Hyundai, IMT, ST, TI, Fujitsu, SHARP,
     Language, English{, French, Dutch, Italian, German};


Const
Emergency   : Boolean = False;
PCIROMEn    : Boolean = False;
PCIROM      : Boolean = False;
CTFlash     : Boolean = False; {v1.32}
SaveBIOS    : Boolean = False;
ForceId     : Boolean = False;
CMOS        : Boolean = False;
Quit        : Boolean = False;
Repair      : Boolean = False;
Reboot      : Boolean = False;
BaseForced  : LongInt = 0;

Var
M,D,Z,X,Y,
Count       : Byte; {v1.22}
Int         : Integer;
BIOSBlk     : ARRAY[ 0 .. 32767 ] of Byte;
FlashName   : ^String;
OldExitProc : Pointer;
OldBIOS,
NewBIOS     : LongInt;
FlashBase,
FlashSize   : LongInt;
X2,Y2       : Longint;
AdvMenu,
{PnPDMIMenu,}
CMOSMenu,   {v1.22}
MainMenu    : PMenuItem;
FlashInfo   : PChipInfo;
VErr, Redir : Boolean; {v1.22}
SelA, A     : Char;
IFile       : File;
CMOSImg,
CMOSBack    : ARRAY[ $0E .. $FF ] of Byte;
Img,
PCIReg4,
PCIReg30,
ScanPos,
MaxBlock,
TempBuf     : LongInt;
SStarts     : ARRAY[ 0 .. 512 ] of LongInt; {38 -> 512 v1.21}
PCIROMCnt,
CMOSSize    : Byte;
EMFName,
SaveName, {v1.36}
PStr        : String[ 127 ];
AnswYes,
AnswNo      : Char;
StdOut      : Text;
StdOutRec   : TextRec absolute StdOut;
ForceIdVal  : Word;
SaveDir     : String; {v1.28}

Function AskFor2(L : Byte;Txt : String) : Boolean;
Var X,Y,X2,Y2 : Byte;
    Answer : Char;
Begin
 AskFor2:=True;
 X:=WhereX;
 Y:=WhereY;
 GotoXY(13,Y+1+l);
 Write(Txt);
 repeat
  Answer:=UpCase( _ReadKey );
 until ( Answer = AnswYes ) or ( Answer = AnswNo );
 AskFor2:= Answer = AnswYes;
 WriteLn;
 X2:=WhereX;
 Y2:=WhereY;
 GotoXY(13,Y+1+l);
 ClrEol;
 GotoXY(X,Y);
end;

Function AskFor(L : Byte;Txt : String) : Boolean;
Var X,Y : Byte;

begin
 X:=WhereX;
 Y:=WhereY;
 AskFor := AskFor2( L, Txt );
 GotoXY( X,Y );
end;

procedure ErrorMsg(Message:String); {v1.28}
begin
  GotoXY(1,20);
  ClrEol;
  GotoXY(18,20);
  Write(Message);
  Delay(2000);
  GotoXY(1,20);
  ClrEol;
end;

function IOError:Boolean; {v1.28}
var Error:byte;
    Message:String;
begin
  IOError:=False;
  Error:=IOResult;
  if Error=0 then Exit;
  IOError:=True;
  Message:='Error #'+IntToStr(Error)+': ';
  case Error of
     2,18: Message:=Message+'File not found.';
        3: Message:=Message+'Path not found.';
        4: Message:=Message+'Too many open files.';
        5: Message:=Message+'Access denied.';
        6: Message:=Message+'Invalid file handle.';
       15: Message:=Message+'Drive error.';
   19,150: Message:=Message+'Disk is write protected.';
       20: Message:=Message+'Unknown drive.';
   21,152: Message:=Message+'Drive is not ready.';
       23: Message:=Message+'CRC Error.';
       25: Message:=Message+'Seek error.';
       26: Message:=Message+'Unknown media type.';
       27: Message:=Message+'Sector not found.';
      100: Message:=Message+'Disk read error.';
      101: Message:=Message+'Disk full.';
      103: Message:=Message+'File is not open.';
      183: Message:=Message+'File is open in read-only mode.';
  else Message:=Message+'Unknown Error.';
  end;
  ErrorMsg(Message);
end;

Procedure FlashBlock( Block, Start, Size : LongInt );
Var
S,
X, Pos  : LongInt;
UpdStat,
NxtUpd  : Word;
Sector  : Boolean;
W       : Byte;
SPos,Y,Z: Word; {v1.34}
SaveCR0 : LongInt;

Begin
 {Disable cache, avoid problems on Cyrix systems}
 Asm
  DB    0FH, 20H, 00H  {MOV EAX,CR0}
  DB    66H
  MOV   WORD PTR SaveCR0,AX
  DB    66H
  OR    AX,0
  DW    6000H
  DB    0FH, 22H, 00H  {MOV CR0,EAX}
  DB    0FH,09H        {WBINVD}
 End;

 Sector := ( FlashInfo^.Flags and 1 ) = 0;
 Pos := 0;

 Start := Start{ + FlashBase}; {v1.29}
 If Sector then
  Begin
   X := {FlashBase}0; {v1.29}
   SPos := 1;
   SStarts[ 0 ] := X;
   If ( ( FlashInfo^.Flags ) and 2 ) = 0 then
    Begin
     {Make list with sector ends & sizes (=next sector starts)}
     With FlashInfo^ do
      For W := 1 to 1{Count} do
       For Y := 0 to 4 do {v1.21 3->4}
        If Sectors[ Y, 0 ] = 0 then Break else
        For Z := 1 to Sectors[ Y, 0 ] do
         Begin
(*          X := X + ( LongInt( Sectors[ Y, 1 ] ) + 1 ) shl 11; {*2K}*)
          X := X + LongInt( Sectors[ Y, 1 ] ) shl 7; {*128} {v1.21}
          SStarts[ SPos ] := X;
          Inc( SPos );
         End;
    End else
    Begin
     {Bulk erase chip}
     For W := 1 to {FlashInfo^.Count}1 do
      Begin
       X := X + ( FlashSize {div FlashInfo^.Count} );
       SStarts[ SPos ] := X;
       Inc( SPos );
      End;
     {Might need blanking prior to erase}
     If ( FlashInfo^.Flags and 4 ) <> 0 then
      Begin
       WrtProgressBar( Msg( 1 ) );
       FillLinBlockD( TempBuf, FlashInfo^.PgSize, 0 );
       UpdStat := ( FlashSize div FlashInfo^.PgSize + 31 ) shr 5;
       NxtUpd := UpdStat;
       For X := 0 to ( FlashSize div FlashInfo^.PgSize ) - 1 do
        Begin
         Dec( NxtUpd );
         If NxtUpd = 0 then
          Begin
           if FlashError=0 then TextColor(Green) else TextColor(Red);
           Write( 'Û' );
           NxtUpd := UpdStat;
          End;
         FlashProgram( {FlashBase +} X, TempBuf ); {v1.29}
        End;
      End;
    End;
   WrtProgressBar( Msg( 2 ) );
   SPos := 0;
   While Start >= SStarts[ SPos + 1 ] do Inc( SPos ); {Find starting sector}

   {Calculate the actual size in bytes we physically need to write}
   X := SStarts[ SPos ];
   S := ( SStarts[ SPos + 1 ] - Start );
   Y := SPos + 1;
   While ( S < Size ) and ( (Size-S) >= (SStarts[Y+1] - SStarts[Y] ) ) do
    Begin
     S := S + ( SStarts[ Y + 1 ] - SStarts[ Y ] );
     Inc( Y );
    End;
   If S <> Size then Inc( Y );
   X := SStarts[ Y ] - X;
   {And use physical size to calculate status bar values}
   UpdStat := ( X div FlashInfo^.PgSize + 31 ) shr 5;
   NxtUpd := UpdStat;

   {Write first unaligned and/or partial sector if necessary}
   S := SStarts[ SPos + 1 ] - SStarts[ SPos ];
   If ( Start <> SStarts[ SPos ] ) or
      ( Size < S ) then
    Begin
     MoveLinBlockD( SStarts[ SPos ],
                    TempBuf, S );
     S := S - ( Start - SStarts[ SPos ] );
     If S > Size then S := Size;
     MoveLinBlockD( Block, TempBuf + ( Start - SStarts[ SPos ] ), S );

     FlashErase( SStarts[ SPos ] );  {Clear sector}
     For X := 0 to ( ( SStarts[ SPos + 1 ] -
                       SStarts[ SPos ] ) div FlashInfo^.PgSize ) - 1 do
      Begin
       Dec( NxtUpd );
       If NxtUpd = 0 then
        Begin
         if FlashError=0 then TextColor(Green) else TextColor(Red);
         Write( 'Û' );
         NxtUpd := UpdStat;
        End;
       FlashProgram( SStarts[ SPos ] + ( X * FlashInfo^.PgSize ),
                     TempBuf + ( X * FlashInfo^.PgSize ) );
      End;
     Inc( SPos );
     Pos := SStarts[ SPos ] - Start;
    End;

   {Copy aligned sectors}
   While ( Pos < Size ) and
         ( ( Size - Pos ) >= ( SStarts[ SPos + 1 ] - SStarts[ SPos ] ) ) do
    Begin
     FlashErase( SStarts[ SPos ] );  {Clear sector}
     For X := 0 to ( ( SStarts[ SPos + 1 ] -
                       SStarts[ SPos ] ) div FlashInfo^.PgSize ) - 1 do
      Begin
       Dec( NxtUpd );
       If NxtUpd = 0 then
        Begin
         if FlashError=0 then TextColor(Green) else TextColor(Red);
         Write( 'Û' );
         NxtUpd := UpdStat;
        End;
       FlashProgram( SStarts[ SPos ] + ( X * FlashInfo^.PgSize ), Block + Pos );
       Pos := Pos + FlashInfo^.PgSize;
      End;
     Inc( SPos );
    End;

   {Write last partial sector if necessary}
   S := SStarts[ SPos + 1 ] - SStarts[ SPos ];
   If ( Pos <> Size ) then
    Begin
     MoveLinBlockD( SStarts[ SPos ],
                    TempBuf, S );
     MoveLinBlockD( Block + Pos, TempBuf, Size - Pos );
     FlashErase( SStarts[ SPos ] );  {Clear sector}
     For X := 0 to ( ( SStarts[ SPos + 1 ] -
                       SStarts[ SPos ] ) div FlashInfo^.PgSize ) - 1 do
      Begin
       Dec( NxtUpd );
       If NxtUpd = 0 then
        Begin
         if FlashError=0 then TextColor(Green) else TextColor(Red);
         Write( 'Û' );
         NxtUpd := UpdStat;
        End;
       FlashProgram( SStarts[ SPos ] + ( X * FlashInfo^.PgSize ),
                     TempBuf + ( X * FlashInfo^.PgSize ) );
      End;
    End;
  End else
  Begin
   UpdStat := ( Size div FlashInfo^.PgSize + 31 ) shr 5;
   NxtUpd := UpdStat;
   WrtProgressBar( Msg( 2 ) );

   {Write first unaligned and/or partial page if necessary}
   If ( ( Start and ( FlashInfo^.PgSize - 1 ) ) <> 0 )
      or ( Size < 128 ) then
    Begin
     MoveLinBlockD( Start and not ( FlashInfo^.PgSize - 1 ),
                    TempBuf, FlashInfo^.PgSize );
     S := FlashInfo^.PgSize - ( Start and ( FlashInfo^.PgSize - 1 ) );
     If S > Size then S := Size;
     MoveLinBlockD( Block, TempBuf + ( Start and ( FlashInfo^.PgSize - 1 ) ), S );
     FlashProgram( Start and not ( FlashInfo^.PgSize - 1 ), TempBuf );
     Pos := S;
    End;

   {Copy aligned pages}
   While ( Pos < Size ) and
         ( ( Size - Pos ) >= FlashInfo^.PgSize ) do
    Begin
     Dec( NxtUpd );
     If NxtUpd = 0 then
      Begin
       if FlashError=0 then TextColor(Green) else TextColor(Red);
       Write( 'Û' );
       NxtUpd := UpdStat;
      End;
     FlashProgram( Start + Pos, Block + Pos );
     Pos := Pos + FlashInfo^.PgSize;
    End;

   {Write last partial page if necessary}
   If Pos <> Size then
    Begin
     S := Size - Pos;
     MoveLinBlockD( Start + Pos,TempBuf, FlashInfo^.PgSize );
     MoveLinBlockD( Block + Pos, TempBuf, S );
     FlashProgram( Start + Pos, TempBuf );
     Pos := S;
    End;
  End;


 {Restore CR0}
 Asm
  DB    66H
  MOV   AX,WORD PTR SaveCR0
  DB    0FH, 22H, 00H  {MOV CR0,EAX}
 End;
End;

Procedure FlashBIOSImg( BIOS, Start, Size : LongInt );
Var
X : LongInt;

Begin
 Repeat
  FlashBlock( BIOS, Start, Size );
  LogWrite('Flashing '+_Str(Size)+'b long BIOS image to '+_Str(Start)); {v1.23}
  WrtProgressBar( Msg( 3 ) );
  VErr := False;
  For X := 0 to 31 do
   Begin
    If (Flash_Compare(X*(FlashSize shr 5)+Start,
                      X*(FlashSize shr 5)+BIOS, FlashSize shr 5)) {v1.29}
     and (X*(FlashSize shr 5)<Size)
     then Write( 'Û' ) else
      if X*(FlashSize shr 5)>=Size then Write('±') else
       Begin
        Write( 'X' );
        VErr := True;
       End;
   End;
  If VErr then
   Begin
    Text_Color( 12 );
    GotoXY( 2, 22 );
    If Emergency then Sound( 1000 ) else Write( #7 );
    Write( Msg( 4 ) );
    Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
    If Emergency then NoSound;
    GotoXY( 11, 22 );
    ClrEol;
   End;
 Until ( not VErr ) or ( A = AnswNo );
 if not VErr then {v1.22}
  Begin
   Beep(  500, 100 );
   Beep( 1000, 100 );
   Beep( 1500, 100 );
   LogWrite('Flashing completed successfully'); {v1.23}
  End;
 ClearProgressBar;
 if VErr then LogWrite('Flashing failed'); {v1.23}
End;


function FlashFile( Var IFile : File; BB : Boolean ):Boolean; {function-v1.28}
Var
X, Pos : LongInt;

Begin
 FlashFile:=True;
 if BB then LogWrite('Flashing BIOS including BootBlock')
  else LogWrite('Flashing BIOS without BootBlock'); {v1.23}
 X := 0;
 While ( X < FileSize( IFile ) ) do
  Begin
   BlockRead( IFile, BIOSBlk, 32768 );
   if IOError then {v1.28}
    begin
      FlashFile:=False;
      ErrorMsg(Msg(64));
      Exit;
    end;
   MoveLinBlockD( ( LongInt( Seg( BIOSBlk ) ) shl 4 ) + LongInt( Ofs( BIOSBlk ) ), X + NewBIOS, 32768 );
   X := X + 32768;
  End;

 If Emergency then
  Begin
   Delay( 1000 );
   Beep( 1000, 500 ); {2nd single beep: start flashing}
  End;

 Pos := FlashSize - FileSize( IFile );
 If BB then
  FlashBIOSImg( NewBIOS, Pos, FileSize( IFile ) )
 else
  Begin
   If not Emergency and
      not Flash_Compare(FlashSize-8192,NewBios+FlashSize-8192,8192) then {v1.29}
    Begin
     Text_Color( 12 );
     GotoXY( 2, 22 );
     Write( Msg( 5 ) );
     Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
     GotoXY( 2, 22 );
     ClrEol;
     If A = AnswNo then
      Begin
       GotoXY( 2, 20 );
       ClrEol;
       FlashFile:=False;
       Exit;
      End;
     Write( Msg( 49 ) ); {v1.30}
     Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
     GotoXY( 2, 22 );
     ClrEol;
     If A = AnswNo then
      Begin
{       GotoXY( 2, 20 );
       ClrEol;
       FlashFile:=False;
       Exit;}
       FlashBIOSImg( NewBIOS, Pos, FileSize( IFile ) - 8192 );
      End else FlashBIOSImg( NewBIOS, Pos, FileSize( IFile ) );
    End
   else FlashBIOSImg( NewBIOS, Pos, FileSize( IFile ) - 8192 );
  End;
 SetMenuItemStatus( MainMenu, 2, True );
End;


{Write old BIOS image to file with user supplied name}
Procedure WriteBIOSImg; Far;
Var
IName : String;
IFile : File;
X     : LongInt;

Begin
 If SaveBIOS then IName := SaveName else
  Begin
   GotoXY( 18, 20 );
   Write( Msg( 6 ) );
   FInput(IName,'backup.bin',45); {v1.28}
  End;

 If IName <> '' then
  Begin
   Assign( IFile, IName );
   Rewrite( IFile, 1 );
   If IOError then
    Begin
     ErrorMsg(Msg(7)+IName+Msg(95));
     Exit;
    End;

   X := 0;
   While ( X < FlashSize ) do
    Begin
     MoveLinBlockD( X + OldBIOS, LongInt(  Seg( BIOSBlk ) ) shl 4 + LongInt( Ofs( BIOSBlk ) ), 32768 );
     BlockWrite( IFile, BIOSBlk, 32768 );
     if IOError then {v1.28}
      begin
        ErrorMsg(Msg(65));
        Close(IFile);
        IOError;
        Exit;
      end;
     X := X + 32768;
    End;

   Close( IFile );
   IOError;
   LogWrite('BIOS image saved to file '+IName); {v1.23}
  End;

 GotoXY( 11, 20 );
 ClrEol;
End;


{Flash BIOS from file to ROM}
Procedure _FlashBIOS( BB : Boolean );
Var
IName : String;
X     : LongInt;
A     : Char;
Done  : Boolean; {v1.28}

Begin
 GotoXY( 18, 20 );
 Write( Msg( 6 ) );
 FInput(IName,'',45); {v1.28}
 If IName <> '' then
  Begin
   Assign( IFile, IName );
   Reset( IFile, 1 );
   If IOError then
    Begin
     ErrorMsg(Msg(8)+IName+Msg(95));
     Exit;
    End;
   If FileSize( IFile ) <> FlashSize then
    Begin
     Text_Color( 12 );
     GotoXY( 11, 22 );
     Write( Msg( 9 ) );
     Delay(2000); {v1.33}
{     Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );}
     GotoXY( 11, 22 );
     ClrEol;
     GotoXY( 11, 20 );
     ClrEol;
     Close( IFile );
     IOError;
     Exit;
    End;
   If BB then
    Begin
     Text_Color(LightRed);
     GotoXY( 11, 22 );
     Write( Msg( 10 ) );
     Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
     GotoXY( 11, 22 );
     Text_Color(LightGray);
     ClrEol;
     If A = AnswNo then
      Begin
       GotoXY( 11, 20 );
       ClrEol;
       Close( IFile );
       IOError;
       Exit;
      End;
    End;

   Done:=FlashFile( IFile, BB );
   Close( IFile );
   IOError;
   if Done then {v1.28}
    begin
      GotoXY( 32, 8 );
      ClrEol;
      GotoXY( 32, 8 );
      If VErr then
       Begin
        Text_Color( LightRed );
        Write( Msg( 11 ) );
       End else
       Begin
        Text_Color( LightGreen );
        Write( Msg( 12 ) );
       End;
    end;
  End else
  Begin
   GotoXY( 11, 20 );
   ClrEol;
  End;
End;

Procedure FlashBIOS; Far;
Begin
 _FlashBIOS( False );
End;

Procedure FlashBIOSBB; Far;
Begin
 _FlashBIOS( True );
End;

{Flash 4K PnP or DMI block to flash ROM}
(*Procedure FlashPnPDMI( Typ : String; Pos : LongInt );
Var
IName : String;
X     : LongInt;
A     : Char;

Begin
 GotoXY( 18, 20 );
 Write( Typ + Msg( 13 ) );
 FInput(IName,'',45); {v1.28}
 If IName <> '' then
  Begin
   Assign( IFile, IName );
   Reset( IFile, 1 );
   If IOError then
    Begin
     ErrorMsg(Msg(8)+IName+Msg(95));
     Exit;
    End;
   If FileSize( IFile ) <> 4096 then
    Begin
     ErrorMsg(Msg(14));
     Close( IFile );
     IOError;
     Exit;
    End;
   BlockRead( IFile, BIOSBlk, 4096 );
   if IOError then {v1.28}
    begin
      ErrorMsg(Msg(64));
      Exit;
    end;
   if not AskFor(0, Msg( 15 ) ) then
    begin
      Close(IFile);
      IOError;
      GotoXY( 11, 20 );
      ClrEol;
      Exit;
    end;
   LogWrite('Flashing '+Typ+' data from '+IName); {v1.23}
   FlashBIOSImg( ( LongInt( Seg( BIOSBlk ) ) shl 4 ) + LongInt( Ofs( BIOSBlk ) ),
                 Pos{ - FlashBase}, 4096 ); {v1.29}
   SetMenuItemStatus( MainMenu, 2, True );
   Close( IFile );
   IOError;
   GotoXY( 32, 8 );
   ClrEol;
   GotoXY( 32, 8 );
   If VErr then
    Begin
     Text_Color( LightRed );
     Write( Msg( 11 ) );
    End else
    Begin
     Text_Color( LightGreen );
     Write( Msg( 12 ) );
    End;
  End else
  Begin
   GotoXY( 11, 20 );
   ClrEol;
  End;
End;

{Flash PnP data from file to ROM}
Procedure FlashPnP; Far;
Begin
 FlashPnPDMI( 'PnP',{ $FFFFD000}FlashSize-$3000 ); {v1.29}
End;*)

(*{Flash DMI data from file to ROM}
Procedure FlashDMI; Far;
Begin
 FlashPnPDMI( 'DMI',{ $FFFFC000}FlashSize-$4000 );
End;*)

(*Procedure ClearPnPDMI( Typ : String; Pos : LongInt );
Begin
 Text_Color( 12 );
 GotoXY( 11, 22 );
 Write( Msg( 16 ), Typ, Msg( 17 ) );
 Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
 GotoXY( 11, 22 );
 ClrEol;
 If A = AnswYes then
  Begin
   LogWrite('Clearing '+Typ+' data in Flash ROM'); {v1.23}
   FillChar( BIOSBlk, 4096, $FF );
   FlashBIOSImg( ( LongInt( Seg( BIOSBlk ) ) shl 4 ) + LongInt( Ofs( BIOSBlk ) ),
                 Pos{ - FlashBase}, 4096 ); {v1.29}
   SetMenuItemStatus( MainMenu, 2, True );
   GotoXY( 32, 8 );
   ClrEol;
   GotoXY( 32, 8 );
   If VErr then
    Begin
     Text_Color( LightRed );
     Write( Msg( 11 ) );
    End else
    Begin
     Text_Color( LightGreen );
     Write( Msg( 12 ) );
    End;
  End;
End;

Procedure ClearPnP; Far;
Begin
 ClearPnPDMI( 'PNP',{ $FFFFD000}FlashSize-$3000 ); {v1.29}
End;*)

(*Procedure ClearDMI; Far;
Begin
 ClearPnPDMI( 'DMI',{ $FFFFC000}FlashSize-$4000 );
End;*)

(*Procedure WritePnPDMIImg( Typ : String; Pos : LongInt );
Var
IName : String;
IFile : File;
X     : LongInt;

Begin
 GotoXY( 18, 20 );
 Write( Msg( 97 ) + Typ + Msg( 18 ) );
 FInput(IName,'backup.pnp',45); {v1.28}
 if IName<>'' then {v1.28}
  begin
    Assign( IFile, IName );
    Rewrite( IFile, 1 );
    If IOError then
     Begin
      ErrorMsg(Msg(7)+IName+' !'#7);
      Exit;
     End;

    Flash_ReadBlock(Pos,LongInt(Seg(BIOSBlk)) shl 4+LongInt(Ofs(BIOSBlk)),4096); {v1.29}
    BlockWrite( IFile, BIOSBlk, 4096 );
    if IOError then {v1.28}
    begin
      ErrorMsg(Msg(65));
      Close(IFile);
      IOError;
      Exit;
    end;
    Close( IFile );
    IOError;
    LogWrite(Typ+' data saved to '+IName); {v1.23}
  end;
 GotoXY( 11, 20 );
 ClrEol;
End;

Procedure WritePnP; Far;
Begin
 WritePnPDMIImg( 'PnP',{ $FFFFD000 }FlashSize-$3000); {v1.29}
End;*)

(*Procedure WriteDMI; Far;
Begin
 WritePnPDMIImg( 'DMI',{ $FFFFC000 }FlashSize-$4000);
End;*)

Procedure WriteBootBlk; Far;
Var
IName : String;
IFile : File;

Begin
 GotoXY( 18, 20 );
 Write( Msg( 19 ) );
 FInput(IName,'backup.boo',45); {v1.28}
 if IName<>'' then {v1.28}
  begin
    Assign( IFile, IName );
    Rewrite( IFile, 1 );
    If IOError then
     Begin
      ErrorMsg(Msg(7)+IName+' !'#7);
      Exit;
     End;
    Flash_ReadBlock(FlashSize-8192,LongInt(Seg(BIOSBlk)) shl 4+LongInt(Ofs(BIOSBlk)),8192); {v1.29}
    BlockWrite( IFile, BIOSBlk, 8192 );
    if IOError then {v1.28}
    begin
      ErrorMsg(Msg(65));
      Close(IFile);
      IOError;
      Exit;
    end;
    Close( IFile );
    IOError;
    LogWrite('BootBlock backup saved to '+IName);
  end;
 GotoXY( 11, 20 );
 ClrEol;
End;

Procedure FlashBootBlk; Far;
Var
IName : String;
X     : LongInt;
A     : Char;

Begin
 GotoXY( 18, 20 );
 Write( Msg( 19 ) );
 FInput(IName,'',45); {v1.28}
 If IName <> '' then
  Begin
   Assign( IFile, IName );
   Reset( IFile, 1 );
   If IOError then
    Begin
     ErrorMsg(Msg(8)+IName+' !'#7);
     Exit;
    End;
   If FileSize( IFile ) <> 8192 then
    Begin
     ErrorMsg(Msg(96));
     Close( IFile );
     IOError;
     Exit;
    End;
   Text_Color( 12 );
   GotoXY( 11, 22 );
   Write( Msg( 10 ) );
   Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
   GotoXY( 11, 22 );
   ClrEol;
   If A = AnswNo then
    Begin
     GotoXY( 11, 20 );
     ClrEol;
     Close( IFile );
     IOError;
     Exit;
    End;

   BlockRead( IFile, BIOSBlk, 8192 );
   if IOError then {v1.28}
    begin
      ErrorMsg(Msg(64));
      Close(IFile);
      IOError;
      Exit;
    end;
   LogWrite('Flashing BootBlock from '+IName); {v1.23}
   FlashBIOSImg( ( LongInt( Seg( BIOSBlk ) ) shl 4 ) + LongInt( Ofs( BIOSBlk ) ),
                { $FFFFE000 - FlashBase}FlashSize-8192, 8192 ); {v1.29}
   SetMenuItemStatus( MainMenu, 2, True );
   Close( IFile );
   IOError;
   GotoXY( 32, 8 );
   ClrEol;
   GotoXY( 32, 8 );
   If VErr then
    Begin
     Text_Color( LightRed );
     Write( Msg( 11 ) );
    End else
    Begin
     Text_Color( LightGreen );
     Write( Msg( 12 ) );
    End;
  End else
  Begin
   GotoXY( 11, 20 );
   ClrEol;
  End;
End;

{Flash BIOS backup back into flash chip}
Procedure FlashOldBIOS; Far;
Begin
 Text_Color( 12 );
 GotoXY( 11, 22 );
 Write( Msg( 20 ) );
 Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
 GotoXY( 11, 22 );
 ClrEol;
 If A = AnswYes then
  Begin
   LogWrite('Flashing backup BIOS to Flash ROM'); {v1.23}
   FlashBIOSImg( OldBIOS, 0, FlashSize{ - 8192 });
   SetMenuItemStatus( MainMenu, 2, False );
  End;
End;

Function GetCMOSSize : Byte;
Var
X, S1, S2 : Byte;

Begin
 GetCMOSSize:=127;

 {Backup values $10 and $50}
 Port[$70]:=$10;
 S1:=Port[$71];
 Port[$70]:=$50;
 S2:=Port[$71];
 if S1=S2 then {If they are different then it is definately 128 bytes}
  begin
    {Change $50, read back at $10}
    Port[$70]:=$50;
    Port[$71]:=S1 xor $55;
    Port[$70]:=$10;
    X:=Port[$71];
    {Write back old values}
    Port[$70]:=$10;
    Port[$71]:=S1;
    Port[$70]:=$50;
    Port[$71]:=S2;

    {If value read back is same as value written then we only have 64 bytes}
    if X=(S1 xor $55) then
     begin
       GetCMOSSize:=63;
       Exit;
     end;
  end;

 Port[$70]:=$10;
 S1:=Port[$71];
 Port[$72]:=$90; {v1.36}
 S2:=Port[$73];
 Port[$70]:=$10;
 Port[$71]:=$55;
 Port[$72]:=$90; {v1.36}
 Port[$73]:=$AA;
 Port[$70]:=$10;
 if Port[$71]=$55 then {v1.29}
  begin
   Port[$72]:=$90; {v1.36}
   if Port[$73]=$AA then GetCMOSSize:=255;
  end;
 Port[$70]:=$10;
 Port[$71]:=S1;
 Port[$72]:=$90; {v1.36}
 Port[$73]:=S2;
End;

function CMOSClr:Boolean;
var X,Z:Byte;
    OK:Boolean;
begin
 Z:=CMOSSize;
 if Z>127 then Z:=127;
 {Clear it}
 for X:=$0E to Z do
  begin
   Port[$70]:=X;
   Port[$71]:=$00;
  end;
 if CMOSSize>Z then
  begin
   for X:=$80 to $FF do
    begin
     Port[$72]:=X;
     Port[$73]:=$00;
    end;
  end;
 {Verify}
 OK:=True;
 for X:=$0E to Z do
  begin
   Port[$70]:=X;
   if Port[$71]<>$00 then OK:=False;
  end;
 if CMOSSize>Z then
  for X:=$80 to $FF do
   begin
    Port[$72]:=X;
    if Port[$73]<>$00 then OK:=False;
   end;
 if not OK then
  begin
   Write(Msg(24));
   Delay(2000);
  end;
 CMOSClr:=OK;
end;

{Clear CMOS ram area}
Procedure ClearCMOS; Far;
Begin
 Text_Color( 12 );
 GotoXY( 2, 22 );
 Write( Msg( 21 ) );
 Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
 GotoXY( 2, 22 );
 ClrEol;
 If A = AnswYes then
  Begin
   Text_Color(LightRed);
   GotoXY(11,22);
   if CMOSClr then
    begin
     Write(Msg(22),CMOSSize+1,Msg(23));
     Delay(1000);
     LogWrite('CMOS settings cleared');
    end
   else LogWrite('Error clearing CMOS settings - may be write protected');
   GotoXY(11,22);
   ClrEol;
   SetMenuItemStatus( CMOSMenu, 3, True ); {v1.33}
  End;
End;

procedure CMOSWrite(var IFile:file); {v1.25}
var X,Z:Byte;
begin
 Z:=CMOSSize;
 if Z>127 then Z:=127;
 for X:=$0E to Z do
  begin
   Port[$70]:=X;
   CMOSImg[X]:=Port[$71];
  end;
 if CMOSSize>Z then
  for X:=$80 to $FF do
   begin
    Port[$72]:=X;
    CMOSImg[X]:=Port[$73];
   end;
 BlockWrite(IFile,CMOSImg,CMOSSize-$0D);
 if IOError then {v1.28}
 begin
   ErrorMsg(Msg(65));
   Exit;
 end;
end;

{Write CMOS data to disk}
Procedure SaveCMOS; Far;
Var
IName : String;
IFile : File;

Begin
 GotoXY( 18, 20 );
 Write( Msg( 97 ) + 'CMOS' + Msg( 18 ) );
 FInput(IName,'backup.cmo',45); {v1.28}
 if IName<>'' then {v1.28}
  begin
    Assign( IFile, IName );
    Rewrite( IFile, 1 );
    If IOError then
     Begin
      ErrorMsg(Msg(7)+IName+' !'#7);
      Exit;
     End;
    CMOSWrite(IFile);
    Close( IFile );
    IOError;
    LogWrite('CMOS settings saved to '+IName); {v1.23}
  end;
 GotoXY( 11, 20 );
 ClrEol;
End;

function CMOSRestore(var IFile:File):Boolean; {v1.25}
var X,Z:Byte;
    OK:Boolean;
begin
 Z:=CMOSSize;
 if Z>127 then Z:=127;
 BlockRead(IFile,CMOSImg,CMOSSize-$0D);
 if IOError then {v1.28}
  begin
    ErrorMsg(Msg(64));
    Exit;
  end;
 for X:=$0E to Z do
  begin
   Port[$70]:=X;
   Port[$71]:=CMOSImg[X];
  end;
 if CMOSSize>Z then
  for X:=$80 to $FF do
   begin
    Port[$72]:=X;
    Port[$73]:=CMOSImg[X];
   end;
 OK:=True;
 for X:=$0E to Z do
  begin
   Port[$70]:=X;
   if Port[$71]<>CMOSImg[X] then OK:=False;
  end;
 if CMOSSize>Z then
  for X:=$80 to $FF do
   begin
    Port[$72]:=X;
    if Port[$73]<>CMOSImg[X] then OK:=False;
   end;
 if not OK then
  Begin
   Text_Color(LightRed);
   GotoXY(11,22);
   Write(Msg(26));
   Delay(2000);
   GotoXY(11,22);
   ClrEol;
  End;
 CMOSRestore:=OK;
end;

{Read CMOS data from disk}
Procedure RestoreCMOS; Far;
Var
IName : String;
IFile : File;

Begin
 GotoXY( 18, 20 );
 Write( Msg( 97 ) + 'CMOS' + Msg( 18 ) );
 FInput(IName,'',45); {v1.28}
 If IName <> '' then
  Begin
   Assign( IFile, IName );
   Reset( IFile, 1 );
   If IOError then
    Begin
     ErrorMsg(Msg(8)+IName+' !'#7);
     Exit;
    End;
   If FileSize( IFile ) <> ( CMOSSize - $0D ) then
    Begin
     GotoXY( 11, 20 );
     Write( Msg( 98 ), CMOSSize - $0D, Msg( 99 ) );
     Delay( 2000 );
     GotoXY( 11, 20 );
     ClrEol;
     Close( IFile );
     IOError;
     Exit;
    End;
   if CMOSRestore(IFile) then LogWrite('CMOS settings restored from '+IName)
    else LogWrite('Error restoring CMOS settings - may be write protected');
   Close( IFile );
   IOError;
   SetMenuItemStatus( CMOSMenu, 3, True ); {v1.33}
  End;
 GotoXY( 11, 20 );
 ClrEol;
End;


Procedure WrtOldCMOS; Far;
var X,Z:Byte;
    OK:Boolean;

Begin
 Text_Color( 12 );
 GotoXY( 11, 22 );
 Write( Msg( 27 ) );
 repeat A:=UpCase(_ReadKey) until (A=AnswYes) or (A=AnswNo);
 GotoXY( 11, 22 );
 ClrEol;
 if A=AnswYes then
  Begin
   Z:=CMOSSize;
   if Z>127 then Z:=127;
   for X:=$0E to Z do
    begin
     Port[$70]:=X;
     Port[$71]:=CMOSBack[X];
    end;
   if CMOSSize>Z then
    for X:=$80 to $FF do
     begin
      Port[$72]:=X;
      Port[$73]:=CMOSBack[X];
     end;
   {Verify}
   OK:=True;
   for X:=$0E to Z do
    begin
     Port[$70]:=X;
     if Port[$71]<>CMOSBack[X] then OK:=False;
    end;
   if CMOSSize>Z then
    for X:=$80 to $FF do
     begin
      Port[$72]:=X;
      if Port[$73]<>CMOSBack[X] then OK:=False;
     end;
   Text_Color(12);
   GotoXY(11,22);
   if OK then
    begin
     Write(CMOSSize-$0D,Msg(28));
     Delay(1000);
    end
   else
    begin
     Write(Msg(26));
     _ReadKey;
    end;
   GotoXY(11,22);
   ClrEol;
  End;
 SetMenuItemStatus( CMOSMenu, 3, False ); {v1.33}
 LogWrite('CMOS settings restored from backup in memory'); {v1.23}
End;

Procedure MyExitProc; Far;
Begin
 LogWrite('Exiting UniFlash...');
 If PCIROMEn then
  Begin
   SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04, PCIReg4 );
   SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, PCIReg30 );
   PCIROMEnable(False);
  End;
 Text_Color( LightGray );
 RomEnable( False );
 LogWrite('Turning off logging, shutting down to real mode');
 LogEnd;
 FlatRealOff;
 ExitProc := OldExitProc;
 Y := WhereY;
 Window( 1, WhereY, 80, 25 );
 Text_Color( 7 );
 Text_BackGround( 0 );
 ClrScr;
 Window( 1, 1, 80, 25 );
 GotoXY( 1, Y );
 ClrKbBuf; {v1.27}
 ChDir(SaveDir);
End;

Procedure WrtCenter( Msg : String );
Begin
 WriteLn( '        ' + Msg );
End;

Procedure Err( Msg : String );
Begin
 WriteLn;
 WriteLn;
 Text_Color(lightred);
 LogWrite( Msg ); {v1.23}
 WrtCenter( #7 + Msg );
 Text_Color(lightgray);
 If Emergency then Sound( 1000 );
 halt(0);
End;

Function OpStr( S : String ) : String;
Var
X : Byte;

Begin
 If ( Length( S ) > 1 ) and ( ( S[ 1 ] = '-' ) or ( S[ 1 ] = '/' ) ) then
  Begin
   For X := 1 to Length( S ) do S[ X ] := UpCase( S[ X ] );
   OpStr := Copy( S, 2, Length( S ) - 1 );
  End else OpStr := '';
End;

procedure CheckRedir; {v1.22}
var A:Byte;
Begin
  A:=WhereX;
  Write(StdOut,' ');
  Redir:=WhereX=A;
End;

function WriteLnStd(S:String):Boolean; {v1.22}
var A:Char;
begin
  Inc( Count );
  if not Redir and ( Count >= Hi( WindMax ) ) then
   Begin
    Write( '-- More --' );
    A:=_ReadKey;
    if (UpCase(A)='Q') or (A=#27) then begin WriteLnStd:=False; Exit; end; {v1.24}
    WriteLn;
    Count:=0;
   End;
  WriteLn( StdOut, S );
  WriteLnStd:=True;
end;

procedure MemInit; {v1.24}
begin
 InitXMS; {Init memory subsystem. Should be done before FlatRealOn}
 If XMSLeft = -1 then Err( Msg( 37 ) );

 If not FlatRealOn then
  Err( Msg( 38 ) ) else LogWrite('Flat Real Mode initialized'); {v1.23}

 {Allocate high memory if XMS not present}
 AllocHimem;
end;

procedure ROMSelect; {v1.24}
begin
{ ROMBase :=0 ;}  {standard system BIOS flag for detectloop}
 ROMBase:=BaseForced;

(*If PCI ROM mode then scan for & select PCI ROM
  NOTE: This is all experimental and uses a technique that
        I think will not be encouraged by the PCI SIG. It may
        cause problems with PCI cards with a shared memory
        controller (like local memory corruption ...)
        Use the PCIROM switch at your own risk ... *)
 If PCIROM then
  Begin
   PCIROMCnt := 0;

   if (PCIROMBus<>0) or (PCIROMDev<>0) or (PCIROMFun<>0) then {v1.27}
    begin
      Asm CLI End;
      PCIReg4 := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04 );     {Save reg 4}
      SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04, PCIReg4 or $02 ); {Enable memory}
      PCIReg30 := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30 );     {Save reg 30}
      SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, $FFFFFFFF );  {Check for stuck 0's}
      Img := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30 );
      SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, $00000001 );  {Check for stuck 1's}
      Img := Img xor GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30 ); {Now every 0 is a hw bit}
      For Z := 1 to 32 do If ( Img and ( 1 shl LongInt( Z ) ) ) <> 0 then Break;
      If ( Z < 32 ) and ( ( Img xor ( - ( 1 shl LongInt( Z ) ) ) ) = 0 ) then
       Begin
        Inc( PCIROMCnt );
        With PCIROMs[ PCIROMCnt ] do
         Begin
          MaxSize := 1 shl LongInt( Z );
          VenID := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $00 );
          DevID := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $00 ) shr 16;
          Bus := PCIROMBus;
          Pos := ( PCIROMDev shl 3 ) or PCIROMFun;
         End;
       End;
      SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04, PCIReg4 );
      SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, PCIReg30 );
      Asm STI End;
    end
   else
    begin
      {Scan the PCI config space for devices with a PCI option ROM}
      For PCIROMBus := 0 to $FF do For PCIROMDev :=0 to $1F do
       Begin
        If ( GetPCIRegD( PCIROMBus, PCIROMDev, 0, 0 ) and $FFFF ) <> $FFFF then
         Begin
          X := 0;
          If ( GetPCIRegD( PCIROMBus, PCIROMDev, 0, $0C ) and $800000 ) <> 0 then X := 7;
          For PCIROMFun := 0 to X do
           If ( GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, 0 ) and $FFFF ) <> $FFFF then
            Begin
             (* Found a PCI device, check for PCI option ROM *)
             Asm CLI End;
             {Save state; enable memory}
             PCIReg4 := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04 );     {Save reg 4}
             SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04, PCIReg4 or $02 ); {Enable memory}
             PCIReg30 := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30 );     {Save reg 30}

             {Check for hardwired bits}
             SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, $FFFFFFFF );  {Check for stuck 0's}
             Img := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30 );
             SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, $00000001 );  {Check for stuck 1's}
             Img := Img xor GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30 ); {Now every 0 is a hw bit}
             {Scan for 1st non-hardwired bit}
             For Z := 1 to 32 do
              If ( Img and ( 1 shl LongInt( Z ) ) ) <> 0 then Break;
             {We don't support option ROM's at (semi-)fixed addresses}
             If ( Z < 32 ) and ( ( Img xor ( - ( 1 shl LongInt( Z ) ) ) ) = 0 ) then
              Begin
               {found PCI option ROM, add to list}
               Inc( PCIROMCnt );
               With PCIROMs[ PCIROMCnt ] do
                Begin
                 MaxSize := 1 shl LongInt( Z );
                 VenID := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $00 );
                 DevID := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $00 ) shr 16;
                 Bus := PCIROMBus;
                 Pos := ( PCIROMDev shl 3 ) or PCIROMFun;
                End;
              End;
             {Restore PCI device state}
             SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04, PCIReg4 );
             SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, PCIReg30 );
             Asm STI End;
            End;
         End;
       End;
    end;

   If PCIROMCnt > 0 then
    Begin
     Window(1,9,80,25);
     ClrScr;
     Window(1,1,80,25);
     GotoXY(1,9);
     Text_Color( Yellow );
     WrtCenter( Msg( 39 ) );
     WriteLn;
     Text_Color( 15 );
     For X := 1 to PCIROMCnt do With PCIROMs[ X ] do
      Begin
       Write( '        ', Char( X + 48 ), '. ' );
       WriteLn( Msg( 40 ), Hb( Bus ),
                Msg( 41 ), Hb( Pos shr 3 ),
                Msg( 42 ), Hb( Pos and 7 ),
                ' (VEN=', Hw( VenId ),
                ', DEV=', Hw( DevId ),
                ', ', MaxSize shr 10, 'K max)' );

      End;
     WriteLn;
     WrtCenter( Msg( 43 ) );
     WriteLn;
     WrtCenter( Msg( 44 ) );
     GotoXY( 17, WhereY - 1 );
     SelA := '0';
     Repeat
      A := _ReadKey;
      If ( A >= '0' ) and ( A <= Char( 48 + PCIROMCnt ) ) then
       Begin
        SelA := A;
        GotoXY( 17, WhereY );
        Write( A );
        GotoXY( 17, WhereY );
       End;
     Until ( A = #13 ) or ( A = #27 );
     If ( A = #27 ) or ( SelA = '0' ) then
      Begin
       WriteLn;
       Halt;
      End;
     CurPCIROM := Byte( SelA ) - 48;
     With PCIROMs[ CurPCIROM ] do
      Begin
       PCIROMBus := Bus;
       PCIROMDev := Pos shr 3;
       PCIROMFun := Pos and 7;
       PCIReg4 := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04 );       {Save reg 4}
       SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04, PCIReg4 or $02 );  {Enable memory}
       PCIReg30 := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30 );      {Save reg 30}
(*       If Hi( PCIReg30 shr 16 ) = $CB then {v1.22}
        SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, PCIReg30 or 1 )
       else*) SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, $80000001 );
       PCIROMEnable(True);

       GotoXY(2,7);
       ClrEol;
       Text_Color(Yellow);
       Write(Msg(66));
       Text_Color(15);
       Write(CurrentPCICard,' at ',Hb(PCIROMBus),':',Hb(PCIROMDev),':',Hb(PCIROMFun));

       PCIROMEn := True;
       ROMBase := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30 ) and $FFFFFFFE{ $80000000}; {v1.22}
      End;

     Window(1,9,80,25);
     ClrScr;
     Window(1,1,80,25);
     GotoXY(1,3);
     LogWrite( 'PCI expansion ROM at '+Hb(PCIROMBus)+':'+Hb(PCIROMDev)+':'+Hb(PCIROMFun)+' selected' ); {v1.23}
    End else Err( Msg( 45 ) );
  End
 else
  if CTFlash then
   begin
     if not CTFlash_AutoDetect then begin Err(Msg(112)); end;
     GotoXY(2,7);
     ClrEol;
     GotoXY(19,7);
     Text_Color(Yellow);
     Write('c''t Flasher: ');
     Text_Color(15);
     Write(Hw(CTFlashPort),', ',Hl(CTFlashBase));
   end
  else
    Begin
      RomEnable( True ); {Program the chipset so it lets you see the BIOS}
      LogWrite( 'System ROM selected' ); {v1.23}
   End;
end;

procedure ROMType; {v1.24}
begin
 If FlashError = 0 then
  Begin
   FlashSize := LongInt( FlashInfo^.Size ) shl 10;
   FlashBase := ROMBase { - ( FlashSize * FlashInfo^.Count ) };

   With FlashInfo^ do
    Case Flags and 3 of
     0   : Begin
            MaxBlock := 0;
            For X := 0 to 4 do {v1.21 3->4}
             Begin
              If Sectors[ X, 0 ] = 0 then Break;
              If Sectors[ X, 1 ] > MaxBlock then
               MaxBlock := Sectors[ X, 1 ];
             End;
            MaxBlock := ( MaxBlock + 1 ) shl{ 11}7; {v1.21}
           End;
     1,3 : MaxBlock := PgSize;
     2   : MaxBlock := FlashSize {div FlashInfo^.Count};
    End;
   {Allocate 2 buffers for BIOS images}
   OldBIOS := AllocLinBlock( FlashSize );
   NewBIOS := AllocLinBlock( FlashSize );
   {Allocate temp page/sector buffer}
   TempBuf := AllocLinBlock( MaxBlock );

   If ( OldBIOS = 0 ) or ( NewBIOS = 0 ) or ( TempBuf = 0 ) then
    Err( Msg( 50 ) );
  End else
  Begin
   {some defaults so we can at least write something to disk}
   If PCIROM then
    Begin
     FlashBase := ROMBase;
{     FlashSize := FlashSize shl 9;}
     FlashSize := PCIROMs[ CurPCIROM ].MaxSize; {v1.22}
    End else
    Begin
     FlashSize := 131072;    {128K default}
     if (ROMBase=0) or (ROMBase=$FFF00000) then {v1.30}
      begin
        if BaseForced=0 then FlashBase := $FFFE0000 else FlashBase:=ROMBase; {same}
        ROMBase := FlashBase;
      end;
    End;
   OldBIOS := AllocLinBlock( FlashSize );
   If ( OldBIOS = 0 ) then
    Err( Msg( 50 ) );
  End;
 Text_Color(yellow);
 GotoXY( 2, 5 );
 ClrEol;
 Write( Msg( 51 ) );
 With FlashInfo^ do
  Begin
   Text_Color( 15 );
   If FlashError <> 0 then Write( Msg( 52 ) )
   else
    Begin
{     If Count > 1 then Write( Count, ' x ' );}
     Write( Manuf^, ' ', Name^ );
    End;
   If ForceId then
    begin
      Write( ' (forced)' );
      LogWrite('Flash ROM chip forced: '+Manuf^+' '+Name^); {v1.23}
    end
   else
    if FlashError=0 then LogWrite('Flash ROM chip detected: '+Manuf^+' '+Name^) {v1.23}
     else LogWrite( 'Flash ROM chip not detected' ); {v1.23}
   GotoXY( 1, 5 ); {v1.21}
   Write(' (' + Hb( Man1 ) + Hb( Dev1 ) + ',' + Hb( Man2 ) + Hb( Dev2 ) + ')' );
   LogWrite('Flash ROM ID: '+Hb(Man1)+HB(Dev1)+','+Hb(Man2)+Hb(Dev2)); {v1.23}

   GotoXY( 2, 6 );
   Text_Color(yellow);
   ClrEol;
   Write( Msg( 53 ) );
   Text_Color( 15 );
   If FlashError <> 0 then Write( Msg( 54 ) ) else
    Begin
     Case Flags and 3 of
      0 : Begin
           Write( Msg( 55 ) );
{           If Count > 1 then Write( Count, ' x (' );}
           For X := 0 to 4 do With FlashInfo^ do {v1.21 3->4}
            Begin
             If Sectors[ X, 0 ] = 0 then Break;
             If X > 0 then Write( ',' );
             Write( Sectors[ X, 0 ], 'x' );
             if Sectors[ X, 1 ] >= 8 then Write( ( Word( Sectors[ X, 1 ] ){ + 1} ) shr 3{shl 1}, 'k' ) {v1.21}
              else Write( ( Word( Sectors[ X, 1 ] ){ + 1} ) shl 7{shl 1}, 'b' );
            End;
{           If Count > 1 then Write( ')' );}
          End;
      1 : Begin
{           If Count > 1 then Write( Count, ' x ' );}
           Write( ( ( LongInt( Size ) shl 10 ) {div Count} ) div PgSize );
           Write( Msg( 56 ), pgsize, Msg( 57 ) );
          End;
      2 : Write( Msg( 58 ) );
      3 : Begin
{           If Count > 1 then Write( Count, ' x ' );}
           Write( ( ( LongInt( Size ) shl 10 ) {div Count} ) div PgSize );
           Write( Msg( 59 ), pgsize, Msg( 57 ) );
          End;
     End;
     If ( Size and 1023 ) <> 0 then
      Write( ' (', Size, 'K)' )
     else
      Write( ' (', Size shr 10, 'M)' );
    End;
  End;
  GotoXY(2,8); {v1.28}
end;

procedure XMSInfo; {v1.24}
begin
 Text_Color( DarkGray );
 GotoXY( 1, 24 );
 Write( Msg( 68 ) );
 Write( 'XMSPos=', Hl( XMSPos ), ', XMSLeft=', XMSLeft );
 GotoXY( 1, 23 );
 Write( Msg( 69 ) );
 Write( Hl( ROMBase )+ Msg( 70 ) +Hl(ROMBase)+'-->('+Hw(FIMemW(ROMBase))+Hw(FIMemW(ROMBase+2))+')' );
end;

procedure RedetectFlashROM;Far; {v1.24}
begin
 ForceID:=False; {v1.30}
 LogWrite('Restarting UniFlash...');
 If PCIROMEn then
  Begin
   SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04, PCIReg4 );
   SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, PCIReg30 );
   PCIROMEnable(False);
  End;
 RomEnable( False );
 LogWrite('Shutting down to real mode');
 FlatRealOff;
 LogWrite('Turning off XMS support');
 CloseXMS;
 LogWrite('Initializing again');
 MemInit;
 ROMSelect;
 FlashInfo := FlashDetect;
 ROMType;
 LogWrite('Welcome back');
 XMSInfo;
 {Backup current BIOS}
 Flash_ReadBlock(0,OldBios,FlashSize); {v1.29}
 SetMenuItemStatus( MainMenu, 0, True );
 SetMenuItemStatus( MainMenu, 1, True );
 SetMenuItemStatus( MainMenu, 2, False );
 SetMenuItemStatus( MainMenu, 3, True );
 SetMenuItemStatus( MainMenu, 4, True );
 SetMenuItemStatus( MainMenu, 5, True );
 SetMenuItemStatus( MainMenu, 7, True );
 If FlashInfo = Nil then
  Begin
   SetMenuItemStatus( MainMenu, 1, False );
   SetMenuItemStatus( MainMenu, 5, False );
  End;
 If ( FlashInfo^.Flags and 3 ) = 2 then SetMenuItemStatus( MainMenu, 5, False );
 if PCIROM then
  begin
    SetMenuItemStatus( MainMenu, 4, False );
    SetMenuItemStatus( MainMenu, 5, False );
  end;
end;

{---------------------- MAIN PART OF THE PROGRAM -------------------------}
{---------------------- MAIN PART OF THE PROGRAM -------------------------}
{---------------------- MAIN PART OF THE PROGRAM -------------------------}
{---------------------- MAIN PART OF THE PROGRAM -------------------------}
Begin
 FileMode:=0; {Reset will open files as Read-Only} {v1.31}
 {Hack to be able to write to StdOut - better ideas anyone ?}
 Assign( StdOut, 'CON' );
 Rewrite( StdOut );
 StdOutRec.Handle := 1;
 CheckRedir; {v1.22 Check if STDOUT is redirected}
 if NoVideo then DirectVideo:=False; {v1.28}

 ClrScr;
 GotoXY(9,2);
 Text_Color(Yellow);
 Write('UniFlash ');
 Text_Color(LightGreen);
 Write('v' + Version );
 Text_Color(LightCyan);
 WriteLn(' (c) 2004 Rainbow Software (http://www.uniflash.org)');
 Text_Color(LightMagenta);
 GotoXY(9,3);
 Write('Original version by Pascal van Leeuwen & Galkowski Adam');
 Text_Color(LightGray);

 CurLang := 1; {default = English}
 If ( ParamCount > 0 ) then
  Begin
   PStr := OpStr( ParamStr( 1 ) );
   If PStr[ 1 ] = '0' then
    Begin
     WriteLn;
     WriteLn;
     WrtCenter( 'Languages supported in this version:' );
     WriteLn;
     For X := 1 to LangCount do
      WrtCenter( Char( X + Ord( '0' ) ) + '. ' + GetLangName( X ) );
     WriteLn;
     WrtCenter( 'Use UNIFLASH /x [other options] where x is the language number.' );
     WriteLn;
     Halt;
    End;
   If PStr[ 1 ] in [ '1' .. Char( LangCount + Byte( '0' ) ) ] then
    Begin
     CurLang := Byte( PStr[ 1 ] ) - Byte( '0' ); {Set language}
     X := 2;
    End else X := 1;
  End;
 InitLanguage(CurLang); {v1.31}
 PStr := Msg( 105 );
 AnswYes := PStr[ 1 ];
 AnswNo  := PStr[ 2 ];

 PCIROMBus:=0;
 PCIROMDev:=0;
 PCIROMFun:=0;

 While ParamCount >= X do
  Begin
   PStr := OpStr( ParamStr( X ) );
   If ( PStr = 'E' ) then
    Begin
     Inc( X );
     If ParamCount < X then Err( Msg( 29 )+'E' );
     Emergency := True;
     EMFName := ParamStr( X );
    End else
   If ( PStr = 'H' ) or ( PStr = '?' ) then
    Begin
     WriteLn;
     WriteLn;
     WrtCenter( 'UNIFLASH [-H|-?|[-PCIROM [BUS DEV FUN]|-AMI|-BASE xxxxx|CTFLASH [xxx]]' );
     WrtCenter( ' [-E fname][-SAVE fname|-CHIPLIST|-FORCE xxxx][-REPAIR][-LOG][-MONO]' );
     WrtCenter( ' [-CMOSS fname][-CMOSR fname][-CMOSC]][-QUIT][-REBOOT]'); {v1.26}
     WrtCenter( '' );
     WrtCenter( Msg( 30 ) );
     WrtCenter( Msg( 31 ) );
     WrtCenter( Msg( 33 ) ); {v1.32}
     WrtCenter( Msg( 32 ) );
     WrtCenter( Msg( 34 ) );
     WrtCenter( Msg( 35 ) );
     WrtCenter( Msg( 36 ) );
     WrtCenter( Msg( 107 ) );
     WrtCenter( Msg( 108 ) );
     WrtCenter( Msg( 132 ) ); {v1.28}
     WrtCenter( Msg( 136 ) ); {v1.28}
     WrtCenter( Msg( 109 ) );
     WrtCenter( Msg( 131 ) ); {v1.25}
     WrtCenter( Msg( 133 ) ); {v1.25}
     WrtCenter( Msg( 134 ) ); {v1.26}
     WrtCenter( Msg( 25 ) ); {v1.28}
     Halt;
    End else
   If PStr = 'PCIROM' then
    begin
      PCIROM:=True;
      Inc(X);
      PStr:=ParamStr(X);
      if (PStr[1]<>'-') and (PStr[1]<>'/') and (ParamCount>=X) then
       begin
         Val(PStr,PCIROMBus,Int);
         Inc(X);
         PStr:=ParamStr(X);
         if (ParamCount<X) or (PStr[1]='-') or (PStr[1]='/') then Err(Msg(135));
         Val(PStr,PCIROMDev,Int);
         Inc(X);
         PStr:=ParamStr(X);
         if (ParamCount<X) or (PStr[1]='-') or (PStr[1]='/') then Err(Msg(135));
         Val(PStr,PCIROMFun,Int);
       end
      else Dec(X);
    end
   else
   If PStr = 'CTFLASH' then {v1.32}
    begin
      CTFlash:=True;
      Inc(X);
      PStr:=ParamStr(X);
      if (PStr[1]<>'-') and (PStr[1]<>'/') and (ParamCount>=X) then
       CTFlashPort:=Hex2Dec(PStr)
      else begin CTFlashPort:=0; Dec(X); end;
      CTFlashPort:=CTFlashPort and $FFFC;
      if (CTFlashPort<$200) or (CTFlashPort>$3FC) then CTFlashPort:=0;
    end
   else
   If PStr = 'AMI' then WantToUseAmi := True else
   If PStr = 'MONO' then Mono := True else {v1.27}
   If PStr = 'LOG' then
    begin
     Logging:=True;
     LogStart;
    end else {v1.23}
   If PStr = 'CHIPLIST' then
    Begin
     WriteLnStd( '' );
     WriteLnStd( '  List of supported flash chips' );
     WriteLnStd( '  -----------------------------' );
     CurManuf := ManuRoot;
     Repeat
      With CurManuf^ do
       Begin
        M := Manuf;
        For D := 0 to $FF do {v1.21 FF}
         If IdChip( D, CurCInfo ) then With CurCInfo do
          if not WriteLnStd( '  '+ Hb( M )+ Hb( D )+ ' - '+ Manuf^+ ' '+ Name^ ) then
           begin ClrKbBuf; Exit; end;
       End;
      CurManuf := CurManuf^.Next;
     Until ( CurManuf = Nil );
     Exit;
    End else
   If PStr = 'FORCE' then
    Begin
     Inc( X );
     If ParamCount < X then Err( Msg( 106 ) );
     PStr := ParamStr( X );
     If Length( PStr ) <> 4 then Err( Msg( 106 ) );
     ForceIdVal := 0;
     For M := 1 to 4 do
      Begin
       ForceIdVal := ForceIdVal shl 4;
       If ( PStr[ M ] >= '0' ) and ( PStr[ M ] <= '9' ) then
        ForceIdVal := ForceIdVal or ( Byte( PStr[ M ] ) - Byte( '0' ) )
       else
       If ( UpCase( PStr[ M ] ) >= 'A' ) and ( UpCase( PStr[ M ] ) <= 'F' ) then
        ForceIdVal := ForceIdVal or ( Byte( UpCase( PStr[ M ] ) ) - Byte( 'A' ) + 10 )
       else Err( Msg( 106 ) );
      End;
     ForceId := True;
    End else
   If PStr = 'REPAIR' then {v1.28}
    Begin
      if not ForceID then Err(Msg(137));
      if (Hi(ForceIDVal)<>$BF) and (Hi(ForceIDVal)<>$DA) then Err(Msg(138));
      Repair:=True;
    End else
   If PStr = 'SAVE' then
    Begin
     Inc( X );
     If ParamCount < X then Err( Msg( 29 ) );
     SaveBIOS := True;
     SaveName := ParamStr( X );
    End else
   if PStr = 'CMOSS' then {v1.25}
    begin
     CMOS:=True;
     Inc(X);
     if ParamCount<X then Err(Msg(29)+'CMOSS');
     CMOSSize:=GetCMOSSize;
     Assign(IFile,ParamStr(X));
     ReWrite(IFile,1);
     If IOResult=0 then
      begin
        CMOSWrite(IFile);
        Close(IFile);
        IOError;
        WriteLn;
        WriteLn;
        LogWrite('CMOS settings saved to '+ParamStr(X));
        WrtCenter('CMOS settings saved to '+ParamStr(X));
      end else Err(Msg(7)+ParamStr(X)+' !'#7);
    end else
   if PStr = 'CMOSR' then {v1.25}
    begin
     CMOS:=True;
     Inc(X);
     if ParamCount<X then Err(Msg( 29 )+'CMOSR');
     CMOSSize:=GetCMOSSize;
     Assign(IFile,ParamStr(X));
     Reset(IFile,1);
     if IOResult=0 then
      begin
       if FileSize(IFile)=(CMOSSize-$0D) then
        begin
          CMOSRestore(IFile);
          Close(IFile);
          IOError;
          WriteLn;
          WriteLn;
          LogWrite('CMOS settings restored from '+ParamStr(X));
          WrtCenter('CMOS settings restored from '+ParamStr(X));
        end else Err(Msg(98)+_Str(CMOSSize-$0A)+Msg(99));
      end else Err(Msg(8)+ParamStr(X)+' !'#7);
    end else
   if PStr = 'CMOSC' then {v1.25}
    begin
     CMOS:=True;
     CMOSSize:=GetCMOSSize;
     if CMOSClr then
      begin
       WriteLn;
       WriteLn;
       LogWrite('CMOS settings cleared');
       WrtCenter('CMOS settings cleared');
      end
     else Err(Msg(24));
    end else
   if PStr = 'QUIT' then Quit:=True else {v1.28}
   if PStr = 'REBOOT' then Reboot:=True else {v1.28}
   if PStr = 'BASE' then {v1.28}
    begin
     Inc(X);
     if ParamCount<X then Err(Msg(92));
     PStr:=ParamStr(X);
     if Length(PStr)<5 then Err(Msg(92));
     for M:=1 to Length(PStr) do
      Begin
       BaseForced:=BaseForced shl 4;
       if (PStr[M]>='0') and (PStr[M]<='9') then
        BaseForced:=BaseForced or (Byte(PStr[M])-Byte('0'))
       else
       if (UpCase(PStr[M])>='A') and (UpCase(PStr[M])<='F') then
        BaseForced:=BaseForced or (Byte(UpCase(PStr[M]))-Byte('A')+10)
       else Err(Msg(92));
      End;
    End;
   Inc( X );
  End;

 if CMOS and not Emergency and not SaveBIOS then Exit;
 if Windows then Err( Msg( 110 ) ); {v1.22}

 if (not LocatePIIX) and (BaseForced=0) and not CTFlash then Err(Msg(111)); {v1.22}

 GotoXY( 2, 7 );
 Text_Color(yellow);
 Write( Msg( 61 ) );
 Text_Color( 15 );
 Write(CurrentChipset);

 LogWrite( 'Chipset detected: ' + CurrentChipset ); {v1.23}

 MemInit; {v1.24}

 CMOSSize := GetCMOSSize;
 LogWrite( 'CMOS size detected: '+_Str(CMOSSize+1)+'b'); {v1.25}

 OldExitProc := ExitProc;
 ExitProc := @MyExitProc;

 BIOSID:=#0#0#0#0#0#0#0#0; {v1.34}
 ROMSelect; {v1.24}

 If ForceId then
  Begin
   FlashError := 1;
   CurManuf := ManuRoot;
   FlashInfo := @CurCInfo;
{   CurCInfo.Count` := 1;}
   Repeat
    With CurManuf^ do
     If ( Manuf = Hi( ForceIdVal ) ) and
          IdChip( Lo( ForceIdVal ), CurCInfo ) then FlashError := 0;
    CurManuf := CurManuf^.Next;
   Until ( FlashError = 0 ) or ( CurManuf = Nil );
   If ROMBase = 0 then
    ROMBase := - LongInt( FlashInfo^.Size ) shl 10; {rom starts at top of memory}
   Size512K:=CurCInfo.Size>=512; {v1.34}
  End else FlashInfo := FlashDetect;

 ROMType; {v1.24}

 {Backup current BIOS}
 Flash_ReadBlock(0,OldBios,FlashSize); {v1.29}

 If SaveBIOS then
  Begin
   WriteBIOSImg;
   GotoXY( 1, Hi( WindMax ) );
  End;

 if Quit then Exit; {v1.28}

 if Repair then
  begin
    FlashCmd($F0);
    Delay(100);
    FlashCmd($80);
    FlashCmd($60);
    Delay(100);
    Flash_Write(0,Hi(ForceIdVal));
    Flash_Write(1,Lo(ForceIdVal));
    Delay(100);
    FlashCmd($F0);
    Halt;
  end;

 If Emergency then
  Begin
   LogWrite('Entering emergency mode');
   If FlashError <> 0 then Err( Msg( 60 ) );
   Beep( 1000, 500 ); {single beep, start reading}
   Assign( IFile, EmFName );
   Reset( IFile, 1 );
   If IOResult <> 0 then Err( Msg( 8 ) + EMFName + Msg( 95 ) );
   FlashFile( IFile, True {force boot block write, from personal experience}
                          {I really think that it can't be avoided !!      } );
   Close( IFile );
   IOError;
   if Reboot then
    asm
      db 0EAh,00h,00h,0FFh,0FFh
    end;
   Halt;
  End;

 GotoXY( 2, 8 );
 Text_Color(yellow);
 Write( Msg( 62 ) );
 Text_Color( 15 );
 Write( Msg( 63 ) );

 XMSInfo; {v1.24}

(* If PCIROM then {v1.29}
  Begin
   Text_Color( yellow );
   GotoXY( 2, 8 );
   Write( Msg( 71 ) );
   Text_Color( 15 );
   Write( Msg( 72 ), Hb( PCIROMBus ),
          ':', Hb( PCIROMDev ),
          ':', Hb( PCIROMFun ) );
  End;*)

 {Backup CMOS data}
 Z:=CMOSSize;
 if Z>127 then Z:=127;
 for X:=$0E to Z do
  begin
   Port[$70]:=X;
   CMOSBack[X]:=Port[$71];
  end;
 if CMOSSize>Z then
  begin
   for X:=$80 to $FF do
    begin
     Port[$72]:=X;
     CMOSBack[X]:=Port[$73];
    end;
  end;

 Text_Color(WHITE);

 GetDir(0,SaveDir); {v1.28}

(* PnPDMIMenu := AddMenuItem( Msg( 73 ), Msg( 112 ), 0, 1, @WritePnp,
               AddMenuItem( Msg( 74 ), Msg( 113 ), 1, 1, @FlashPnp,
               AddMenuItem( Msg( 75 ), Msg( 114 ), 2, 1, @ClearPnp,
               AddMenuItem( Msg( 76 ), 4, 1, @WriteDMI,
               AddMenuItem( Msg( 77 ), 5, 1, @FlashDMI,
               AddMenuItem( Msg( 78 ), 6, 1, @ClearDMI,
               AddMenuItem( Msg( 79 ), Msg( 130 ), 4, 1, Nil, Nil ) ) ) ) {) ) )};*)

 AdvMenu := AddMenuItem( Msg( 82 ), Msg( 115 ), 0, 1, @FlashBIOS,
            AddMenuItem( Msg( 83 ), Msg( 116 ), 1, 1, @WriteBootBlk,
            AddMenuItem( Msg( 84 ), Msg( 117 ), 2, 1, @FlashBootBlk,
            AddMenuItem( Msg( 79 ), Msg( 130 ), 4, 1, Nil, Nil ) ) ) );

 CMOSMenu := AddMenuItem( Msg( 80 ), Msg( 118 ), 0, 1, @SaveCMOS,
             AddMenuItem( Msg( 81 ), Msg( 119 ), 1, 1, @RestoreCMOS,
             AddMenuItem( Msg( 88 ), Msg( 120 ), 2, 1, @ClearCMOS,
             AddMenuItem( Msg( 89 ), Msg( 121 ), 3, 0, @WrtOldCMOS,
             AddMenuItem( Msg( 79 ), Msg( 130 ), 5, 1, Nil, Nil ) ) ) ) );

 MainMenu := AddMenuItem( Msg( 85 ),  Msg( 122 ), 0, 1, @WriteBIOSImg,
             AddMenuItem( Msg( 86 ),  Msg( 123 ), 1, 1, @FlashBIOSBB,
             AddMenuItem( Msg( 87 ),  Msg( 124 ), 2, 0, @FlashOldBIOS,
             AddMenuItem( Msg( 100 ), Msg( 125 ), 3, 1, @RedetectFlashROM,
             AddMenuItem( Msg( 101 ), Msg( 126 ), 4, 3, CMOSMenu,
{             AddMenuItem( Msg( 90 ),  Msg( 127 ), 5, 3, PnPDMIMenu,}
             AddMenuItem( Msg( 91 ),  Msg( 128 ), 5, 3, AdvMenu,
             AddMenuItem( Msg( 93 ),  Msg( 129 ), 7, 1, Nil, Nil ) ) ) ) ) ) ) {)};

 If FlashInfo = Nil then
  Begin
   SetMenuItemStatus( MainMenu, 1, False );
   SetMenuItemStatus( MainMenu, 5, False );
  End;
 If ( FlashInfo^.Flags and 3 ) = 2 then SetMenuItemStatus( MainMenu, 5, False );

 If PCIROM then
  Begin
   SetMenuItemStatus( MainMenu, 4, False );
   SetMenuItemStatus( MainMenu, 5, False );
  End;
 LogWrite('UniFlash running in interactive mode'); {v1.23}
 VErr := False;
 Repeat
  RunMenu( MainMenu );
  If VErr then
   Begin
    Text_Color( 12 );
    GotoXY( 11, 22 );
    Write( Msg( 94 ) );
    Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
    GotoXY( 11, 22 );
    ClrEol;
   End;
 Until ( not VErr ) or ( A = AnswYes );

 GotoXY( 1, Hi( WindMax ) );
end.