{$M 4096, 4096, 4096}
Uses Crt,Flash,Pci,Tools, GenFlash,
     SST, Winbond, AMD, Intel, Atmel,
     Catalyst, Macronix;


Const
Expert      : Boolean = False;
Emergency   : Boolean = False;
Debug       : Boolean = False;
PCIOREn     : Boolean = False;
PCIOR       : Boolean = False;
Version     = '1.15';

Var
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
SStarts     : ARRAY[ 0 .. 38 ] of LongInt;
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

Procedure FlashBlock( Block, Start, Size : LongInt );
Var
S,
X, Pos  : LongInt;
UpdStat,
NxtUpd  : Word;
Sector  : Boolean;
SPos, Y,
Z, W    : Byte;
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
       For Y := 0 to 3 do
        If Sectors[ Y, 0 ] = 0 then Break else
        For Z := 1 to Sectors[ Y, 0 ] do
         Begin
          X := X + ( LongInt( Sectors[ Y, 1 ] ) + 1 ) shl 11; {*2K}
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
       WrtProgressBar( 'Blanking in progress' );
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
   WrtProgressBar( 'Flashing in progress' );
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
   WrtProgressBar( 'Flashing in progress' );

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
  WrtProgressBar( 'Verifying data' );
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
(*    Delay( 50 );  {just cosmetic}  *)
   End;
  If VErr then
   Begin
    TextColor( 12 );
    GotoXY( 11, 22 );
    If Emergency then Sound( 1000 ) else Write( #7 );
    Write( 'FLASH DATA VERIFICATION ERROR. RETRY WRITE OPERATION [Y/N]?' );
    Repeat A := UpCase( ReadKey ) Until ( A = 'Y' ) or ( A = 'N' );
    If Emergency then NoSound;
    GotoXY( 11, 22 );
    ClrEol;
   End;
 Until ( not VErr ) or ( A = 'N' );
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
     GotoXY( 11, 22 );
     Write( 'WARNING: BOOTBLOCK MISMATCH !! PROCEED ANYWAY [Y,N]?' );
     Repeat A := UpCase( ReadKey ) Until ( A = 'Y' ) or ( A = 'N' );
     GotoXY( 11, 22 );
     ClrEol;
     If A = 'N' then
      Begin
       GotoXY( 11, 20 );
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
 GotoXY( 11, 20 );
 Write( 'Image file name: ' );
 ReadLn( IName );
 Assign( IFile, IName );
 Rewrite( IFile, 1 );
 If IOResult <> 0 then
  Begin
   GotoXY( 11, 20 );
   Write( 'Unable to create file ', IName, ' !'#7 );
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
 Write( 'Image file name: ' );
 ReadLn( IName );
 If IName <> '' then
  Begin
   Assign( IFile, IName );
   Reset( IFile, 1 );
   If IOResult <> 0 then
    Begin
     GotoXY( 11, 20 );
     Write( 'Unable to open file ', IName, ' !'#7 );
     Delay( 2000 );
     GotoXY( 11, 20 );
     ClrEol;
     Exit;
    End;
   If FileSize( IFile ) <> FlashSize then
    Begin
     TextColor( 12 );
     GotoXY( 11, 22 );
     Write( 'FILE SIZE DOES NOT MATCH FLASH ROM CHIP SIZE. PROCEED [Y,N]?' );
     Repeat A := UpCase( ReadKey ) Until ( A = 'Y' ) or ( A = 'N' );
     GotoXY( 11, 22 );
     ClrEol;
     If A = 'N' then
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
     Write( 'WARNING: ABOUT TO ALTER THE BOOT BLOCK. PROCEED [Y,N]?' );
     Repeat A := UpCase( ReadKey ) Until ( A = 'Y' ) or ( A = 'N' );
     GotoXY( 11, 22 );
     ClrEol;
     If A = 'N' then
      Begin
       GotoXY( 11, 20 );
       ClrEol;
       Close( IFile );
       Exit;
      End;
    End;

   FlashFile( IFile, BB );
   Close( IFile );
   GotoXY( 30, 7 );
   ClrEol;
   GotoXY( 30, 7 );
   If VErr then
    Begin
     TextColor( 12 );
     Write( 'ERROR' );
    End else
    Begin
     TextColor( 15 );
     Write( 'SUCCESS' );
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
 Write( Typ + ' data file name: ' );
 ReadLn( IName );
 If IName <> '' then
  Begin
   Assign( IFile, IName );
   Reset( IFile, 1 );
   If IOResult <> 0 then
    Begin
     GotoXY( 11, 20 );
     Write( 'Unable to open file ', IName, ' !'#7 );
     Delay( 2000 );
     GotoXY( 11, 20 );
     ClrEol;
     Exit;
    End;
   If FileSize( IFile ) <> 4096 then
    Begin
     GotoXY( 11, 20 );
     Write( 'Invalid file size - must be exactly 4K !'#7 );
     Delay( 2000 );
     GotoXY( 11, 20 );
     ClrEol;
     Close( IFile );
     Exit;
    End;
   BlockRead( IFile, BIOSBlk, 4096 );
   FlashBIOSImg( ( LongInt( Seg( BIOSBlk ) ) shl 4 ) + LongInt( Ofs( BIOSBlk ) ),
                 Pos - FlashBase, 4096 );
   SetMenuItemStatus( MainMenu, 2, True );
   Close( IFile );
   GotoXY( 30, 7 );
   ClrEol;
   GotoXY( 30, 7 );
   If VErr then
    Begin
     TextColor( 12 );
     Write( 'ERROR' );
    End else
    Begin
     TextColor( 15 );
     Write( 'SUCCESS' );
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
 Write( 'WARNING: YOU WILL LOSE ALL ', Typ, ' SETTINGS. PROCEED [Y,N]?' );
 Repeat A := UpCase( ReadKey ) Until ( A = 'Y' ) or ( A = 'N' );
 GotoXY( 11, 22 );
 ClrEol;
 If A = 'Y' then
  Begin
   FillChar( BIOSBlk, 4096, $FF );
   FlashBIOSImg( ( LongInt( Seg( BIOSBlk ) ) shl 4 ) + LongInt( Ofs( BIOSBlk ) ),
                 Pos - FlashBase, 4096 );
   SetMenuItemStatus( MainMenu, 2, True );
   GotoXY( 30, 7 );
   ClrEol;
   GotoXY( 30, 7 );
   If VErr then
    Begin
     TextColor( 12 );
     Write( 'ERROR' );
    End else
    Begin
     TextColor( 15 );
     Write( 'SUCCESS' );
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
 Write( Typ + ' data file name: ' );
 ReadLn( IName );
 Assign( IFile, IName );
 Rewrite( IFile, 1 );
 If IOResult <> 0 then
  Begin
   GotoXY( 11, 20 );
   Write( 'Unable to create file ', IName, ' !'#7 );
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
 Write( 'Bootblock file name: ' );
 ReadLn( IName );
 Assign( IFile, IName );
 Rewrite( IFile, 1 );
 If IOResult <> 0 then
  Begin
   GotoXY( 11, 20 );
   Write( 'Unable to create file ', IName, ' !'#7 );
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
 Write( 'Bootblock file name: ' );
 ReadLn( IName );
 If IName <> '' then
  Begin
   Assign( IFile, IName );
   Reset( IFile, 1 );
   If IOResult <> 0 then
    Begin
     GotoXY( 11, 20 );
     Write( 'Unable to open file ', IName, ' !'#7 );
     Delay( 2000 );
     GotoXY( 11, 20 );
     ClrEol;
     Exit;
    End;
   If FileSize( IFile ) <> 8192 then
    Begin
     GotoXY( 11, 20 );
     Write( 'Invalid file size - must be exactly 8K !'#7 );
     Delay( 2000 );
     GotoXY( 11, 20 );
     ClrEol;
     Close( IFile );
     Exit;
    End;
   TextColor( 12 );
   GotoXY( 11, 22 );
   Write( 'WARNING: ABOUT TO ALTER THE BOOT BLOCK. PROCEED [Y,N]?' );
   Repeat A := UpCase( ReadKey ) Until ( A = 'Y' ) or ( A = 'N' );
   GotoXY( 11, 22 );
   ClrEol;
   If A = 'N' then
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
   GotoXY( 30, 7 );
   ClrEol;
   GotoXY( 30, 7 );
   If VErr then
    Begin
     TextColor( 12 );
     Write( 'ERROR' );
    End else
    Begin
     TextColor( 15 );
     Write( 'SUCCESS' );
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
 Write( 'FLASH THE BACKUP BIOS IMAGE BACK INTO THE FLASH ROM [Y,N]?' );
 Repeat A := UpCase( ReadKey ) Until ( A = 'Y' ) or ( A = 'N' );
 GotoXY( 11, 22 );
 ClrEol;
 If A = 'Y' then
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
 GotoXY( 11, 22 );
 Write( 'WARNING: YOU WILL LOSE ALL BIOS SETTINGS. PROCEED [Y,N]?' );
 Repeat A := UpCase( ReadKey ) Until ( A = 'Y' ) or ( A = 'N' );
 GotoXY( 11, 22 );
 ClrEol;
 If A = 'Y' then
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
     Write( 'CLEARED ', CMOSSize, ' BYTES OF CMOS RAM.'#7 );
     Delay( 1000 );
    End else
    Begin
     Write( 'ERROR CLEARING CMOS RAM - MAY BE (PARTIALLY) WRITE PROTECTED.'#7 );
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
 Write( 'CMOS data file name: ' );
 ReadLn( IName );
 Assign( IFile, IName );
 Rewrite( IFile, 1 );
 If IOResult <> 0 then
  Begin
   GotoXY( 11, 20 );
   Write( 'Unable to create file ', IName, ' !'#7 );
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
 Write( 'CMOS data file name: ' );
 ReadLn( IName );
 If IName <> '' then
  Begin
   Assign( IFile, IName );
   Reset( IFile, 1 );
   If IOResult <> 0 then
    Begin
     GotoXY( 11, 20 );
     Write( 'Unable to open file ', IName, ' !'#7 );
     Delay( 2000 );
     GotoXY( 11, 20 );
     ClrEol;
     Exit;
    End;
   If FileSize( IFile ) <> ( CMOSSize - $10 ) then
    Begin
     GotoXY( 11, 20 );
     Write( 'Invalid file size - must be exactly ', CMOSSize - $10, ' bytes !'#7 );
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
     Write( 'ERROR WRITING TO CMOS RAM - MAY BE (PARTIALLY) WRITE PROTECTED.'#7 );
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
 Write( 'WRITE BACK OLD CMOS DATA [Y,N]?' );
 Repeat A := UpCase( ReadKey ) Until ( A = 'Y' ) or ( A = 'N' );
 GotoXY( 11, 22 );
 ClrEol;
 If A = 'Y' then
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
     Write( Size - $10, ' BYTES OF CMOS RAM WRITTEN.'#7 );
     Delay( 1000 );
    End else
    Begin
     Write( 'ERROR WRITING CMOS RAM - MAY BE (PARTIALLY) WRITE PROTECTED.'#7 );
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


{---------------------- MAIN PART OF THE PROGRAM -------------------------}

Begin
 ClrScr;
 GotoXY(11,3);
 textcolor(yellow);
 Write('UniFlash ');
 textcolor(lightgreen);
 Write('V' + Version );
 textcolor(lightcyan);
 Write(' (C) 1997 Pascal van Leeuwen & Galkowski Adam ',#13,#10);
 textcolor(lightgray);

 X := 1;
 While ParamCount >= X do
  Begin
   PStr := OpStr( ParamStr( X ) );
   If ( PStr = 'E' ) then
    Begin
     Inc( X );
     If ParamCount < X then Err( 'Missing file name with option -E' );
     Emergency := True;
     EMFName := ParamStr( X );
    End else
   If ( PStr = 'H' ) or ( PStr = '?' ) then
    Begin
     WriteLn;
     WriteLn;
     WrtCenter( 'UNIFLASH [-H|-?|-E fname|-EXPERT|-PCIOR] ' );
     WrtCenter( '' );
     WrtCenter( '-H or -?        Shows this help screen' );
     WrtCenter( '-E fname        Flashes bios image from file fname to Flash' );
     WrtCenter( '                ROM without any user intervention.' );
     WrtCenter( '-EXPERT         Enables some more advanced menu options' );
     WrtCenter( '-PCIOR          Flash PCI option ROM instead of system ROM' );
     WriteLn;
     Halt;
    End else
   If PStr = 'EXPERT' then Expert := True else
   If PStr = 'DEBUG' then Debug := True else
   If PStr = 'PCIOR' then PCIOR := True;
   Inc( X );
  End;

 InitXMS; {Init memory subsystem. Should be done before FlatRealOn}
 If XMSLeft = -1 then
  Err('Unable to access memory beyond 1Mb - try using HIMEM.SYS.');

 If not FlatRealOn then
  Err('Sorry, but either you don''t have a 486+ either CPU is in V86 mode.');

 {Allocate high memory if XMS not present}
 AllocHimem;

 CMOSSize := GetCMOSSize;
 RomEnable( Map );

 OldExitProc := ExitProc;
 ExitProc := @MyExitProc;

 ROMBase := 0;  {standard system BIOS}

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
                {found PCI option ROM, add to list}  *)
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
     WrtCenter( 'Select PCI option ROM from list below:' );
     WriteLn;
     TextColor( 15 );
     For X := 1 to OPRCnt do With OpROM[ X ] do
      Begin
       Write( '          ', Char( X + 48 ), '. ' );
       WriteLn( 'Bus ', Hb( Bus ),
                ' device ', Hb( Pos shr 3 ),
                ' function ', Hb( Pos and 7 ),
                ' (VID=', Hw( VenId ),
                ', DID=', Hw( DevId ),
                ', ', MaxSize shr 10, 'K max)' );

      End;
     WriteLn;
     WrtCenter( '0. Quit' );
     WriteLn;
     WrtCenter( 'Select: 0' );
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

    End else Err( 'No PCI option ROMs found.' );
  End;

 FlashInfo := FlashDetect;

 {Abort if option ROM is not a recognised flash ROM. This to avoid  }
 {the corruption of memory local to the PCI card as much as possible}
 If PCIOR and ( FlashError <> 0 ) then
  Err( 'Selected device''s option ROM is not a supported Flash ROM.' );

 If FlashError = 0 then
  Begin
   FlashSize := LongInt( FlashInfo^.Size ) shl 10;
   FlashBase := ROMBase;
   With FlashInfo^ do
    Case Flags and 3 of
     0   : Begin
            MaxBlock := 0;
            For X := 0 to 3 do
             Begin
              If Sectors[ X, 0 ] = 0 then Break;
              If Sectors[ X, 1 ] > MaxBlock then
               MaxBlock := Sectors[ X, 1 ];
             End;
            MaxBlock := ( MaxBlock + 1 ) shl 11;
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
    Err( 'Not enough free memory.' );
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
    End;
   OldBIOS := AllocLinBlock( FlashSize );
   If ( OldBIOS = 0 ) then
    Err( 'Not enough free memory.' );
  End;
 textcolor(yellow);
 GotoXY( 14, 5 );
 Write( 'Flash ROM chip: ' );
 With FlashInfo^ do
  Begin
   TextColor( 15 );
   If FlashError <> 0 then Write( 'UNKNOWN' ) else
    Begin
     If Count > 1 then Write( Count, ' x ' );
     Write( Manuf^, ' ', Name^ );
    End;
   If Debug then
    Write(' (' + Hb( Man1 ) + Hb( Dev1 ) +
          ',' + Hb( Man2 ) + Hb( Dev2 ) + ')' );
   GotoXY( 16, 6 );
   TextColor(yellow);
   Write( 'Organisation: ' );
   TextColor( 15 );
   If FlashError <> 0 then Write( 'N/A' ) else
    Begin
     Case Flags and 3 of
      0 : Begin
           Write( 'sectored: ' );
           If Count > 1 then Write( Count, ' x (' );
           For X := 0 to 3 do With FlashInfo^ do
            Begin
             If Sectors[ X, 0 ] = 0 then Break;
             If X > 0 then Write( ',' );
             Write( Sectors[ X, 0 ], 'x' );
             Write( ( Word( Sectors[ X, 1 ] ) + 1 ) shl 1, 'k' );
            End;
           If Count > 1 then Write( ')' );
          End;
      1 : Begin
           If Count > 1 then Write( Count, ' x ' );
           Write( ( ( LongInt( Size ) shl 10 ) div Count ) div PgSize );
           Write( ' pages of ', pgsize, ' bytes' );
          End;
      2 : Write( 'bulk erase' );
      3 : Begin
           If Count > 1 then Write( Count, ' x ' );
           Write( ( ( LongInt( Size ) shl 10 ) div Count ) div PgSize );
           Write( ' sectors of ', pgsize, ' bytes' );
          End;
     End;
     If ( Size and 1023 ) <> 0 then
      Write( ' (', Size, 'K)' )
     else
      Write( ' (', Size shr 10, 'M)' );
    End;
  End;
 GotoXY( 11, 7 );

 If Emergency then
  Begin
   If FlashError <> 0 then Err( 'Unknown flash chip !' );
   Beep( 1000, 500 ); {single beep, start reading}
   Assign( IFile, EmFName );
   Reset( IFile, 1 );
   If IOResult <> 0 then Err( 'Unable to open file ' + EMFName + ' !' );
   FlashFile( IFile, True {force boot block write, from personal experience}
                          {I really think that it can't be avoided !!      } );
   Close( IFile );
   {double beep : flash done}
   Beep( 1000, 200 );
   Delay( 20 );
   Beep( 1000, 200 );
   Halt;
  End;

 TextColor(yellow);
 Write( 'Last write status: ' );
 TextColor( 15 );
 Write( 'not available' );
 If Debug then
  Begin
   TextColor( yellow );
   GotoXY( 16, 9 );
   Write( 'South bridge: ' );
   TextColor( 15 );
   Write( 'Vendor=', Hw( PiixMan ), ', Device=', Hw( PIIXId ), ' at ', Hb( PiixL shr 3 ), ':',
          Hb( PiixL and 7 ) );
   TextColor( yellow );
   GotoXY( 22, 4 );
   Write( 'Memory: ' );
   TextColor( 15 );
   Write( 'XMSPos=', Hl( XMSPos ), ', XMSLeft=', XMSLeft );
   TextColor( yellow );
   GotoXY( 20, 8 );
   Write( 'ROM base: ' );
   TextColor( 15 );
   Write( Hl( ROMBase ) );
  End;

 If PCIOr then
  Begin
   TextColor( yellow );
   GotoXY( 14, 8 );
   Write( 'Option ROM for: ' );
   TextColor( 15 );
   Write( 'device at ', Hb( ORBus ),
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
  AddMenuItem( 'Write ESCD (PnP data) to disk',
               0, 1, @WritePnp,
  AddMenuItem( 'Flash ESCD (PnP data) image to Flash ROM',
               1, 1, @FlashPnp,
  AddMenuItem( 'Clear ESCD (PnP data)',
               2, 1, @ClearPnp,
  AddMenuItem( 'Write DMI data to disk',
               3, 1, @WriteDMI,
  AddMenuItem( 'Flash DMI data image to Flash ROM',
               4, 1, @FlashDMI,
  AddMenuItem( 'Clear DMI data',
               5, 1, @ClearDMI,
  AddMenuItem( 'Back to main menu',
               7, 1, Nil,
  Nil ) ) ) ) ) ) );

 AdvMenu :=
  AddMenuItem( 'Save CMOS data to disk',
               0, 1, @SaveCMOS,
  AddMenuItem( 'Restore CMOS data from disk',
               1, 1, @RestoreCMOS,
  AddMenuItem( 'Flash BIOS image INCLUDING bootblock',
               2, 1, @FlashBIOSBB,
  AddMenuItem( 'Write boot block to disk',
               3, 1, @WriteBootBlk,
  AddMenuItem( 'Flash bootblock to Flash ROM',
               4, 1, @FlashBootBlk,

  AddMenuItem( 'Back to main menu',
               6, 1, Nil,
  Nil ) ) ) ) ) );

 MainMenu :=
  AddMenuItem( 'Write old BIOS image to disk',
               0, 1, @WriteBIOSImg,
  AddMenuItem( 'Flash BIOS image to Flash ROM',
               1, 1, @FlashBIOS,
  AddMenuItem( 'Flash back old BIOS image',
               2, 0, @FlashOldBIOS,
  AddMenuItem( 'Clear CMOS data',
               3, 1, @ClearCMOS,
  AddMenuItem( 'Write back old CMOS data',
               4, 0, @WrtOldCMOS,
  AddMenuItem( 'ESCD (PnP) and DMI submenu',
               5, 3, PnPDMIMenu,
  AddMenuItem( 'Advanced submenu',
               6, 3, AdvMenu,
  AddMenuItem( 'Quit',
               8, 1, Nil,
  Nil ) ) ) ) ) ) ) );

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
    Write( 'LAST FLASH WRITE WAS UNSUCCESFULL. QUIT ANYHOW [Y/N]?'#7 );
    Repeat A := UpCase( ReadKey ) Until ( A = 'Y' ) or ( A = 'N' );
    GotoXY( 11, 22 );
    ClrEol;
   End;
 Until ( not VErr ) or ( A = 'Y' );

 GotoXY( 1, Hi( WindMax ) );
end.
