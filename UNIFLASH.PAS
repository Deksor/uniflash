{$M 32384, 4096, 4096}
{$I-}
{$S-}
{$R-}
Program Uniflash;

Uses Crt, Dos,
     Flash,Pci,Tools, GenFlash,
     Intel, Atmel, SST, Winbond, AMD, Catalyst, Macronix, AMIC, Alliance,
     ISSI, Mosel, EON, PMC, Hyundai, IMT,
     Language, English, French, Dutch;


Const
Expert      : Boolean = False;
Emergency   : Boolean = False;
Debug       : Boolean = False;
PCIOREn     : Boolean = False;
PCIOR       : Boolean = False;
AutoSave    : Boolean = False;
Version     = '1.21';
ForceId     : Boolean = False;

Var
M, D,
CurOp,
ORBus, OrDev,
ORFun, Z,
FlashNo,X,Y : Byte;
BIOSBlk     : ARRAY[ 0 .. 32767 ] of Byte;
FlashName   : ^String;
OldExitProc : Pointer;
OldBIOS,
NewBIOS     : LongInt;
FlashBase,
FlashSize   : LongInt;
X2,Y2       : Longint;
AdvMenu,
PnPDMIMenu,
MainMenu    : PMenuItem;
FlashInfo   : PChipInfo;
VErr        : Boolean;
SelA, A     : Char;
IFile       : File;
CMOSImg,
CMOSBack    : ARRAY[ $10 .. $7F ] of Byte;
Img,
PCIReg4,
PCIReg30,
ScanPos,
MaxBlock,
TempBuf     : LongInt;
SStarts     : ARRAY[ 0 .. 512 ] of LongInt; {38 -> 512 v1.21}
OPRCnt,
CMOSSize    : Byte;
EMFName,
PStr        : String[ 127 ];
OpROM       : ARRAY[ 1 .. 20 ] of
               Record
                MaxSize : LongInt;
                VenID,
                DevID   : Word;
{                Size    : Byte; }
                Bus,
                Pos     : Byte;
               End;
AnswYes,
AnswNo      : Char;
StdOut      : Text;
StdOutRec   : TextRec absolute StdOut;
ForceIdVal  : Word;

Function AskFor2(l : byte;txt : string) : boolean;
var x,y,x2,y2 : byte;
answer : char;
begin
Askfor2:=true;
x:=wherex;
y:=wherey;
gotoxy(13,y+1+l);
write(txt);
repeat
answer:=Upcase( readkey );
until ( answer = AnswYes ) or ( Answer = AnswNo );
askfor2:= Answer = AnswYes;
writeln;
x2:=wherex;
y2:=wherey;
gotoxy(13,y+1+l);
clreol;
gotoxy(x,y);
end;

Function AskFor(l : byte;txt : string) : boolean;
Var x,y : byte;

begin
 x:=wherex;
 y:=wherey;
 AskFor := AskFor2( l, txt );
 gotoxy( x,y );
end;

Procedure FlashBlock( Block, Start, Size : LongInt );
Var
S,
X, Pos  : LongInt;
UpdStat,
NxtUpd  : Word;
Sector  : Boolean;
SPos, Y,
{Z,} W    : Byte;
Z       : Word; {v1.21}
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

 Start := Start + FlashBase;
 If Sector then
  Begin
   X := FlashBase;
   SPos := 1;
   SStarts[ 0 ] := X;
   If ( ( FlashInfo^.Flags ) and 2 ) = 0 then
    Begin
     {Make list with sector ends & sizes (=next sector starts)}
     With FlashInfo^ do
      For W := 1 to Count do
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
     For W := 1 to FlashInfo^.Count do
      Begin
       X := X + ( FlashSize div FlashInfo^.Count );
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
           Write( 'Û' );
           NxtUpd := UpdStat;
          End;
         FlashProgram( FlashBase + X, TempBuf );
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
   While ( S < Size ) and
          ( ( Size - S ) >= ( SStarts[ Y + 1 ] - SStarts[ Y ] ) ) do
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
  WrtProgressBar( Msg( 3 ) );
  VErr := False;
{writeln(hl(X * ( Size shr 5 ) + FlashBase + Start),' ',hl(X * ( Size shr 5 ) + BIOS));}
  For X := 0 to 31 do
   Begin
    If CompLinBlocks( X * ( Size shr 5 ) + FlashBase + Start,
                      X * ( Size shr 5 ) + BIOS, Size shr 5 )
     then Write( 'Û' ) else
      Begin
       Write( 'X' );
       VErr := True;
      End;
(*    Delay( 50 );  {just cosmetic}  *)
   End;
  If VErr then
   Begin
    TextColor( 12 );
    GotoXY( 2, 22 );
    If Emergency then Sound( 1000 ) else Write( #7 );
    Write( Msg( 4 ) );
    Repeat A := UpCase( ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
    If Emergency then NoSound;
    GotoXY( 11, 22 );
    ClrEol;
   End;
 Until ( not VErr ) or ( A = AnswNo );
 ClearProgressBar;
End;


Procedure FlashFile( Var IFile : File; BB : Boolean );
Var
X, Pos : LongInt;

Begin
 X := 0;
 While ( X < FileSize( IFile ) ) do
  Begin
   BlockRead( IFile, BIOSBlk, 32768 );
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
      not CompLinBlocks( $FFFFE000, NewBios + FlashSize - 8192, 8192 ) then
    Begin
     TextColor( 12 );
     GotoXY( 2, 22 );
     Write( Msg( 5 ) );
     Repeat A := UpCase( ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
     GotoXY( 2, 22 );
     ClrEol;
     If A = AnswNo then
      Begin
       GotoXY( 2, 20 );
       ClrEol;
       Exit;
      End;
    End;
   FlashBIOSImg( NewBIOS, Pos, FileSize( IFile ) - 8192 );
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
 If AutoSave then IName := EMFName else
  Begin
   GotoXY( 11, 20 );
   Write( Msg( 6 ) );
   ReadLn( IName );
  End;

 If IName <> '' then
  Begin
   Assign( IFile, IName );
   Rewrite( IFile, 1 );
   If IOResult <> 0 then
    Begin
     GotoXY( 11, 20 );
     Write( Msg( 7 ), IName, Msg( 95 ) );
     Delay( 2000 );
     GotoXY( 11, 20 );
     ClrEol;
     Exit;
    End;

   X := 0;
   While ( X < FlashSize ) do
    Begin
     MoveLinBlockD( X + OldBIOS, LongInt(  Seg( BIOSBlk ) ) shl 4 + LongInt( Ofs( BIOSBlk ) ), 32768 );
     BlockWrite( IFile, BIOSBlk, 32768 );
     X := X + 32768;
    End;

   Close( IFile );
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

Begin
 GotoXY( 11, 20 );
 Write( Msg( 6 ) );
 ReadLn( IName );
 If IName <> '' then
  Begin
   Assign( IFile, IName );
   Reset( IFile, 1 );
   If IOResult <> 0 then
    Begin
     GotoXY( 11, 20 );
     Write( Msg( 8 ), IName, Msg( 95 ) );
     Delay( 2000 );
     GotoXY( 11, 20 );
     ClrEol;
     Exit;
    End;
   If FileSize( IFile ) <> FlashSize then
    Begin
     TextColor( 12 );
     GotoXY( 11, 22 );
     Write( Msg( 9 ) );
     Repeat A := UpCase( ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
     GotoXY( 11, 22 );
     ClrEol;
     If A = AnswNo then
      Begin
       GotoXY( 11, 20 );
       ClrEol;
       Close( IFile );
       Exit;
      End;
    End;
   If BB then
    Begin
     TextColor( 12 );
     GotoXY( 11, 22 );
     Write( Msg( 10 ) );
     Repeat A := UpCase( ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
     GotoXY( 11, 22 );
     ClrEol;
     If A = AnswNo then
      Begin
       GotoXY( 11, 20 );
       ClrEol;
       Close( IFile );
       Exit;
      End;
    End;

   FlashFile( IFile, BB );
   Close( IFile );
   GotoXY( 32, 7 );
   ClrEol;
   GotoXY( 32, 7 );
   If VErr then
    Begin
     TextColor( 12 );
     Write( Msg( 11 ) );
    End else
    Begin
     TextColor( 15 );
     Write( Msg( 12 ) );
    End;
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
Procedure FlashPnPDMI( Typ : String; Pos : LongInt );
Var
IName : String;
X     : LongInt;
A     : Char;

Begin
 GotoXY( 11, 20 );
 Write( Typ + Msg( 13 ) );
 ReadLn( IName );
 If IName <> '' then
  Begin
   Assign( IFile, IName );
   Reset( IFile, 1 );
   If IOResult <> 0 then
    Begin
     GotoXY( 11, 20 );
     Write( Msg( 8 ), IName, Msg( 95 ) );
     Delay( 2000 );
     GotoXY( 11, 20 );
     ClrEol;
     Exit;
    End;
   If FileSize( IFile ) <> 4096 then
    Begin
     GotoXY( 11, 20 );
     Write( Msg( 14 ) );
     Delay( 2000 );
     GotoXY( 11, 20 );
     ClrEol;
     Close( IFile );
     Exit;
    End;
   BlockRead( IFile, BIOSBlk, 4096 );
   if not askfor(0, Msg( 15 ) ) then
      begin
      close(ifile);
      GotoXY( 11, 20 );
      ClrEol;
      exit;
      end;

   FlashBIOSImg( ( LongInt( Seg( BIOSBlk ) ) shl 4 ) + LongInt( Ofs( BIOSBlk ) ),
                 Pos - FlashBase, 4096 );
   SetMenuItemStatus( MainMenu, 2, True );
   Close( IFile );
   GotoXY( 32, 7 );
   ClrEol;
   GotoXY( 32, 7 );
   If VErr then
    Begin
     TextColor( 12 );
     Write( Msg( 11 ) );
    End else
    Begin
     TextColor( 15 );
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
 FlashPnPDMI( 'PnP', $FFFFD000 );
End;

{Flash DMI data from file to ROM}
Procedure FlashDMI; Far;
Begin
 FlashPnPDMI( 'DMI', $FFFFC000 );
End;

Procedure ClearPnPDMI( Typ : String; Pos : LongInt );
Begin
 TextColor( 12 );
 GotoXY( 11, 22 );
 Write( Msg( 16 ), Typ, Msg( 17 ) );
 Repeat A := UpCase( ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
 GotoXY( 11, 22 );
 ClrEol;
 If A = AnswYes then
  Begin
   FillChar( BIOSBlk, 4096, $FF );
   FlashBIOSImg( ( LongInt( Seg( BIOSBlk ) ) shl 4 ) + LongInt( Ofs( BIOSBlk ) ),
                 Pos - FlashBase, 4096 );
   SetMenuItemStatus( MainMenu, 2, True );
   GotoXY( 32, 7 );
   ClrEol;
   GotoXY( 32, 7 );
   If VErr then
    Begin
     TextColor( 12 );
     Write( Msg( 11 ) );
    End else
    Begin
     TextColor( 15 );
     Write( Msg( 12 ) );
    End;
  End;
End;

Procedure ClearPnP; Far;
Begin
 ClearPnPDMI( 'PNP', $FFFFD000 );
End;

Procedure ClearDMI; Far;
Begin
 ClearPnPDMI( 'DMI', $FFFFC000 );
End;

Procedure WritePnPDMIImg( Typ : String; Pos : LongInt );
Var
IName : String;
IFile : File;
X     : LongInt;

Begin
 GotoXY( 11, 20 );
 Write( Msg( 97 ) + Typ + Msg( 18 ) );
 ReadLn( IName );
 Assign( IFile, IName );
 Rewrite( IFile, 1 );
 If IOResult <> 0 then
  Begin
   GotoXY( 11, 20 );
   Write( Msg( 7 ), IName, ' !'#7 );
   Delay( 2000 );
   GotoXY( 11, 20 );
   ClrEol;
   Exit;
  End;

 MoveLinBlockD( Pos, LongInt(  Seg( BIOSBlk ) ) shl 4 + LongInt( Ofs( BIOSBlk ) ), 4096 );
 BlockWrite( IFile, BIOSBlk, 4096 );
 Close( IFile );

 GotoXY( 11, 20 );
 ClrEol;
End;

Procedure WritePnP; Far;
Begin
 WritePnPDMIImg( 'PnP', $FFFFD000 );
End;

Procedure WriteDMI; Far;
Begin
 WritePnPDMIImg( 'DMI', $FFFFC000 );
End;

Procedure WriteBootBlk; Far;
Var
IName : String;
IFile : File;

Begin
 GotoXY( 11, 20 );
 Write( Msg( 19 ) );
 ReadLn( IName );
 Assign( IFile, IName );
 Rewrite( IFile, 1 );
 If IOResult <> 0 then
  Begin
   GotoXY( 11, 20 );
   Write( Msg( 7 ), IName, ' !'#7 );
   Delay( 2000 );
   GotoXY( 11, 20 );
   ClrEol;
   Exit;
  End;
 MoveLinBlockD( $FFFFE000, LongInt(  Seg( BIOSBlk ) ) shl 4 + LongInt( Ofs( BIOSBlk ) ), 8192 );
 BlockWrite( IFile, BIOSBlk, 8192 );
 Close( IFile );

 GotoXY( 11, 20 );
 ClrEol;
End;

Procedure FlashBootBlk; Far;
Var
IName : String;
X     : LongInt;
A     : Char;

Begin
 GotoXY( 11, 20 );
 Write( Msg( 19 ) );
 ReadLn( IName );
 If IName <> '' then
  Begin
   Assign( IFile, IName );
   Reset( IFile, 1 );
   If IOResult <> 0 then
    Begin
     GotoXY( 11, 20 );
     Write( Msg( 8 ), IName, ' !'#7 );
     Delay( 2000 );
     GotoXY( 11, 20 );
     ClrEol;
     Exit;
    End;
   If FileSize( IFile ) <> 8192 then
    Begin
     GotoXY( 11, 20 );
     Write( Msg( 96 ) );
     Delay( 2000 );
     GotoXY( 11, 20 );
     ClrEol;
     Close( IFile );
     Exit;
    End;
   TextColor( 12 );
   GotoXY( 11, 22 );
   Write( Msg( 10 ) );
   Repeat A := UpCase( ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
   GotoXY( 11, 22 );
   ClrEol;
   If A = AnswNo then
    Begin
     GotoXY( 11, 20 );
     ClrEol;
     Close( IFile );
     Exit;
    End;

   BlockRead( IFile, BIOSBlk, 8192 );
   FlashBIOSImg( ( LongInt( Seg( BIOSBlk ) ) shl 4 ) + LongInt( Ofs( BIOSBlk ) ),
                 $FFFFE000 - FlashBase, 8192 );
   SetMenuItemStatus( MainMenu, 2, True );
   Close( IFile );
   GotoXY( 32, 7 );
   ClrEol;
   GotoXY( 32, 7 );
   If VErr then
    Begin
     TextColor( 12 );
     Write( Msg( 11 ) );
    End else
    Begin
     TextColor( 15 );
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
 TextColor( 12 );
 GotoXY( 11, 22 );
 Write( Msg( 20 ) );
 Repeat A := UpCase( ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
 GotoXY( 11, 22 );
 ClrEol;
 If A = AnswYes then
  Begin
   FlashBIOSImg( OldBIOS, 0, FlashSize - 8192 );
   SetMenuItemStatus( MainMenu, 2, False );
  End;
End;

Function GetCMOSSize : Byte;
Var
X, S1, S2 : Byte;

Begin
 GetCMOSSize := 128;
 {Test for 128 bytes extended CMOS RAM}

 {Backup values $10 and $50}
 Port[ $70 ] := $10;
 S1 := Port[ $71 ];
 Port[ $70 ] := $50;
 S2 := Port[ $71 ];
 {If they are different then it is definately 128 bytes}
 If S1 <> S2 then Exit;
 {Change $50, read back at $10}
 Port[ $70 ] := $50;
 Port[ $71 ] := S1 xor $55;
 Port[ $70 ] := $10;
 X := Port[ $71 ];
 {Write back old values}
 Port[ $70 ] := $10;
 Port[ $71 ] := S1;
 Port[ $70 ] := $50;
 Port[ $71 ] := S2;

 {If value read back is same as value written then we only have 64 bytes}
 If ( X = ( S1 xor $55 ) ) then GetCMOSSize := 64;
End;

{Clear CMOS ram area}
Procedure ClearCMOS; Far;
Var
X, Y : Byte;

Begin
 TextColor( 12 );
 GotoXY( 2, 22 );
 Write( Msg( 21 ) );
 Repeat A := UpCase( ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
 GotoXY( 2, 22 );
 ClrEol;
 If A = AnswYes then
  Begin
   {Clear it}
   For X := $10 to CMOSSize - 1 do
    Begin
     Port[ $70 ] := X;
     Port[ $71 ] := $00;
    End;
   {Verify}
   Y := 0;
   For X := $10 to CMOSSize - 1 do
    Begin
     Port[ $70 ] := X;
     If Port[ $71 ] <> $00 then Y := 1;
    End;
   TextColor( 12 );
   GotoXY( 11, 22 );
   If Y = 0 then
    Begin
     Write( Msg( 22 ), CMOSSize, Msg( 23 ) );
     Delay( 1000 );
    End else
    Begin
     Write( Msg( 24 ) );
     Delay( 2000 );
    End;
   GotoXY( 11, 22 );
   ClrEol;
   SetMenuItemStatus( MainMenu, 4, True );
  End;
End;


{Write CMOS data to disk}
Procedure SaveCMOS; Far;
Var
IName : String;
IFile : File;
X     : Byte;

Begin
 GotoXY( 11, 20 );
 Write( Msg( 97 ) + 'CMOS' + Msg( 18 ) );
 ReadLn( IName );
 Assign( IFile, IName );
 Rewrite( IFile, 1 );
 If IOResult <> 0 then
  Begin
   GotoXY( 11, 20 );
   Write( Msg( 7 ), IName, ' !'#7 );
   Delay( 2000 );
   GotoXY( 11, 20 );
   ClrEol;
   Exit;
  End;
 For X := $10 to CMOSSize - 1 do
  Begin
   Port[ $70 ] := X;
   CMOSImg[ X ] := Port[ $71 ];
  End;
 BlockWrite( IFile, CMOSImg, CMOSSize - $10 );
 Close( IFile );
 GotoXY( 11, 20 );
 ClrEol;
End;

{Read CMOS data from disk}
Procedure RestoreCMOS; Far;
Var
IName : String;
IFile : File;
X, Y  : Byte;

Begin
 GotoXY( 11, 20 );
 Write( Msg( 97 ) + 'CMOS' + Msg( 18 ) );
 ReadLn( IName );
 If IName <> '' then
  Begin
   Assign( IFile, IName );
   Reset( IFile, 1 );
   If IOResult <> 0 then
    Begin
     GotoXY( 11, 20 );
     Write( Msg( 8 ), IName, ' !'#7 );
     Delay( 2000 );
     GotoXY( 11, 20 );
     ClrEol;
     Exit;
    End;
   If FileSize( IFile ) <> ( CMOSSize - $10 ) then
    Begin
     GotoXY( 11, 20 );
     Write( Msg( 98 ), CMOSSize - $10, Msg( 99 ) );
     Delay( 2000 );
     GotoXY( 11, 20 );
     ClrEol;
     Close( IFile );
     Exit;
    End;
   BlockRead( IFile, CMOSImg, CMOSSize - $10 );
   Close( IFile );
   For X := $10 to CMOSSize - 1 do
    Begin
     Port[ $70 ] := X;
     Port[ $71 ] := CMOSImg[ X ];
    End;
   Y := 0;
   For X := $10 to CMOSSize - 1 do
    Begin
     Port[ $70 ] := X;
     If Port[ $71 ] <> CMOSImg[ X ] then Y := 1;
    End;
   If Y <> 0 then
    Begin
     Write( Msg( 26 ) );
     Delay( 2000 );
    End;
   SetMenuItemStatus( MainMenu, 4, True );
  End;
 GotoXY( 11, 20 );
 ClrEol;
End;


Procedure WrtOldCMOS; Far;
Var
X, Y,
Size : Byte;

Begin
 TextColor( 12 );
 GotoXY( 11, 22 );
 Write( Msg( 27 ) );
 Repeat A := UpCase( ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
 GotoXY( 11, 22 );
 ClrEol;
 If A = AnswYes then
  Begin
   Size := CMOSSize;
   For X := $10 to Size - 1 do
    Begin
     Port[ $70 ] := X;
     Port[ $71 ] := CMOSBack[ X ];
    End;
   {Verify}
   Y := 0;
   For X := $10 to Size - 1 do
    Begin
     Port[ $70 ] := X;
     If Port[ $71 ] <> CMOSBack[ X ] then Y := 1;
    End;
   TextColor( 12 );
   GotoXY( 11, 22 );
   If Y = 0 then
    Begin
     Write( Size - $10, Msg( 28 ) );
     Delay( 1000 );
    End else
    Begin
     Write( Msg( 26 ) );
     ReadKey;
    End;
   GotoXY( 11, 22 );
   ClrEol;
  End;
 SetMenuItemStatus( MainMenu, 4, False );
End;

{Safety net, disable ROM access & flat real mode on exit}
Procedure MyExitProc; Far;
Begin
 If PCIOrEn then
  Begin
   SetPCIRegD( ORBus, ORDev, ORFun, $04, PCIReg4 );
   SetPCIRegD( ORBus, ORDev, ORFun, $30, PCIReg30 );
  End;
 textcolor( lightgray );
 RomEnable( Unmap );
 FlatRealOff;
 ExitProc := OldExitProc;
 Y := WhereY;
 Window( 1, WhereY, 80, 25 );
 TextColor( 7 );
 TextBackGround( 0 );
 ClrScr;
 Window( 1, 1, 80, 25 );
 GotoXY( 1, Y );
End;

Procedure WrtCenter( Msg : String );
Begin
 WriteLn( '          ' + Msg );
End;

Procedure Err( Msg : String );
Begin
 WriteLn;
 WriteLn;
 textcolor(lightred);
 WrtCenter( #7 + Msg );
 textcolor(lightgray);
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

procedure BiosInfo; far;
var s1,s2,s3,s4,s5 : string;
begin
gotoxy(6,21);
s1:=zero2str($f000,$A367);
s2:=zero2str($f000,$e061);
s3:=zero2str($f000,$ece0);
s4:=zero2str($f000,$ec71);
s5:=zero2str($f000,$e0c1);

{if s1='Award Software,  Inc.' then}
if not strcomp(s1,'Award',5) then
   begin
   s1:='?';
   s2:='?';
   s3:='?';
   s4:='?';
   s5:='?';
   end;

cwriteln(14,15, Msg( 100 ),s1);
cwriteln(14,15, Msg( 101 ),s2);
cwriteln(14,15, Msg( 102 ),s3);
cwriteln(14,15, Msg( 103 ),s4);
cwrite(14,15, Msg( 104 ),s5);
readkey;
gotoxy(1,21);
clreol;
gotoxy(1,22);
clreol;
gotoxy(1,23);
clreol;
gotoxy(1,24);
clreol;
gotoxy(1,25);
clreol;

end;


{---------------------- MAIN PART OF THE PROGRAM -------------------------}
{---------------------- MAIN PART OF THE PROGRAM -------------------------}
{---------------------- MAIN PART OF THE PROGRAM -------------------------}
{---------------------- MAIN PART OF THE PROGRAM -------------------------}
var savefile : file;
    savename : string;

Begin
 {Hack to be able to write to StdOut - better ideas anyone ?}
 Assign( StdOut, 'CON' );
 Rewrite( StdOut );
 StdOutRec.Handle := 1;

 ClrScr;
 GotoXY(11,2);
 textcolor(yellow);
 Write('UniFlash ');
 textcolor(lightgreen);
 Write('v' + Version );
 textcolor(lightcyan);
 WriteLn(' (c) 1998 Pascal van Leeuwen & Galkowski Adam ');
 textcolor(lightmagenta);
 GotoXY(11,3);
 Write('Development continues...by Rainbow Software (http://rnbw.tsx.org)');
 textcolor(lightgray);

 SetLanguage( 1 ); {default = English}
 If ( ParamCount > 0 ) then
  Begin
   PStr := OpStr( ParamStr( 1 ) );
   If PStr[ 1 ] = '0' then
    Begin
     WriteLn;
     WriteLn;
     WrtCenter( 'Languages supported in this version:' );
     WriteLn;
     For X := 1 to GetLangCount do
      WrtCenter( Char( X + Ord( '0' ) ) + '. ' + GetLangName( X ) );
     WriteLn;
     WrtCenter( 'Use UNIFLASH /x [other options] where x is the language number.' );
     WriteLn;
     Halt;
    End;
   If PStr[ 1 ] in [ '1' .. Char( GetLangCount + Byte( '0' ) ) ] then
    Begin
     SetLanguage( Byte( PStr[ 1 ] ) - Byte( '0' ) ); {Set language}
     X := 2;
    End else X := 1;
  End;
 PStr := Msg( 105 );
 AnswYes := PStr[ 1 ];
 AnswNo  := PStr[ 2 ];

 While ParamCount >= X do
  Begin
   PStr := OpStr( ParamStr( X ) );
   If ( PStr = 'E' ) then
    Begin
     Inc( X );
     If ParamCount < X then Err( Msg( 29 ) );
     Emergency := True;
     EMFName := ParamStr( X );
    End else
   If ( PStr = 'H' ) or ( PStr = '?' ) then
    Begin
     WriteLn;
     WriteLn;
     WrtCenter( 'UNIFLASH [-H|-?|[-E fname][-EXPERT][-PCIOR|-AMI]' );
     WrtCenter( '          [-DEBUG][-SAVE fname]|-CHIPLIST|-FORCE xxxx]' );
     WrtCenter( '' );
     WrtCenter( Msg( 30 ) );
     WrtCenter( Msg( 31 ) );
     WrtCenter( Msg( 32 ) );
     WrtCenter( Msg( 33 ) );
     WrtCenter( Msg( 34 ) );
     WrtCenter( Msg( 35 ) );
     WrtCenter( Msg( 36 ) );
     WrtCenter( Msg( 107 ) );
     WrtCenter( Msg( 108 ) );
     WrtCenter( Msg( 109 ) );
     WriteLn;
     Halt;
    End else
   If PStr = 'EXPERT' then Expert := True else
   If PStr = 'DEBUG' then Debug := True else
   If PStr = 'PCIOR' then PCIOR := True else
   If PStr = 'AMI' then WantToUseAmi := True else
   If PStr = 'CHIPLIST' then
    Begin
     WriteLn( StdOut );
     WriteLn( StdOut, '  List of supported flash chips' );
     WriteLn( StdOut, '  -----------------------------' );
     CurManuf := ManuRoot;
     Repeat
      With CurManuf^ do
       Begin
        M := Manuf;
        For D := 0 to $FF do {v1.21 FF}
         If IdChip( D, CurCInfo ) then With CurCInfo do
          WriteLn( StdOut,
                   '  ', Hb( M ), Hb( D ), ' - ', Manuf^, ' ', Name^ );
       End;
      CurManuf := CurManuf^.Next;
     Until ( CurManuf = Nil );
     Halt;
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
   If PStr = 'SAVE' then
    Begin
     Inc( X );
     If ParamCount < X then Err( Msg( 29 ) );
     AutoSave := True;
     EMFName := ParamStr( X );
    End;
   Inc( X );
  End;

 InitXMS; {Init memory subsystem. Should be done before FlatRealOn}
 If XMSLeft = -1 then
  Err( Msg( 37 ) );

 If not FlatRealOn then
  Err( Msg( 38 ) );

 {Allocate high memory if XMS not present}
 AllocHimem;

 CMOSSize := GetCMOSSize;

{Program the chipset that way it lets you to see the BIOS}
 RomEnable( Map );

 OldExitProc := ExitProc;
 ExitProc := @MyExitProc;

 ROMBase :=0 ;  {standard system BIOS flag for detectloop}

 {If PCI option ROM mode then scan for & select option ROM    }
 {NOTE: This is all experimental and uses a technique that    }
 {      I think will not be encouraged by the PCI SIG. It may }
 {      cause problems with PCI cards with a shared memory    }
 {      controller (like local memory corruption ...)         }
 {      Use the PCIOR switch at your own risk ...             }
 If PCIOR then
  Begin
   OPRCnt := 0;
   {Scan the PCI config space for devices with a PCI option ROM}
   For OrBus := 0 to $FF do For OrDev :=0 to $1F do
    Begin
     If ( GetPCIRegD( OrBus, OrDev, 0, 0 ) and $FFFF ) <> $FFFF then
      Begin
       X := 0;
       If ( GetPCIRegD( OrBus, OrDev, 0, $0C ) and $800000 ) <> 0 then X := 7;
       For OrFun := 0 to X do
        If ( GetPCIRegD( OrBus, OrDev, OrFun, 0 ) and $FFFF ) <> $FFFF then
         Begin
          (* Found a PCI device, check for PCI option ROM *)
          Asm CLI End;
          {Save state; enable memory}
          PCIReg4 := GetPCIRegD( OrBus, OrDev, OrFun, $04 );     {Save reg 4}
          SetPCIRegD( OrBus, OrDev, OrFun, $04, PCIReg4 or $02 ); {Enable memory}
          PCIReg30 := GetPCIRegD( OrBus, OrDev, OrFun, $30 );     {Save reg 30}

          {Check for hardwired bits}
          SetPCIRegD( OrBus, OrDev, OrFun, $30, $FFFFFFFF );  {Check for stuck 0's}
          Img := GetPCIRegD( OrBus, OrDev, OrFun, $30 );
          SetPCIRegD( OrBus, OrDev, OrFun, $30, $00000001 );  {Check for stuck 1's}
          Img := Img xor
                 GetPCIRegD( OrBus, OrDev, OrFun, $30 ); {Now every 0 is a hw bit}
          {Scan for 1st non-hardwired bit}
          For Z := 1 to 32 do
           If ( Img and ( 1 shl LongInt( Z ) ) ) <> 0 then Break;
          {We don't support option ROM's at (semi-)fixed addresses}
          If ( Z < 32 ) and
             ( ( Img xor ( - ( 1 shl LongInt( Z ) ) ) ) = 0 ) then
           Begin
(*            {Map the ROM at $80000000}
            SetPCIRegD( OrBus, OrDev, OrFun, $30, $80000001 );
            {And check for a valid PCI option rom at $80000000}
            If ( FIMemW( $80000000 ) = $AA55 ) then
             Begin
              If ( FIMemW( $80000000 + FIMemW( $80000018 ) ) = $4350 {PC} ) and
                 ( FIMemW( $80000000 + FIMemW( $80000018 ) + 2 ) = $5249 {IR} ) then
               Begin
                {found PCI option ROM, add to list} *)
                Inc( OPRCnt );
                With OPRom[ OPRCnt ] do
                 Begin
                  MaxSize := 1 shl LongInt( Z );
(*                  Size := FIMemB( $80000002 ); *)
                  VenID := GetPCIRegD( OrBus, OrDev, OrFun, $00 );
                  DevID := GetPCIRegD( OrBus, OrDev, OrFun, $00 ) shr 16;
                  Bus := OrBus;
                  Pos := ( OrDev shl 3 ) or OrFun;
                 End;
(*               End;
             End; *)

           End;
          {Restore PCI device state}
          SetPCIRegD( OrBus, OrDev, OrFun, $04, PCIReg4 );
          SetPCIRegD( OrBus, OrDev, OrFun, $30, PCIReg30 );
          Asm STI End;
         End;
      End;
    End;

   If OPRCnt > 0 then
    Begin
     WriteLn;
     TextColor( yellow );
     WrtCenter( Msg( 39 ) );
     WriteLn;
     TextColor( 15 );
     For X := 1 to OPRCnt do With OpROM[ X ] do
      Begin
       Write( '          ', Char( X + 48 ), '. ' );
       WriteLn( Msg( 40 ), Hb( Bus ),
                Msg( 41 ), Hb( Pos shr 3 ),
                Msg( 42 ), Hb( Pos and 7 ),
                ' (VID=', Hw( VenId ),
                ', DID=', Hw( DevId ),
                ', ', MaxSize shr 10, 'K max)' );

      End;
     WriteLn;
     WrtCenter( Msg( 43 ) );
     WriteLn;
     WrtCenter( Msg( 44 ) );
     GotoXY( 19, WhereY - 1 );
     SelA := '0';
     Repeat
      A := ReadKey;
      If ( A >= '0' ) and ( A <= Char( 48 + OPRCnt ) ) then
       Begin
        SelA := A;
        GotoXY( 19, WhereY );
        Write( A );
        GotoXY( 19, WhereY );
       End;
     Until ( A = #13 ) or ( A = #27 );
     If ( A = #27 ) or ( SelA = '0' ) then
      Begin
       WriteLn;

       Halt;
      End;
     CurOp := Byte( SelA ) - 48;
     With OPRom[ CurOp ] do
      Begin
       ORBus := Bus;
       ORDev := Pos shr 3;
       ORFun := Pos and 7;
       PCIReg4 := GetPCIRegD( ORBus, ORDev, ORFun, $04 );       {Save reg 4}
       SetPCIRegD( ORBus, ORDev, ORFun, $04, PCIReg4 or $02 );  {Enable memory}
       PCIReg30 := GetPCIRegD( ORBus, ORDev, ORFun, $30 );      {Save reg 30}
       SetPCIRegD( ORBus, ORDev, ORFun, $30, $80000001 );
       PCIOrEn := True;
       ROMBase := $80000000;
      End;

     Window( 1, 5, 80, 25 );
     ClrScr;
     Window( 1, 1, 80, 25 );
     GotoXY( 1, 3 );

    End else Err( Msg( 45 ) );
  End;

 If ForceId then
  Begin
   FlashError := 1;
   CurManuf := ManuRoot;
   FlashInfo := @CurCInfo;
   CurCInfo.Count := 1;
   Repeat
    With CurManuf^ do
     If ( Manuf = Hi( ForceIdVal ) ) and
          IdChip( Lo( ForceIdVal ), CurCInfo ) then FlashError := 0;
    CurManuf := CurManuf^.Next;
   Until ( FlashError = 0 ) or ( CurManuf = Nil );
   If ROMBase = 0 then
    ROMBase := - LongInt( FlashInfo^.Size ) shl 10; {rom starts at top of memory}
  End else FlashInfo := FlashDetect;

(*
if pcior then begin
if askfor2(2,Msg( 46 ) ) then begin
                      write( Msg( 47 ) );
                      readln(savename);
                      assign(savefile,savename);
                      rewrite(savefile,1);
                       X2 := 0;
                       While ( X2 < Oprom[curop].maxsize ) do
                        Begin
                         MoveLinBlockD( X2 + $80000000, LongInt(  Seg( BIOSBlk ) ) shl 4 + LongInt( Ofs( BIOSBlk ) ), 32768 );
                         BlockWrite( savefile, BIOSBlk, 32768 );
                         X2 := X2 + 32768;
                        End;


                      close(savefile);
                      writeln( Msg( 48 ) );
                      end;
end; *)

 {Abort if option ROM is not a recognised flash ROM. This to avoid  }
 {the corruption of memory local to the PCI card as much as possible}
 If PCIOR and ( FlashError <> 0 ) then
  Err( Msg( 49 ) );

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
     2   : MaxBlock := FlashSize div FlashInfo^.Count;
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
   If PCIOr then
    Begin
     FlashBase := ROMBase;
     FlashSize := FlashSize shl 9;
    End else
    Begin
     FlashSize := 131072;    {128K default}
     FlashBase := $FFFE0000; {same}
     ROMBase := FlashBase;
    End;
   OldBIOS := AllocLinBlock( FlashSize );
   If ( OldBIOS = 0 ) then
    Err( Msg( 50 ) );
  End;
 textcolor(yellow);
 GotoXY( 2, 4 );
 Write( Msg( 51 ) );
 With FlashInfo^ do
  Begin
   TextColor( 15 );
   If FlashError <> 0 then Write( Msg( 52 ) ) else
    Begin
     If Count > 1 then Write( Count, ' x ' );
     Write( Manuf^, ' ', Name^ );
    End;
   If ForceId then
    Write( ' (forced)' ) else
   If Debug then
    Begin
     GotoXY( 1, 4 ); {v1.21}
     Write(' (' + Hb( Man1 ) + Hb( Dev1 ) +
           ',' + Hb( Man2 ) + Hb( Dev2 ) + ')' );
    End;
   GotoXY( 2, 5 );
   TextColor(yellow);
   Write( Msg( 53 ) );
   TextColor( 15 );
   If FlashError <> 0 then Write( Msg( 54 ) ) else
    Begin
     Case Flags and 3 of
      0 : Begin
           Write( Msg( 55 ) );
           If Count > 1 then Write( Count, ' x (' );
           For X := 0 to 4 do With FlashInfo^ do {v1.21 3->4}
            Begin
             If Sectors[ X, 0 ] = 0 then Break;
             If X > 0 then Write( ',' );
             Write( Sectors[ X, 0 ], 'x' );
             if Sectors[ X, 1 ] >= 8 then Write( ( Word( Sectors[ X, 1 ] ){ + 1} ) shr 3{shl 1}, 'k' ) {v1.21}
              else Write( ( Word( Sectors[ X, 1 ] ){ + 1} ) shl 7{shl 1}, 'b' );
            End;
           If Count > 1 then Write( ')' );
          End;
      1 : Begin
           If Count > 1 then Write( Count, ' x ' );
           Write( ( ( LongInt( Size ) shl 10 ) div Count ) div PgSize );
           Write( Msg( 56 ), pgsize, Msg( 57 ) );
          End;
      2 : Write( Msg( 58 ) );
      3 : Begin
           If Count > 1 then Write( Count, ' x ' );
           Write( ( ( LongInt( Size ) shl 10 ) div Count ) div PgSize );
           Write( Msg( 59 ), pgsize, Msg( 57 ) );
          End;
     End;
     If ( Size and 1023 ) <> 0 then
      Write( ' (', Size, 'K)' )
     else
      Write( ' (', Size shr 10, 'M)' );
    End;
  End;
 GotoXY( 11, 7 );

 If AutoSave then
  Begin
   WriteBIOSImg;
   GotoXY( 1, Hi( WindMax ) );
  End;

 If Emergency then
  Begin
   If FlashError <> 0 then Err( Msg( 60 ) );
   Beep( 1000, 500 ); {single beep, start reading}
   Assign( IFile, EmFName );
   Reset( IFile, 1 );
   If IOResult <> 0 then Err( Msg( 8 ) + EMFName + Msg( 95 ) );
   FlashFile( IFile, True {force boot block write, from personal experience}
                          {I really think that it can't be avoided !!      } );
   Close( IFile );
   {double beep : flash done}
   Beep( 1000, 200 );
   Delay( 20 );
   Beep( 1000, 200 );
   Halt;
  End;

 GotoXY( 2, 6 );
 TextColor(yellow);
 Write( Msg( 61 ) );
 TextColor( 15 );
 Write( CurrentChipset);
 GotoXY( 2, 7 );
 TextColor(yellow);
 Write( Msg( 62 ) );
 TextColor( 15 );
 Write( Msg( 63 ) );
 If Debug then
  Begin
(*   TextColor( yellow );
   GotoXY( 2, 9 );
   Write( Msg( 64 ) );
   TextColor( 15 );
   Write( Msg( 65 ), Hw( PiixMan ), Msg( 66 ), Hw( PIIXId ), Msg( 67 ), Hb( PiixL shr 3 ), ':',
          Hb( PiixL and 7 ) ); *)
   TextColor( yellow );
   GotoXY( 2, 1{3} ); {v1.21}
   Write( Msg( 68 ) );
   TextColor( 15 );
   Write( 'XMSPos=', Hl( XMSPos ), ', XMSLeft=', XMSLeft );
   TextColor( yellow );
   GotoXY( 2, 8 );
   Write( Msg( 69 ) );
   TextColor( 15 );
   Write( Hl( ROMBase )+ Msg( 70 ) +hl(rombase)+'-->('+hw(fimemw(rombase))+hw(fimemw(rombase+2))+')' );
  End;

 If PCIOr then
  Begin
   TextColor( yellow );
   GotoXY( 2, 8 );
   Write( Msg( 71 ) );
   TextColor( 15 );
   Write( Msg( 72 ), Hb( ORBus ),
          ':', Hb( ORDev ),
          ':', Hb( ORFun ) );
  End;

 {Backup current BIOS}
 MoveLinBlockD( FlashBase, OldBIOS, FlashSize );
 {Backup CMOS data}
 For X := $10 to CMOSSize do
  Begin
   Port[ $70 ] := X;
   CMOSBack[ X ] := Port[ $71 ];
  End;

 textcolor(WHITE);

 PnPDMIMenu :=
  AddMenuItem( Msg( 73 ),
               0, 1, @WritePnp,
  AddMenuItem( Msg( 74 ),
               1, 1, @FlashPnp,
  AddMenuItem( Msg( 75 ),
               2, 1, @ClearPnp,
  AddMenuItem( Msg( 76 ),
               3, 1, @WriteDMI,
  AddMenuItem( Msg( 77 ),
               4, 1, @FlashDMI,
  AddMenuItem( Msg( 78 ),
               5, 1, @ClearDMI,
  AddMenuItem( Msg( 79 ),
               7, 1, Nil,
  Nil ) ) ) ) ) ) );

 AdvMenu :=
  AddMenuItem( Msg( 80 ),
               0, 1, @SaveCMOS,
  AddMenuItem( Msg( 81 ),
               1, 1, @RestoreCMOS,
  AddMenuItem( Msg( 82 ),
               2, 1, @FlashBIOSBB,
  AddMenuItem( Msg( 83 ),
               3, 1, @WriteBootBlk,
  AddMenuItem( Msg( 84 ),
               4, 1, @FlashBootBlk,
  AddMenuItem( Msg( 79 ),
               6, 1, Nil,
  Nil ) ) ) ) ) );

 MainMenu :=
  AddMenuItem( Msg( 85 ),
               0, 1, @WriteBIOSImg,
  AddMenuItem( Msg( 86 ),
               1, 1, @FlashBIOS,
  AddMenuItem( Msg( 87 ),
               2, 0, @FlashOldBIOS,
  AddMenuItem( Msg( 88 ),
               3, 1, @ClearCMOS,
  AddMenuItem( Msg( 89 ),
               4, 0, @WrtOldCMOS,
  AddMenuItem( Msg( 90 ),
               5, 3, PnPDMIMenu,
  AddMenuItem( Msg( 91 ),
               6, 3, AdvMenu,
  AddMenuItem( Msg( 92 ),
               7, 1, @biosinfo,
  AddMenuItem( Msg( 93 ),
               9, 1, Nil,
  Nil ) ) ) ) ) ) ) ) );

 If FlashInfo = Nil then
  Begin
   SetMenuItemStatus( MainMenu, 1, False );
   SetMenuItemStatus( MainMenu, 5, False );
   SetMenuItemStatus( AdvMenu, 2, False );
   SetMenuItemStatus( AdvMenu, 3, False );
   SetMenuItemStatus( AdvMenu, 4, False );
  End;
 If ( FlashInfo^.Flags and 3 ) = 2 then
  SetMenuItemStatus( MainMenu, 5, False );

 If not Expert or PCIOR then
  Begin
   SetMenuItemStatus( MainMenu, 5, False );
   SetMenuItemStatus( MainMenu, 6, False );
  End;

 If PCIOR then
  Begin
   SetMenuItemStatus( MainMenu, 3, False );
   SetMenuItemStatus( MainMenu, 4, False );
  End;

 VErr := False;
 Repeat
  RunMenu( MainMenu );
  If VErr then
   Begin
    TextColor( 12 );
    GotoXY( 11, 22 );
    Write( Msg( 94 ) );
    Repeat A := UpCase( ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
    GotoXY( 11, 22 );
    ClrEol;
   End;
 Until ( not VErr ) or ( A = AnswYes );

 GotoXY( 1, Hi( WindMax ) );
end.