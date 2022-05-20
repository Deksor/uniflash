{$M 16384, 0, 16384}
{$I-}
{$S-}
{$R-}
{$G+}
Program Uniflash;

Uses Crt, Dos,
     Flash, Pci, Tools, GenFlash,
     Intel, Atmel, SST, Winbond, AMD, Catalyst, Macronix, AMIC, Alliance,
     ISSI, Mosel, EON, PMC, Hyundai, IMT, ST, TI, Fujitsu,
     Language, English, French, Dutch, Italian;


Const
Emergency   : Boolean = False;
PCIOREn     : Boolean = False;
PCIOR       : Boolean = False;
SaveBIOS    : Boolean = False;
ForceId     : Boolean = False;
CMOS        : Boolean = False;

Var
M, D,
CurOp,
ORBus, OrDev,
ORFun, Z,
FlashNo,X,Y,
Count       : Byte; {v1.22}
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
CMOSMenu,   {v1.22}
MainMenu    : PMenuItem;
FlashInfo   : PChipInfo;
VErr,
Redir       : Boolean; {v1.22}
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
  LogWrite('Flashing '+_Str(Size)+'b long BIOS image to '+_Str(Start)); {v1.23}
  WrtProgressBar( Msg( 3 ) );
  VErr := False;
  For X := 0 to 31 do
   Begin
    If CompLinBlocks( X * ( Size shr 5 ) + FlashBase + Start,
                      X * ( Size shr 5 ) + BIOS, Size shr 5 )
     then Write( 'Û' ) else
      Begin
       Write( 'X' );
       VErr := True;
      End;
   End;
  If VErr then
   Begin
    TextColor( 12 );
    GotoXY( 2, 22 );
    If Emergency then Sound( 1000 ) else Write( #7 );
    Write( Msg( 4 ) );
    Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
    If Emergency then NoSound;
    GotoXY( 11, 22 );
    ClrEol;
   End;
 Until ( not VErr ) or ( A = AnswNo );
 ClearProgressBar;
 if ( not VErr ) and ( not Emergency ) then {v1.22 beep after successful flash}
  Begin
   Beep(  500, 100 );
   Beep( 1000, 100 );
   Beep( 1500, 100 );
   LogWrite('Flashing completed successfully'); {v1.23}
  End;
 if VErr then LogWrite('Flashing failed'); {v1.23}
End;


Procedure FlashFile( Var IFile : File; BB : Boolean );
Var
X, Pos : LongInt;

Begin
 if BB then LogWrite('Flashing BIOS including BootBlock')
  else LogWrite('Flashing BIOS without BootBlock'); {v1.23}
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
     Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
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
 If SaveBIOS then IName := EMFName else
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
 LogWrite('BIOS image saved to file '+IName); {v1.23}
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
     Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
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
     Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
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
   GotoXY( 32, 8 );
   ClrEol;
   GotoXY( 32, 8 );
   If VErr then
    Begin
     TextColor( LightRed );
     Write( Msg( 11 ) );
    End else
    Begin
     TextColor( LightGreen );
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
   LogWrite('Flashing '+Typ+' data from '+IName); {v1.23}
   FlashBIOSImg( ( LongInt( Seg( BIOSBlk ) ) shl 4 ) + LongInt( Ofs( BIOSBlk ) ),
                 Pos - FlashBase, 4096 );
   SetMenuItemStatus( MainMenu, 2, True );
   Close( IFile );
   GotoXY( 32, 8 );
   ClrEol;
   GotoXY( 32, 8 );
   If VErr then
    Begin
     TextColor( LightRed );
     Write( Msg( 11 ) );
    End else
    Begin
     TextColor( LightGreen );
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

(*{Flash DMI data from file to ROM}
Procedure FlashDMI; Far;
Begin
 FlashPnPDMI( 'DMI', $FFFFC000 );
End;*)

Procedure ClearPnPDMI( Typ : String; Pos : LongInt );
Begin
 TextColor( 12 );
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
                 Pos - FlashBase, 4096 );
   SetMenuItemStatus( MainMenu, 2, True );
   GotoXY( 32, 8 );
   ClrEol;
   GotoXY( 32, 8 );
   If VErr then
    Begin
     TextColor( LightRed );
     Write( Msg( 11 ) );
    End else
    Begin
     TextColor( LightGreen );
     Write( Msg( 12 ) );
    End;
  End;
End;

Procedure ClearPnP; Far;
Begin
 ClearPnPDMI( 'PNP', $FFFFD000 );
End;

(*Procedure ClearDMI; Far;
Begin
 ClearPnPDMI( 'DMI', $FFFFC000 );
End;*)

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
 LogWrite(Typ+' data saved to '+IName); {v1.23}
End;

Procedure WritePnP; Far;
Begin
 WritePnPDMIImg( 'PnP', $FFFFD000 );
End;

(*Procedure WriteDMI; Far;
Begin
 WritePnPDMIImg( 'DMI', $FFFFC000 );
End;*)

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
 LogWrite('BootBlock backup saved to '+IName);
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
   Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
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
   LogWrite('Flashing BootBlock from '+IName); {v1.23}
   FlashBIOSImg( ( LongInt( Seg( BIOSBlk ) ) shl 4 ) + LongInt( Ofs( BIOSBlk ) ),
                 $FFFFE000 - FlashBase, 8192 );
   SetMenuItemStatus( MainMenu, 2, True );
   Close( IFile );
   GotoXY( 32, 8 );
   ClrEol;
   GotoXY( 32, 8 );
   If VErr then
    Begin
     TextColor( LightRed );
     Write( Msg( 11 ) );
    End else
    Begin
     TextColor( LightGreen );
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
 Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
 GotoXY( 11, 22 );
 ClrEol;
 If A = AnswYes then
  Begin
   LogWrite('Flashing backup BIOS to Flash ROM'); {v1.23}
   FlashBIOSImg( OldBIOS, 0, FlashSize - 8192 );
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
 Port[$72]:=$10;
 S2:=Port[$73];
 if S1<>S2 then GetCMOSSize:=255
 else
  begin
    Port[$72]:=$10;
    Port[$73]:=S1 xor $55;
    Port[$70]:=$10;
    if Port[$71]<>(S1 xor $55) then GetCMOSSize:=255;
    Port[$70]:=$10;
    Port[$71]:=S1;
    Port[$72]:=$10;
    Port[$73]:=S2;
  end;
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
 TextColor( 12 );
 GotoXY( 2, 22 );
 Write( Msg( 21 ) );
 Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
 GotoXY( 2, 22 );
 ClrEol;
 If A = AnswYes then
  Begin
   CMOSClr;
   TextColor(12);
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
   SetMenuItemStatus( MainMenu, 4, True );
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
end;

{Write CMOS data to disk}
Procedure SaveCMOS; Far;
Var
IName : String;
IFile : File;

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
 CMOSWrite(IFile);
 Close( IFile );
 GotoXY( 11, 20 );
 ClrEol;
 LogWrite('CMOS settings saved to '+IName); {v1.23}
End;

function CMOSRestore(var IFile:File):Boolean; {v1.25}
var X,Z:Byte;
    OK:Boolean;
begin
 Z:=CMOSSize;
 if Z>127 then Z:=127;
 BlockRead(IFile,CMOSImg,CMOSSize-$0D);
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
   Write(Msg(26));
   Delay(2000);
  End;
 CMOSRestore:=OK;
end;

{Read CMOS data from disk}
Procedure RestoreCMOS; Far;
Var
IName : String;
IFile : File;

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
   If FileSize( IFile ) <> ( CMOSSize - $0D ) then
    Begin
     GotoXY( 11, 20 );
     Write( Msg( 98 ), CMOSSize - $0D, Msg( 99 ) );
     Delay( 2000 );
     GotoXY( 11, 20 );
     ClrEol;
     Close( IFile );
     Exit;
    End;
   if CMOSRestore(IFile) then LogWrite('CMOS settings restored from '+IName)
    else LogWrite('Error restoring CMOS settings - may be write protected');
   Close( IFile );
   SetMenuItemStatus( MainMenu, 4, True );
  End;
 GotoXY( 11, 20 );
 ClrEol;
End;


Procedure WrtOldCMOS; Far;
var X,Z:Byte;
    OK:Boolean;

Begin
 TextColor( 12 );
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
   TextColor(12);
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
 SetMenuItemStatus( MainMenu, 4, False );
 LogWrite('CMOS settings restored from backup in memory'); {v1.23}
End;

Procedure MyExitProc; Far;
Begin
 LogWrite('Exiting UniFlash...');
 If PCIOrEn then
  Begin
   SetPCIRegD( ORBus, ORDev, ORFun, $04, PCIReg4 );
   SetPCIRegD( ORBus, ORDev, ORFun, $30, PCIReg30 );
  End;
 TextColor( LightGray );
 RomEnable( Unmap );
 LogWrite('Turning off logging, shutting down to real mode');
 LogEnd;
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
 LogWrite( Msg ); {v1.23}
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

(*procedure BiosInfo; far; {v1.22 DISABLED}
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

end;*)

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
 If XMSLeft = -1 then
  Err( Msg( 37 ) );

 If not FlatRealOn then
  Err( Msg( 38 ) ) else LogWrite('Flat Real Mode initialized'); {v1.23}

 {Allocate high memory if XMS not present}
 AllocHimem;
end;

procedure ROMSelect; {v1.24}
begin
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
          Img := Img xor GetPCIRegD( OrBus, OrDev, OrFun, $30 ); {Now every 0 is a hw bit}
          {Scan for 1st non-hardwired bit}
          For Z := 1 to 32 do
           If ( Img and ( 1 shl LongInt( Z ) ) ) <> 0 then Break;
          {We don't support option ROM's at (semi-)fixed addresses}
          If ( Z < 32 ) and ( ( Img xor ( - ( 1 shl LongInt( Z ) ) ) ) = 0 ) then
           Begin
            {found PCI option ROM, add to list}
            Inc( OPRCnt );
            With OPRom[ OPRCnt ] do
             Begin
              MaxSize := 1 shl LongInt( Z );
              VenID := GetPCIRegD( OrBus, OrDev, OrFun, $00 );
              DevID := GetPCIRegD( OrBus, OrDev, OrFun, $00 ) shr 16;
              Bus := OrBus;
              Pos := ( OrDev shl 3 ) or OrFun;
             End;
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
      A := _ReadKey;
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
       If Hi( PCIReg30 shr 16 ) = $CB then {v1.22}
        SetPCIRegD( ORBus, ORDev, ORFun, $30, PCIReg30 or 1 )
       else SetPCIRegD( ORBus, ORDev, ORFun, $30, $80000001 );
       PCIOrEn := True;
       ROMBase := GetPCIRegD( ORBus, ORDev, ORFun, $30 ) and $FFFFFFFE{ $80000000}; {v1.22}
      End;

     Window( 1, 4, 80, 25 );
     ClrScr;
     Window( 1, 1, 80, 25 );
     GotoXY( 1, 3 );
     LogWrite( 'PCI expansion ROM at '+Hb(ORBus)+':'+Hb(ORDev)+':'+Hb(ORFun)+' selected' ); {v1.23}
    End else Err( Msg( 45 ) );
  End else
   Begin
    RomEnable( Map ); {Program the chipset so it lets you see the BIOS}
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
   If PCIOr then
    Begin
     FlashBase := ROMBase;
{     FlashSize := FlashSize shl 9;}
     FlashSize := OpROM[ CurOp ].MaxSize; {v1.22}
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
 GotoXY( 2, 5 );
 ClrEol;
 Write( Msg( 51 ) );
 With FlashInfo^ do
  Begin
   TextColor( 15 );
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
   TextColor(yellow);
   ClrEol;
   Write( Msg( 53 ) );
   TextColor( 15 );
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
end;

procedure XMSInfo; {v1.24}
begin
 TextColor( DarkGray );
 GotoXY( 1, 24 );
 Write( Msg( 68 ) );
 Write( 'XMSPos=', Hl( XMSPos ), ', XMSLeft=', XMSLeft );
 GotoXY( 1, 23 );
 Write( Msg( 69 ) );
 Write( Hl( ROMBase )+ Msg( 70 ) +hl(rombase)+'-->('+hw(fimemw(rombase))+hw(fimemw(rombase+2))+')' );
end;

procedure RedetectFlashROM;Far; {v1.24}
begin
 LogWrite('Restarting UniFlash...');
 If PCIOrEn then
  Begin
   SetPCIRegD( ORBus, ORDev, ORFun, $04, PCIReg4 );
   SetPCIRegD( ORBus, ORDev, ORFun, $30, PCIReg30 );
  End;
 RomEnable( Unmap );
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
 MoveLinBlockD( FlashBase, OldBIOS, FlashSize );
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
 CheckRedir; {v1.22 Check if STDOUT is redirected}

 ClrScr;
 GotoXY(11,2);
 TextColor(Yellow);
 Write('UniFlash ');
 TextColor(LightGreen);
 Write('v' + Version );
 TextColor(LightCyan);
 WriteLn(' (c) 2002 Rainbow Software (http://rainbow.ht.st)');
 TextColor(LightMagenta);
 GotoXY(11,3);
 Write('Original version by Pascal van Leeuwen & Galkowski Adam');
 TextColor(LightGray);

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
 PStr := Msg( 105 );
 AnswYes := PStr[ 1 ];
 AnswNo  := PStr[ 2 ];

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
     WrtCenter( 'UNIFLASH [-H|-?|[-E fname][-PCIOR|-AMI]' );
     WrtCenter( '          [-SAVE fname]|-CHIPLIST|-FORCE xxxx][-LOG]' );
     WrtCenter( '          [-CMOSS fname][-CMOSR fname][-CMOSC]]'); {v1.25}
     WrtCenter( '' );
     WrtCenter( Msg( 30 ) );
     WrtCenter( Msg( 31 ) );
     WrtCenter( Msg( 32 ) );
     WrtCenter( Msg( 34 ) );
     WrtCenter( Msg( 36 ) );
     WrtCenter( Msg( 107 ) );
     WrtCenter( Msg( 108 ) );
     WrtCenter( Msg( 109 ) );
     WrtCenter( Msg( 131 ) ); {v1.25}
     WrtCenter( Msg( 132 ) ); {v1.25}
     WrtCenter( Msg( 133 ) ); {v1.25}
     WriteLn;
     Halt;
    End else
   If PStr = 'PCIOR' then PCIOR := True else
   If PStr = 'AMI' then WantToUseAmi := True else
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
          if not WriteLnStd( '  '+ Hb( M )+ Hb( D )+ ' - '+ Manuf^+ ' '+ Name^ ) then Exit;
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
   If PStr = 'SAVE' then
    Begin
     Inc( X );
     If ParamCount < X then Err( Msg( 29 ) );
     SaveBIOS := True;
     EMFName := ParamStr( X );
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
    end;
   Inc( X );
  End;

 if CMOS and not Emergency and not SaveBIOS then Exit;
 If Windows then Err( Msg( 110 ) ); {v1.22}

 If not LocatePIIX then { Sets address of PIIX } {v1.22 moved here}
  Err( Msg( 111 ) ); {v1.22}

 LogWrite( 'Chipset detected: ' + CurrentChipset ); {v1.23}

 MemInit; {v1.24}

 CMOSSize := GetCMOSSize;
 LogWrite( 'CMOS size detected: '+_Str(CMOSSize+1)+'b'); {v1.25}

 OldExitProc := ExitProc;
 ExitProc := @MyExitProc;

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
  End else FlashInfo := FlashDetect;

(* {Abort if option ROM is not a recognised flash ROM. This to avoid  }
 {the corruption of memory local to the PCI card as much as possible}
 If PCIOR and ( FlashError <> 0 ) then
  Err( Msg( 49 ) );   disabled in v1.22 *)

 ROMType; {v1.24}

 If SaveBIOS then
  Begin
   WriteBIOSImg;
   GotoXY( 1, Hi( WindMax ) );
  End;

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
   {double beep : flash done}
   Beep( 1000, 200 );
   Delay( 50 ); {v1.22 changed 20 -> 50}
   Beep( 1000, 200 );
   Halt;
  End;

 GotoXY( 2, 7 );
 TextColor(yellow);
 Write( Msg( 61 ) );
 TextColor( 15 );
 Write( CurrentChipset);
 GotoXY( 2, 8 );
 TextColor(yellow);
 Write( Msg( 62 ) );
 TextColor( 15 );
 Write( Msg( 63 ) );

 XMSInfo; {v1.24}

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

 textcolor(WHITE);

 PnPDMIMenu := AddMenuItem( Msg( 73 ), Msg( 112 ), 0, 1, @WritePnp,
               AddMenuItem( Msg( 74 ), Msg( 113 ), 1, 1, @FlashPnp,
               AddMenuItem( Msg( 75 ), Msg( 114 ), 2, 1, @ClearPnp,
(*               AddMenuItem( Msg( 76 ), 4, 1, @WriteDMI,
               AddMenuItem( Msg( 77 ), 5, 1, @FlashDMI,
               AddMenuItem( Msg( 78 ), 6, 1, @ClearDMI,*)
               AddMenuItem( Msg( 79 ), Msg( 130 ), 4, 1, Nil, Nil ) ) ) ) {) ) )};

 AdvMenu := AddMenuItem( Msg( 82 ), Msg( 115 ), 0, 1, @FlashBIOSBB,
            AddMenuItem( Msg( 83 ), Msg( 116 ), 1, 1, @WriteBootBlk,
            AddMenuItem( Msg( 84 ), Msg( 117 ), 2, 1, @FlashBootBlk,
            AddMenuItem( Msg( 79 ), Msg( 130 ), 4, 1, Nil, Nil ) ) ) );

 CMOSMenu := AddMenuItem( Msg( 80 ), Msg( 118 ), 0, 1, @SaveCMOS,
             AddMenuItem( Msg( 81 ), Msg( 119 ), 1, 1, @RestoreCMOS,
             AddMenuItem( Msg( 88 ), Msg( 120 ), 2, 1, @ClearCMOS,
             AddMenuItem( Msg( 89 ), Msg( 121 ), 3, 0, @WrtOldCMOS,
             AddMenuItem( Msg( 79 ), Msg( 130 ), 5, 1, Nil, Nil ) ) ) ) );

 MainMenu := AddMenuItem( Msg( 85 ),  Msg( 122 ), 0, 1, @WriteBIOSImg,
             AddMenuItem( Msg( 86 ),  Msg( 123 ), 1, 1, @FlashBIOS,
             AddMenuItem( Msg( 87 ),  Msg( 124 ), 2, 0, @FlashOldBIOS,
             AddMenuItem( Msg( 100 ), Msg( 125 ), 3, 1, @RedetectFlashROM,
             AddMenuItem( Msg( 101 ), Msg( 126 ), 4, 3, CMOSMenu,
             AddMenuItem( Msg( 90 ),  Msg( 127 ), 5, 3, PnPDMIMenu,
             AddMenuItem( Msg( 91 ),  Msg( 128 ), 6, 3, AdvMenu,
{             AddMenuItem( Msg( 92 ), 7, 1, @BIOSInfo,}
             AddMenuItem( Msg( 93 ),  Msg( 129 ), 8, 1, Nil, Nil ) ) ) ) ) ) ) );

 If FlashInfo = Nil then
  Begin
   SetMenuItemStatus( MainMenu, 1, False );
   SetMenuItemStatus( MainMenu, 5, False );
   SetMenuItemStatus( MainMenu, 6, False );
{   SetMenuItemStatus( AdvMenu, 2, False );
   SetMenuItemStatus( AdvMenu, 3, False );
   SetMenuItemStatus( AdvMenu, 4, False );}
  End;
 If ( FlashInfo^.Flags and 3 ) = 2 then
  SetMenuItemStatus( MainMenu, 5, False );

 If PCIOR then
  Begin
   SetMenuItemStatus( MainMenu, 4, False );
   SetMenuItemStatus( MainMenu, 5, False );
   SetMenuItemStatus( MainMenu, 6, False );
  End;
 LogWrite('UniFlash running in interactive mode'); {v1.23}
 VErr := False;
 Repeat
  RunMenu( MainMenu );
  If VErr then
   Begin
    TextColor( 12 );
    GotoXY( 11, 22 );
    Write( Msg( 94 ) );
    Repeat A := UpCase( _ReadKey ) Until ( A = AnswYes ) or ( A = AnswNo );
    GotoXY( 11, 22 );
    ClrEol;
   End;
 Until ( not VErr ) or ( A = AnswYes );

 GotoXY( 1, Hi( WindMax ) );
end.