{$M 16384, 0, 16384}
{$I-}
{$S-}
{$R-}
{$G+}

Program Uniflash;

Uses Crt, Dos,
Flash, PCI, PCICards, Tools, GenFlash, CT_Flash, DMI,
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
  Unlock      : Boolean = False;
  Reboot      : Boolean = False;
  BaseForced  : LongInt = 0;

Var 
  M,D,Z,X,Y,
  Count       : Byte; {v1.22}
  Int         : Integer;
  BIOSBlk     : ARRAY[ 0 .. 32767 ] Of Byte;
  FlashName   : ^String;
  OldExitProc : FarPointer;
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
  CMOSBack    : ARRAY[ $0E .. $FF ] Of Byte;
  Img,
  PCIReg4,
  PCIReg30,
  ScanPos,
  MaxBlock,
  TempBuf     : LongInt;
  SStarts     : ARRAY[ 0 .. 512 ] Of LongInt; {38 -> 512 v1.21}
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
  AskFor2 := True;
  X := WhereX;
  Y := WhereY;
  GotoXY(13,Y+1+l);
  Write(Txt);
  Repeat
    Answer := UpCase( _ReadKey );
  Until ( Answer = AnswYes ) Or ( Answer = AnswNo );
  AskFor2 := Answer = AnswYes;
  WriteLn;
  X2 := WhereX;
  Y2 := WhereY;
  GotoXY(13,Y+1+l);
  ClrEol;
  GotoXY(X,Y);
End;

Function AskFor(L : Byte;Txt : String) : Boolean;

Var X,Y : Byte;

Begin
  X := WhereX;
  Y := WhereY;
  AskFor := AskFor2( L, Txt );
  GotoXY( X,Y );
End;

Procedure ErrorMsg(Message:String); {v1.28}
Begin
  GotoXY(1,20);
  ClrEol;
  GotoXY(18,20);
  Write(Message);
  Delay(2000);
  GotoXY(1,20);
  ClrEol;
End;

Function IOError: Boolean; {v1.28}

Var Error: byte;
  Message: String;
Begin
  IOError := False;
  Error := IOResult;
  If Error=0 Then Exit;
  IOError := True;
  Message := 'Error #'+IntToStr(Error)+': ';
  Case Error Of 
    2,18: Message := Message+'File not found.';
    3: Message := Message+'Path not found.';
    4: Message := Message+'Too many open files.';
    5: Message := Message+'Access denied.';
    6: Message := Message+'Invalid file handle.';
    15: Message := Message+'Drive error.';
    19,150: Message := Message+'Disk is write protected.';
    20: Message := Message+'Unknown drive.';
    21,152: Message := Message+'Drive is not ready.';
    23: Message := Message+'CRC Error.';
    25: Message := Message+'Seek error.';
    26: Message := Message+'Unknown media type.';
    27: Message := Message+'Sector not found.';
    100: Message := Message+'Disk read error.';
    101: Message := Message+'Disk full.';
    103: Message := Message+'File is not open.';
    183: Message := Message+'File is open in read-only mode.';
    Else Message := Message+'Unknown Error.';
  End;
  ErrorMsg(Message);
End;

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

Sector := ( FlashInfo^.Flags And 1 ) = 0;
Pos := 0;

Start := Start{ + FlashBase}; {v1.29}
If Sector Then
  Begin
    X := {FlashBase}0; {v1.29}
    SPos := 1;
    SStarts[ 0 ] := X;
    If ( ( FlashInfo^.Flags ) And 2 ) = 0 Then
      Begin
     {Make list with sector ends & sizes (=next sector starts)}
        With FlashInfo^ Do
          For W := 1 To 1{Count} Do
            For Y := 0 To 4 Do {v1.21 3->4}
              If Sectors[ Y, 0 ] = 0 Then Break
              Else
                For Z := 1 To Sectors[ Y, 0 ] Do
                  Begin
(*          X := X + ( LongInt( Sectors[ Y, 1 ] ) + 1 ) shl 11; {*2K}*)
                    X := X + LongInt( Sectors[ Y, 1 ] ) shl 7; {*128} {v1.21}
                    SStarts[ SPos ] := X;
                    Inc( SPos );
                  End;
      End
    Else
      Begin
     {Bulk erase chip}
        For W := 1 To {FlashInfo^.Count}1 Do
          Begin
            X := X + ( FlashSize {div FlashInfo^.Count} );
            SStarts[ SPos ] := X;
            Inc( SPos );
          End;
     {Might need blanking prior to erase}
        If ( FlashInfo^.Flags And 4 ) <> 0 Then
          Begin
            WrtProgressBar( Msg( 1 ) );
            FillLinBlockD( TempBuf, FlashInfo^.PgSize, 0 );
            UpdStat := ( FlashSize Div FlashInfo^.PgSize + 31 ) shr 5;
            NxtUpd := UpdStat;
            For X := 0 To ( FlashSize Div FlashInfo^.PgSize ) - 1 Do
              Begin
                Dec( NxtUpd );
                If NxtUpd = 0 Then
                  Begin
                    If FlashError=0 Then TextColor(Green)
                    Else TextColor(Red);
                    Write( '�' );
                    NxtUpd := UpdStat;
                  End;
                FlashProgram( {FlashBase +} X, TempBuf ); {v1.29}
              End;
          End;
      End;
    WrtProgressBar( Msg( 2 ) );
    SPos := 0;
    While Start >= SStarts[ SPos + 1 ] Do
      Inc( SPos ); {Find starting sector}

   {Calculate the actual size in bytes we physically need to write}
    X := SStarts[ SPos ];
    S := ( SStarts[ SPos + 1 ] - Start );
    Y := SPos + 1;
    While ( S < Size ) And ( (Size-S) >= (SStarts[Y+1] - SStarts[Y] ) ) Do
      Begin
        S := S + ( SStarts[ Y + 1 ] - SStarts[ Y ] );
        Inc( Y );
      End;
    If S <> Size Then Inc( Y );
    X := SStarts[ Y ] - X;
   {And use physical size to calculate status bar values}
    UpdStat := ( X Div FlashInfo^.PgSize + 31 ) shr 5;
    NxtUpd := UpdStat;

   {Write first unaligned and/or partial sector if necessary}
    S := SStarts[ SPos + 1 ] - SStarts[ SPos ];
    If ( Start <> SStarts[ SPos ] ) Or
       ( Size < S ) Then
      Begin
        MoveLinBlockD( SStarts[ SPos ],
                      TempBuf, S );
        S := S - ( Start - SStarts[ SPos ] );
        If S > Size Then S := Size;
        MoveLinBlockD( Block, TempBuf + ( Start - SStarts[ SPos ] ), S );

        FlashErase( SStarts[ SPos ] );  {Clear sector}
        For X := 0 To ( ( SStarts[ SPos + 1 ] -
            SStarts[ SPos ] ) Div FlashInfo^.PgSize ) - 1 Do
          Begin
            Dec( NxtUpd );
            If NxtUpd = 0 Then
              Begin
                If FlashError=0 Then TextColor(Green)
                Else TextColor(Red);
                Write( '�' );
                NxtUpd := UpdStat;
              End;
            FlashProgram( SStarts[ SPos ] + ( X * FlashInfo^.PgSize ),
            TempBuf + ( X * FlashInfo^.PgSize ) );
          End;
        Inc( SPos );
        Pos := SStarts[ SPos ] - Start;
      End;

   {Copy aligned sectors}
    While ( Pos < Size ) And
          ( ( Size - Pos ) >= ( SStarts[ SPos + 1 ] - SStarts[ SPos ] ) ) Do
      Begin
        FlashErase( SStarts[ SPos ] );  {Clear sector}
        For X := 0 To ( ( SStarts[ SPos + 1 ] -
            SStarts[ SPos ] ) Div FlashInfo^.PgSize ) - 1 Do
          Begin
            Dec( NxtUpd );
            If NxtUpd = 0 Then
              Begin
                If FlashError=0 Then TextColor(Green)
                Else TextColor(Red);
                Write( '�' );
                NxtUpd := UpdStat;
              End;
            FlashProgram( SStarts[ SPos ] + ( X * FlashInfo^.PgSize ), Block +
            Pos );
            Pos := Pos + FlashInfo^.PgSize;
          End;
        Inc( SPos );
      End;

   {Write last partial sector if necessary}
    S := SStarts[ SPos + 1 ] - SStarts[ SPos ];
    If ( Pos <> Size ) Then
      Begin
        MoveLinBlockD( SStarts[ SPos ],
                      TempBuf, S );
        MoveLinBlockD( Block + Pos, TempBuf, Size - Pos );
        FlashErase( SStarts[ SPos ] );  {Clear sector}
        For X := 0 To ( ( SStarts[ SPos + 1 ] -
            SStarts[ SPos ] ) Div FlashInfo^.PgSize ) - 1 Do
          Begin
            Dec( NxtUpd );
            If NxtUpd = 0 Then
              Begin
                If FlashError=0 Then TextColor(Green)
                Else TextColor(Red);
                Write( '�' );
                NxtUpd := UpdStat;
              End;
            FlashProgram( SStarts[ SPos ] + ( X * FlashInfo^.PgSize ),
            TempBuf + ( X * FlashInfo^.PgSize ) );
          End;
      End;
  End
Else
  Begin
    UpdStat := ( Size Div FlashInfo^.PgSize + 31 ) shr 5;
    NxtUpd := UpdStat;
    WrtProgressBar( Msg( 2 ) );

   {Write first unaligned and/or partial page if necessary}
    If ( ( Start And ( FlashInfo^.PgSize - 1 ) ) <> 0 )
       Or ( Size < 128 ) Then
      Begin
        MoveLinBlockD( Start And Not ( FlashInfo^.PgSize - 1 ),
        TempBuf, FlashInfo^.PgSize );
        S := FlashInfo^.PgSize - ( Start And ( FlashInfo^.PgSize - 1 ) );
        If S > Size Then S := Size;
        MoveLinBlockD( Block, TempBuf + ( Start And ( FlashInfo^.PgSize - 1 ) ),
        S );
        FlashProgram( Start And Not ( FlashInfo^.PgSize - 1 ), TempBuf );
        Pos := S;
      End;

   {Copy aligned pages}
    While ( Pos < Size ) And
          ( ( Size - Pos ) >= FlashInfo^.PgSize ) Do
      Begin
        Dec( NxtUpd );
        If NxtUpd = 0 Then
          Begin
            If FlashError=0 Then TextColor(Green)
            Else TextColor(Red);
            Write( '�' );
            NxtUpd := UpdStat;
          End;
        FlashProgram( Start + Pos, Block + Pos );
        Pos := Pos + FlashInfo^.PgSize;
      End;

   {Write last partial page if necessary}
    If Pos <> Size Then
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
    LogWrite('Flashing '+_Str(Size)+'b long BIOS image to '+_Str(Start));
    {v1.23}
    WrtProgressBar( Msg( 3 ) );
    VErr := False;
    For X := 0 To 31 Do
      Begin
        If (Flash_Compare(X*(FlashSize shr 5)+Start,
           X*(FlashSize shr 5)+BIOS, FlashSize shr 5)) {v1.29}
           And (X*(FlashSize shr 5)<Size)
          Then Write( '�' )
        Else
          If X*(FlashSize shr 5)>=Size Then Write('�')
        Else
          Begin
            Write( 'X' );
            VErr := True;
          End;
      End;
    If VErr Then
      Begin
        Text_Color( 12 );
        GotoXY( 2, 22 );
        If Emergency Then Sound( 1000 )
        Else Write( #7 );
        Write( Msg( 4 ) );
        Repeat
          A := UpCase( _ReadKey )
        Until ( A = AnswYes ) Or ( A = AnswNo );
        If Emergency Then NoSound;
        GotoXY( 11, 22 );
        ClrEol;
      End;
  Until ( Not VErr ) Or ( A = AnswNo );
  If Not VErr Then {v1.22}
    Begin
      Beep(  500, 100 );
      Beep( 1000, 100 );
      Beep( 1500, 100 );
      LogWrite('Flashing completed successfully'); {v1.23}
    End;
  ClearProgressBar;
  If VErr Then LogWrite('Flashing failed'); {v1.23}
End;


Function FlashFile( Var IFile : File; BB : Boolean ): Boolean; {function-v1.28}

Var 
  X, Pos : LongInt;

Begin
  FlashFile := True;
  If BB Then LogWrite('Flashing BIOS including BootBlock')
  Else LogWrite('Flashing BIOS without BootBlock'); {v1.23}
  X := 0;
  While ( X < FileSize( IFile ) ) Do
    Begin
      BlockRead( IFile, BIOSBlk, 32768 );
      If IOError Then {v1.28}
        Begin
          FlashFile := False;
          ErrorMsg(Msg(64));
          Exit;
        End;
      MoveLinBlockD( ( LongInt( Seg( BIOSBlk ) ) shl 4 ) + LongInt( Ofs( BIOSBlk
      ) ), X + NewBIOS, 32768 );
      X := X + 32768;
    End;

  If Emergency Then
    Begin
      Delay( 1000 );
      Beep( 1000, 500 ); {2nd single beep: start flashing}
    End;

  Pos := FlashSize - FileSize( IFile );
  If BB Then
    FlashBIOSImg( NewBIOS, Pos, FileSize( IFile ) )
  Else
    Begin
      If Not Emergency And
         Not Flash_Compare(FlashSize-8192,NewBios+FlashSize-8192,8192) Then
        {v1.29}
        Begin
          Text_Color( 12 );
          GotoXY( 2, 22 );
          Write( Msg( 5 ) );
          Repeat
            A := UpCase( _ReadKey )
          Until ( A = AnswYes ) Or ( A = AnswNo );
          GotoXY( 2, 22 );
          ClrEol;
          If A = AnswNo Then
            Begin
              GotoXY( 2, 20 );
              ClrEol;
              FlashFile := False;
              Exit;
            End;
          Write( Msg( 49 ) ); {v1.30}
          Repeat
            A := UpCase( _ReadKey )
          Until ( A = AnswYes ) Or ( A = AnswNo );
          GotoXY( 2, 22 );
          ClrEol;
          If A = AnswNo Then
            Begin
{       GotoXY( 2, 20 );
       ClrEol;
       FlashFile:=False;
       Exit;}
              FlashBIOSImg( NewBIOS, Pos, FileSize( IFile ) - 8192 );
            End
          Else FlashBIOSImg( NewBIOS, Pos, FileSize( IFile ) );
        End
      Else FlashBIOSImg( NewBIOS, Pos, FileSize( IFile ) - 8192 );
    End;
  SetMenuItemStatus( MainMenu, 2, True );
End;


{Write old BIOS image to file with user supplied name}
Procedure WriteBIOSImg;

Var 
  IName : String;
  IFile : File;
  X     : LongInt;

Begin
  If SaveBIOS Then IName := SaveName
  Else
    Begin
      GotoXY( 18, 20 );
      Write( Msg( 6 ) );
      FInput(IName,'backup.bin',45); {v1.28}
    End;

  If IName <> '' Then
    Begin
      Assign( IFile, IName );
      Rewrite( IFile, 1 );
      If IOError Then
        Begin
          ErrorMsg(Msg(7)+IName+Msg(95));
          Exit;
        End;

      X := 0;
      While ( X < FlashSize ) Do
        Begin
          MoveLinBlockD( X + OldBIOS, LongInt(  Seg( BIOSBlk ) ) shl 4 + LongInt
          ( Ofs( BIOSBlk ) ), 32768 );
          BlockWrite( IFile, BIOSBlk, 32768 );
          If IOError Then {v1.28}
            Begin
              ErrorMsg(Msg(65));
              Close(IFile);
              IOError;
              Exit;
            End;
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
  If IName <> '' Then
    Begin
      Assign( IFile, IName );
      Reset( IFile, 1 );
      If IOError Then
        Begin
          ErrorMsg(Msg(8)+IName+Msg(95));
          Exit;
        End;
      If FileSize( IFile ) <> FlashSize Then
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
      If BB Then
        Begin
          Text_Color(LightRed);
          GotoXY( 11, 22 );
          Write( Msg( 10 ) );
          Repeat
            A := UpCase( _ReadKey )
          Until ( A = AnswYes ) Or ( A = AnswNo );
          GotoXY( 11, 22 );
          Text_Color(LightGray);
          ClrEol;
          If A = AnswNo Then
            Begin
              GotoXY( 11, 20 );
              ClrEol;
              Close( IFile );
              IOError;
              Exit;
            End;
        End;

      Done := FlashFile( IFile, BB );
      Close( IFile );
      IOError;
      If Done Then {v1.28}
        Begin
          GotoXY( 32, 8 );
          ClrEol;
          GotoXY( 32, 8 );
          If VErr Then
            Begin
              Text_Color( LightRed );
              Write( Msg( 11 ) );
            End
          Else
            Begin
              Text_Color( LightGreen );
              Write( Msg( 12 ) );
            End;
        End;
    End
  Else
    Begin
      GotoXY( 11, 20 );
      ClrEol;
    End;
End;

Procedure FlashBIOS;
Begin
  _FlashBIOS( False );
End;

Procedure FlashBIOSBB;
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

Procedure WriteBootBlk;

Var 
  IName : String;
  IFile : File;

Begin
  GotoXY( 18, 20 );
  Write( Msg( 19 ) );
  FInput(IName,'backup.boo',45); {v1.28}
  If IName<>'' Then {v1.28}
    Begin
      Assign( IFile, IName );
      Rewrite( IFile, 1 );
      If IOError Then
        Begin
          ErrorMsg(Msg(7)+IName+' !'#7);
          Exit;
        End;
      Flash_ReadBlock(FlashSize-8192,LongInt(Seg(BIOSBlk)) shl 4+LongInt(Ofs(
                                                                         BIOSBlk
      )),8192); {v1.29}
      BlockWrite( IFile, BIOSBlk, 8192 );
      If IOError Then {v1.28}
        Begin
          ErrorMsg(Msg(65));
          Close(IFile);
          IOError;
          Exit;
        End;
      Close( IFile );
      IOError;
      LogWrite('BootBlock backup saved to '+IName);
    End;
  GotoXY( 11, 20 );
  ClrEol;
End;

Procedure FlashBootBlk;

Var 
  IName : String;
  X     : LongInt;
  A     : Char;

Begin
  GotoXY( 18, 20 );
  Write( Msg( 19 ) );
  FInput(IName,'',45); {v1.28}
  If IName <> '' Then
    Begin
      Assign( IFile, IName );
      Reset( IFile, 1 );
      If IOError Then
        Begin
          ErrorMsg(Msg(8)+IName+' !'#7);
          Exit;
        End;
      If FileSize( IFile ) <> 8192 Then
        Begin
          ErrorMsg(Msg(96));
          Close( IFile );
          IOError;
          Exit;
        End;
      Text_Color( 12 );
      GotoXY( 11, 22 );
      Write( Msg( 10 ) );
      Repeat
        A := UpCase( _ReadKey )
      Until ( A = AnswYes ) Or ( A = AnswNo );
      GotoXY( 11, 22 );
      ClrEol;
      If A = AnswNo Then
        Begin
          GotoXY( 11, 20 );
          ClrEol;
          Close( IFile );
          IOError;
          Exit;
        End;

      BlockRead( IFile, BIOSBlk, 8192 );
      If IOError Then {v1.28}
        Begin
          ErrorMsg(Msg(64));
          Close(IFile);
          IOError;
          Exit;
        End;
      LogWrite('Flashing BootBlock from '+IName); {v1.23}
      FlashBIOSImg( ( LongInt( Seg( BIOSBlk ) ) shl 4 ) + LongInt( Ofs( BIOSBlk
      ) ),
                { $FFFFE000 - FlashBase}FlashSize-8192, 8192 ); {v1.29}
      SetMenuItemStatus( MainMenu, 2, True );
      Close( IFile );
      IOError;
      GotoXY( 32, 8 );
      ClrEol;
      GotoXY( 32, 8 );
      If VErr Then
        Begin
          Text_Color( LightRed );
          Write( Msg( 11 ) );
        End
      Else
        Begin
          Text_Color( LightGreen );
          Write( Msg( 12 ) );
        End;
    End
  Else
    Begin
      GotoXY( 11, 20 );
      ClrEol;
    End;
End;

{Flash BIOS backup back into flash chip}
Procedure FlashOldBIOS;
Begin
  Text_Color( 12 );
  GotoXY( 11, 22 );
  Write( Msg( 20 ) );
  Repeat
    A := UpCase( _ReadKey )
  Until ( A = AnswYes ) Or ( A = AnswNo );
  GotoXY( 11, 22 );
  ClrEol;
  If A = AnswYes Then
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
  GetCMOSSize := 127;

 {Backup values $10 and $50}
  Port[$70] := $10;
  S1 := Port[$71];
  Port[$70] := $50;
  S2 := Port[$71];
  If S1=S2 Then {If they are different then it is definately 128 bytes}
    Begin
    {Change $50, read back at $10}
      Port[$70] := $50;
      Port[$71] := S1 xor $55;
      Port[$70] := $10;
      X := Port[$71];
    {Write back old values}
      Port[$70] := $10;
      Port[$71] := S1;
      Port[$70] := $50;
      Port[$71] := S2;

    {If value read back is same as value written then we only have 64 bytes}
      If X=(S1 xor $55) Then
        Begin
          GetCMOSSize := 63;
          Exit;
        End;
    End;

  Port[$70] := $10;
  S1 := Port[$71];
  Port[$72] := $90; {v1.36}
  S2 := Port[$73];
  Port[$70] := $10;
  Port[$71] := $55;
  Port[$72] := $90; {v1.36}
  Port[$73] := $AA;
  Port[$70] := $10;
  If Port[$71]=$55 Then {v1.29}
    Begin
      Port[$72] := $90; {v1.36}
      If Port[$73]=$AA Then GetCMOSSize := 255;
    End;
  Port[$70] := $10;
  Port[$71] := S1;
  Port[$72] := $90; {v1.36}
  Port[$73] := S2;
End;

Function CMOSClr: Boolean;

Var X,Z: Byte;
  OK: Boolean;
Begin
  Z := CMOSSize;
  If Z>127 Then Z := 127;
 {Clear it}
  For X:=$0E To Z Do
    Begin
      Port[$70] := X;
      Port[$71] := $00;
    End;
  If CMOSSize>Z Then
    Begin
      For X:=$80 To $FF Do
        Begin
          Port[$72] := X;
          Port[$73] := $00;
        End;
    End;
 {Verify}
  OK := True;
  For X:=$0E To Z Do
    Begin
      Port[$70] := X;
      If Port[$71]<>$00 Then OK := False;
    End;
  If CMOSSize>Z Then
    For X:=$80 To $FF Do
      Begin
        Port[$72] := X;
        If Port[$73]<>$00 Then OK := False;
      End;
  If Not OK Then
    Begin
      Write(Msg(24));
      Delay(2000);
    End;
  CMOSClr := OK;
End;

{Clear CMOS ram area}
Procedure ClearCMOS;
Begin
  Text_Color( 12 );
  GotoXY( 2, 22 );
  Write( Msg( 21 ) );
  Repeat
    A := UpCase( _ReadKey )
  Until ( A = AnswYes ) Or ( A = AnswNo );
  GotoXY( 2, 22 );
  ClrEol;
  If A = AnswYes Then
    Begin
      Text_Color(LightRed);
      GotoXY(11,22);
      If CMOSClr Then
        Begin
          Write(Msg(22),CMOSSize+1,Msg(23));
          Delay(1000);
          LogWrite('CMOS settings cleared');
        End
      Else LogWrite('Error clearing CMOS settings - may be write protected');
      GotoXY(11,22);
      ClrEol;
      SetMenuItemStatus( CMOSMenu, 3, True ); {v1.33}
    End;
End;

Procedure CMOSWrite(Var IFile:File); {v1.25}

Var X,Z: Byte;
Begin
  Z := CMOSSize;
  If Z>127 Then Z := 127;
  For X:=$0E To Z Do
    Begin
      Port[$70] := X;
      CMOSImg[X] := Port[$71];
    End;
  If CMOSSize>Z Then
    For X:=$80 To $FF Do
      Begin
        Port[$72] := X;
        CMOSImg[X] := Port[$73];
      End;
  BlockWrite(IFile,CMOSImg,CMOSSize-$0D);
  If IOError Then {v1.28}
    Begin
      ErrorMsg(Msg(65));
      Exit;
    End;
End;

{Write CMOS data to disk}
Procedure SaveCMOS;

Var 
  IName : String;
  IFile : File;

Begin
  GotoXY( 18, 20 );
  Write( Msg( 97 ) + 'CMOS' + Msg( 18 ) );
  FInput(IName,'backup.cmo',45); {v1.28}
  If IName<>'' Then {v1.28}
    Begin
      Assign( IFile, IName );
      Rewrite( IFile, 1 );
      If IOError Then
        Begin
          ErrorMsg(Msg(7)+IName+' !'#7);
          Exit;
        End;
      CMOSWrite(IFile);
      Close( IFile );
      IOError;
      LogWrite('CMOS settings saved to '+IName); {v1.23}
    End;
  GotoXY( 11, 20 );
  ClrEol;
End;

Function CMOSRestore(Var IFile:File): Boolean; {v1.25}

Var X,Z: Byte;
  OK: Boolean;
Begin
  Z := CMOSSize;
  If Z>127 Then Z := 127;
  BlockRead(IFile,CMOSImg,CMOSSize-$0D);
  If IOError Then {v1.28}
    Begin
      ErrorMsg(Msg(64));
      Exit;
    End;
  For X:=$0E To Z Do
    Begin
      Port[$70] := X;
      Port[$71] := CMOSImg[X];
    End;
  If CMOSSize>Z Then
    For X:=$80 To $FF Do
      Begin
        Port[$72] := X;
        Port[$73] := CMOSImg[X];
      End;
  OK := True;
  For X:=$0E To Z Do
    Begin
      Port[$70] := X;
      If Port[$71]<>CMOSImg[X] Then OK := False;
    End;
  If CMOSSize>Z Then
    For X:=$80 To $FF Do
      Begin
        Port[$72] := X;
        If Port[$73]<>CMOSImg[X] Then OK := False;
      End;
  If Not OK Then
    Begin
      Text_Color(LightRed);
      GotoXY(11,22);
      Write(Msg(26));
      Delay(2000);
      GotoXY(11,22);
      ClrEol;
    End;
  CMOSRestore := OK;
End;

{Read CMOS data from disk}
Procedure RestoreCMOS;

Var 
  IName : String;
  IFile : File;

Begin
  GotoXY( 18, 20 );
  Write( Msg( 97 ) + 'CMOS' + Msg( 18 ) );
  FInput(IName,'',45); {v1.28}
  If IName <> '' Then
    Begin
      Assign( IFile, IName );
      Reset( IFile, 1 );
      If IOError Then
        Begin
          ErrorMsg(Msg(8)+IName+' !'#7);
          Exit;
        End;
      If FileSize( IFile ) <> ( CMOSSize - $0D ) Then
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
      If CMOSRestore(IFile) Then LogWrite('CMOS settings restored from '+IName)
      Else LogWrite('Error restoring CMOS settings - may be write protected');
      Close( IFile );
      IOError;
      SetMenuItemStatus( CMOSMenu, 3, True ); {v1.33}
    End;
  GotoXY( 11, 20 );
  ClrEol;
End;


Procedure WrtOldCMOS;

Var X,Z: Byte;
  OK: Boolean;

Begin
  Text_Color( 12 );
  GotoXY( 11, 22 );
  Write( Msg( 27 ) );
  Repeat
    A := UpCase(_ReadKey)
  Until (A=AnswYes) Or (A=AnswNo);
  GotoXY( 11, 22 );
  ClrEol;
  If A=AnswYes Then
    Begin
      Z := CMOSSize;
      If Z>127 Then Z := 127;
      For X:=$0E To Z Do
        Begin
          Port[$70] := X;
          Port[$71] := CMOSBack[X];
        End;
      If CMOSSize>Z Then
        For X:=$80 To $FF Do
          Begin
            Port[$72] := X;
            Port[$73] := CMOSBack[X];
          End;
   {Verify}
      OK := True;
      For X:=$0E To Z Do
        Begin
          Port[$70] := X;
          If Port[$71]<>CMOSBack[X] Then OK := False;
        End;
      If CMOSSize>Z Then
        For X:=$80 To $FF Do
          Begin
            Port[$72] := X;
            If Port[$73]<>CMOSBack[X] Then OK := False;
          End;
      Text_Color(12);
      GotoXY(11,22);
      If OK Then
        Begin
          Write(CMOSSize-$0D,Msg(28));
          Delay(1000);
        End
      Else
        Begin
          Write(Msg(26));
          _ReadKey;
        End;
      GotoXY(11,22);
      ClrEol;
    End;
  SetMenuItemStatus( CMOSMenu, 3, False ); {v1.33}
  LogWrite('CMOS settings restored from backup in memory'); {v1.23}
End;

Procedure MyExitProc;
far;
Begin
  LogWrite('Exiting UniFlash...');
  If PCIROMEn Then
    Begin
      SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04, PCIReg4 );
      SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, PCIReg30 );
      PCIROMEnable(False);
    End;
  Text_Color( LightGray );
  RomEnable( False );
  LogWrite('Turning off logging, shutting down to real mode');
  FlatRealOff;
  LogWrite('Releasing XMS allocation');
  CloseXMS;
  LogEnd;
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

Function CanIdentifyChip( ManufNode : PFl_Manuf; Dev : Byte; Var CInfo :
                         ChipInfo ) : Boolean;

Var 
  IdFn : Fl_IdChip;
Begin
  IdFn := ManufNode^.IdChip;
  CanIdentifyChip := IdFn( Dev, CInfo );
End;

Procedure Err( Msg : String );
Begin
  WriteLn;
  WriteLn;
  Text_Color(lightred);
  LogWrite( Msg ); {v1.23}
  WrtCenter( #7 + Msg );
  Text_Color(lightgray);
  If Emergency Then Sound( 1000 );
  halt(0);
End;

Function OpStr( S : String ) : String;

Var 
  X : Byte;

Begin
  If ( Length( S ) > 1 ) And ( ( S[ 1 ] = '-' ) Or ( S[ 1 ] = '/' ) ) Then
    Begin
      For X := 1 To Length( S ) Do
        S[ X ] := UpCase( S[ X ] );
      OpStr := Copy( S, 2, Length( S ) - 1 );
    End
  Else OpStr := '';
End;

Procedure CheckRedir; {v1.22}

Var A: Byte;
Begin
  A := WhereX;
  Write(StdOut,' ');
  Redir := WhereX=A;
End;

Function WriteLnStd(S:String): Boolean; {v1.22}

Var A: Char;
Begin
  Inc( Count );
  If Not Redir And ( Count >= Hi( WindMax ) ) Then
    Begin
      Write( '-- More --' );
      A := _ReadKey;
      If (UpCase(A)='Q') Or (A=#27) Then
        Begin
          WriteLnStd := False;
          Exit;
        End; {v1.24}
      WriteLn;
      Count := 0;
    End;
  WriteLn( StdOut, S );
  WriteLnStd := True;
End;

Procedure MemInit; {v1.24}
Begin
  InitXMS; {Init memory subsystem. Should be done before FlatRealOn}
  If XMSLeft = -1 Then Err( Msg( 37 ) );

  If Not FlatRealOn Then
    Err( Msg( 38 ) )
  Else LogWrite('Flat Real Mode initialized'); {v1.23}

 {Allocate high memory if XMS not present}
  AllocHimem;
End;

Procedure ROMSelect; {v1.24}
Begin
{ ROMBase :=0 ;}  {standard system BIOS flag for detectloop}
  ROMBase := BaseForced;


(*If PCI ROM mode then scan for & select PCI ROM
  NOTE: This is all experimental and uses a technique that
        I think will not be encouraged by the PCI SIG. It may
        cause problems with PCI cards with a shared memory
        controller (like local memory corruption ...)
        Use the PCIROM switch at your own risk ... *)
  If PCIROM Then
    Begin
      PCIROMCnt := 0;

      If (PCIROMBus<>0) Or (PCIROMDev<>0) Or (PCIROMFun<>0) Then {v1.27}
        Begin
          Asm CLI
        End;
      PCIReg4 := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04 );
      {Save reg 4}
      SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04, PCIReg4 Or $02 );
      {Enable memory}
      PCIReg30 := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30 );
      {Save reg 30}
      SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, $FFFFFFFF );
      {Check for stuck 0's}
      Img := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30 );
      SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, $00000001 );
      {Check for stuck 1's}
      Img := Img xor GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30 );
      {Now every 0 is a hw bit}
      For Z := 1 To 32 Do
        If ( Img And ( 1 shl LongInt( Z ) ) ) <> 0 Then Break;
      If ( Z < 32 ) And ( ( Img xor ( - ( 1 shl LongInt( Z ) ) ) ) = 0 ) Then
        Begin
          Inc( PCIROMCnt );
          With PCIROMs[ PCIROMCnt ] Do
            Begin
              MaxSize := 1 shl LongInt( Z );
              VenID := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $00 );
              DevID := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $00 ) shr 16
              ;
              Bus := PCIROMBus;
              Pos := ( PCIROMDev shl 3 ) Or PCIROMFun;
            End;
        End;
      SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04, PCIReg4 );
      SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, PCIReg30 );
      Asm STI
    End;
End
Else
  Begin
      {Scan the PCI config space for devices with a PCI option ROM}
    For PCIROMBus := 0 To $FF Do
      For PCIROMDev :=0 To $1F Do
        Begin
          If ( GetPCIRegD( PCIROMBus, PCIROMDev, 0, 0 ) And $FFFF ) <> $FFFF
            Then
            Begin
              X := 0;
              If ( GetPCIRegD( PCIROMBus, PCIROMDev, 0, $0C ) And $800000 ) <> 0
                Then X := 7;
              For PCIROMFun := 0 To X Do
                If ( GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, 0 ) And $FFFF
                   ) <> $FFFF Then
                  Begin
             (* Found a PCI device, check for PCI option ROM *)
                    Asm CLI
                  End;
             {Save state; enable memory}
              PCIReg4 := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04 );
              {Save reg 4}
              SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04, PCIReg4 Or $02 )
              ; {Enable memory}
              PCIReg30 := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30 );
              {Save reg 30}

             {Check for hardwired bits}
              SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, $FFFFFFFF );
              {Check for stuck 0's}
              Img := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30 );
              SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, $00000001 );
              {Check for stuck 1's}
              Img := Img xor GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30 );
              {Now every 0 is a hw bit}
             {Scan for 1st non-hardwired bit}
              For Z := 1 To 32 Do
                If ( Img And ( 1 shl LongInt( Z ) ) ) <> 0 Then Break;
             {We don't support option ROM's at (semi-)fixed addresses}
              If ( Z < 32 ) And ( ( Img xor ( - ( 1 shl LongInt( Z ) ) ) ) = 0 )
                Then
                Begin
               {found PCI option ROM, add to list}
                  Inc( PCIROMCnt );
                  With PCIROMs[ PCIROMCnt ] Do
                    Begin
                      MaxSize := 1 shl LongInt( Z );
                      VenID := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $00
                               );
                      DevID := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $00
                               ) shr 16;
                      Bus := PCIROMBus;
                      Pos := ( PCIROMDev shl 3 ) Or PCIROMFun;
                    End;
                End;
             {Restore PCI device state}
              SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04, PCIReg4 );
              SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, PCIReg30 );
              Asm STI
            End;
        End;
  End;
End;
End;

If PCIROMCnt > 0 Then
  Begin
    Window(1,9,80,25);
    ClrScr;
    Window(1,1,80,25);
    GotoXY(1,9);
    Text_Color( Yellow );
    WrtCenter( Msg( 39 ) );
    WriteLn;
    Text_Color( 15 );
    For X := 1 To PCIROMCnt Do
      With PCIROMs[ X ] Do
        Begin
          Write( '        ', Char( X + 48 ), '. ' );
          WriteLn( Msg( 40 ), Hb( Bus ),
          Msg( 41 ), Hb( Pos shr 3 ),
          Msg( 42 ), Hb( Pos And 7 ),
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
      If ( A >= '0' ) And ( A <= Char( 48 + PCIROMCnt ) ) Then
        Begin
          SelA := A;
          GotoXY( 17, WhereY );
          Write( A );
          GotoXY( 17, WhereY );
        End;
    Until ( A = #13 ) Or ( A = #27 );
    If ( A = #27 ) Or ( SelA = '0' ) Then
      Begin
        WriteLn;
        Halt;
      End;
    CurPCIROM := Byte( SelA ) - 48;
    With PCIROMs[ CurPCIROM ] Do
      Begin
        PCIROMBus := Bus;
        PCIROMDev := Pos shr 3;
        PCIROMFun := Pos And 7;
        PCIReg4 := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04 );
        {Save reg 4}
        SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $04, PCIReg4 Or $02 );
        {Enable memory}
        PCIReg30 := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30 );
        {Save reg 30}

(*       If Hi( PCIReg30 shr 16 ) = $CB then {v1.22}
        SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, PCIReg30 or 1 )
       else*)
        SetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30, $80000001 );
        PCIROMEnable(True);

        GotoXY(2,7);
        ClrEol;
        Text_Color(Yellow);
        Write(Msg(66));
        Text_Color(15);
        Write(CurrentPCICard,' at ',Hb(PCIROMBus),':',Hb(PCIROMDev),':',Hb(
                                                                       PCIROMFun
        ));

        PCIROMEn := True;
        ROMBase := GetPCIRegD( PCIROMBus, PCIROMDev, PCIROMFun, $30 ) And $
                   FFFFFFFE{ $80000000}; {v1.22}
      End;

    Window(1,9,80,25);
    ClrScr;
    Window(1,1,80,25);
    GotoXY(1,3);
    LogWrite( 'PCI expansion ROM at '+Hb(PCIROMBus)+':'+Hb(PCIROMDev)+':'+Hb(
                                                                       PCIROMFun
    )+' selected' ); {v1.23}
  End
Else Err( Msg( 45 ) );
End
Else
  If CTFlash Then
    Begin
      If Not CTFlash_AutoDetect Then
        Begin
          Err(Msg(112));
        End;
      GotoXY(2,7);
      ClrEol;
      GotoXY(19,7);
      Text_Color(Yellow);
      Write('c''t Flasher: ');
      Text_Color(15);
      Write(Hw(CTFlashPort),', ',Hl(CTFlashBase));
    End
Else
  Begin
    RomEnable( True ); {Program the chipset so it lets you see the BIOS}
    LogWrite( 'System ROM selected' ); {v1.23}
  End;
End;

Procedure ROMType; {v1.24}
Begin
  If FlashError = 0 Then
    Begin
      FlashSize := LongInt( FlashInfo^.Size ) shl 10;
      FlashBase := ROMBase { - ( FlashSize * FlashInfo^.Count ) };

      With FlashInfo^ Do
        Case Flags And 3 Of 
          0   :
                Begin
                  MaxBlock := 0;
                  For X := 0 To 4 Do {v1.21 3->4}
                    Begin
                      If Sectors[ X, 0 ] = 0 Then Break;
                      If Sectors[ X, 1 ] > MaxBlock Then
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

      If ( OldBIOS = 0 ) Or ( NewBIOS = 0 ) Or ( TempBuf = 0 ) Then
        Err( Msg( 50 ) );
    End
  Else
    Begin
   {some defaults so we can at least write something to disk}
      If PCIROM Then
        Begin
          FlashBase := ROMBase;
{     FlashSize := FlashSize shl 9;}
          FlashSize := PCIROMs[ CurPCIROM ].MaxSize; {v1.22}
        End
      Else
        Begin
          FlashSize := 131072;    {128K default}
          If (ROMBase=0) Or (ROMBase=$FFF00000) Then {v1.30}
            Begin
              If BaseForced=0 Then FlashBase := $FFFE0000
              Else FlashBase := ROMBase; {same}
              ROMBase := FlashBase;
            End;
        End;
      OldBIOS := AllocLinBlock( FlashSize );
      If ( OldBIOS = 0 ) Then
        Err( Msg( 50 ) );
    End;
  Text_Color(yellow);
  GotoXY( 2, 5 );
  ClrEol;
  Write( Msg( 51 ) );
  With FlashInfo^ Do
    Begin
      Text_Color( 15 );
      If FlashError <> 0 Then Write( Msg( 52 ) )
      Else
        Begin
{     If Count > 1 then Write( Count, ' x ' );}
          Write( Manuf^, ' ', Name^ );
        End;
      If ForceId Then
        Begin
          Write( ' (forced)' );
          LogWrite('Flash ROM chip forced: '+Manuf^+' '+Name^); {v1.23}
        End
      Else
        If FlashError=0 Then LogWrite('Flash ROM chip detected: '+Manuf^+' '+
                                      Name^) {v1.23}
      Else LogWrite( 'Flash ROM chip not detected' ); {v1.23}
      GotoXY( 1, 5 ); {v1.21}
      Write(' (' + Hb( Man1 ) + Hb( Dev1 ) + ',' + Hb( Man2 ) + Hb( Dev2 ) + ')'
      );
      LogWrite('Flash ROM ID: '+Hb(Man1)+HB(Dev1)+','+Hb(Man2)+Hb(Dev2));
      {v1.23}

      GotoXY( 2, 6 );
      Text_Color(yellow);
      ClrEol;
      Write( Msg( 53 ) );
      Text_Color( 15 );
      If FlashError <> 0 Then Write( Msg( 54 ) )
      Else
        Begin
          Case Flags And 3 Of 
            0 :
                Begin
                  Write( Msg( 55 ) );
{           If Count > 1 then Write( Count, ' x (' );}
                  For X := 0 To 4 Do
                    With FlashInfo^ Do {v1.21 3->4}
                      Begin
                        If Sectors[ X, 0 ] = 0 Then Break;
                        If X > 0 Then Write( ',' );
                        Write( Sectors[ X, 0 ], 'x' );
                        If Sectors[ X, 1 ] >= 8 Then Write( ( Word( Sectors[ X,
                                                           1 ] ){ + 1} ) shr 3
                          {shl 1}, 'k' ) {v1.21}
                        Else Write( ( Word( Sectors[ X, 1 ] ){ + 1} ) shl 7
                          {shl 1}, 'b' );
                      End;
{           If Count > 1 then Write( ')' );}
                End;
            1 :
                Begin
{           If Count > 1 then Write( Count, ' x ' );}
                  Write( ( ( LongInt( Size ) shl 10 ) {div Count} ) div PgSize )
                  ;
                  Write( Msg( 56 ), pgsize, Msg( 57 ) );
                End;
            2 : Write( Msg( 58 ) );
            3 :
                Begin
{           If Count > 1 then Write( Count, ' x ' );}
                  Write( ( ( LongInt( Size ) shl 10 ) {div Count} ) div PgSize )
                  ;
                  Write( Msg( 59 ), pgsize, Msg( 57 ) );
                End;
          End;
          If ( Size And 1023 ) <> 0 Then
            Write( ' (', Size, 'K)' )
          Else
            Write( ' (', Size shr 10, 'M)' );
        End;
    End;
  GotoXY(2,8); {v1.28}
End;

Procedure XMSInfo; {v1.24}
Begin
  Text_Color( DarkGray );
  GotoXY( 1, 24 );
  Write( Msg( 68 ) );
  Write( 'XMSPos=', Hl( XMSPos ), ', XMSLeft=', XMSLeft );
  GotoXY( 1, 23 );
  Write( Msg( 69 ) );
  Write( Hl( ROMBase )+ Msg( 70 ) +Hl(ROMBase)+'-->('+Hw(FIMemW(ROMBase))+Hw(
                                                                          FIMemW
                                                                             (
                                                                         ROMBase
                                                                             +2)
  )+')' );
End;

Procedure RedetectFlashROM; {v1.24}
Begin
  ForceID := False; {v1.30}
  LogWrite('Restarting UniFlash...');
  If PCIROMEn Then
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
  If FlashInfo = Nil Then
    Begin
      SetMenuItemStatus( MainMenu, 1, False );
      SetMenuItemStatus( MainMenu, 5, False );
    End;
  If ( FlashInfo^.Flags And 3 ) = 2 Then SetMenuItemStatus( MainMenu, 5, False )
  ;
  If PCIROM Then
    Begin
      SetMenuItemStatus( MainMenu, 4, False );
      SetMenuItemStatus( MainMenu, 5, False );
    End;
End;

{---------------------- MAIN PART OF THE PROGRAM -------------------------}
{---------------------- MAIN PART OF THE PROGRAM -------------------------}
{---------------------- MAIN PART OF THE PROGRAM -------------------------}
{---------------------- MAIN PART OF THE PROGRAM -------------------------}
Begin
  FileMode := 0; {Reset will open files as Read-Only} {v1.31}
 {Hack to be able to write to StdOut - better ideas anyone ?}
  Assign( StdOut, 'CON' );
  Rewrite( StdOut );
  StdOutRec.Handle := 1;
  CheckRedir; {v1.22 Check if STDOUT is redirected}
  If NoVideo Then DirectVideo := False; {v1.28}

  ClrScr;
  GotoXY(9,2);
  Text_Color(Yellow);
  Write('UniFlash ');
  Text_Color(LightGreen);
  Write('v' + Version );
  Text_Color(LightCyan);
  WriteLn(' (c) 2026 Deksor (https://github.com/Deksor/uniflash)');
  Text_Color(LightMagenta);
  GotoXY(9,3);
  Write('Original version by Pascal van Leeuwen & Galkowski Adam');
  GotoXY(9,4);
  Write('Then maintained by Ondrej Zary (Rainbow Software) until 2005');
  Text_Color(LightGray);

  CurLang := 1; {default = English}
  If ( ParamCount > 0 ) Then
    Begin
      PStr := OpStr( ParamStr( 1 ) );
      If PStr[ 1 ] = '0' Then
        Begin
          WriteLn;
          WriteLn;
          WrtCenter( 'Languages supported in this version:' );
          WriteLn;
          For X := 1 To LangCount Do
            WrtCenter( Char( X + Ord( '0' ) ) + '. ' + GetLangName( X ) );
          WriteLn;
          WrtCenter(
               'Use UNIFLASH /x [other options] where x is the language number.'
          );
          WriteLn;
          Halt;
        End;
      If PStr[ 1 ] In [ '1' .. Char( LangCount + Byte( '0' ) ) ] Then
        Begin
          CurLang := Byte( PStr[ 1 ] ) - Byte( '0' ); {Set language}
          X := 2;
        End
      Else X := 1;
    End;
  InitLanguage(CurLang); {v1.31}
  PStr := Msg( 105 );
  AnswYes := PStr[ 1 ];
  AnswNo  := PStr[ 2 ];

  PCIROMBus := 0;
  PCIROMDev := 0;
  PCIROMFun := 0;

  While ParamCount >= X Do
    Begin
      PStr := OpStr( ParamStr( X ) );
      If ( PStr = 'E' ) Then
        Begin
          Inc( X );
          If ParamCount < X Then Err( Msg( 29 )+'E' );
          Emergency := True;
          EMFName := ParamStr( X );
        End
      Else
        If ( PStr = 'H' ) Or ( PStr = '?' ) Then
          Begin
            WriteLn;
            WriteLn;
            WrtCenter(
        'UNIFLASH [-H|-?|[-PCIROM [B D F]|-AMI|-ASUS|-BASE xxxxx|CTFLASH [xxx]]'
            );
            WrtCenter(
          ' [-E fname][-SAVE fname|-CHIPLIST|-FORCE xxxx][-REPAIR][-LOG][-MONO]'
            );
            WrtCenter(
               ' [-CMOSS fname][-CMOSR fname][-CMOSC]][-UNLOCK][-QUIT][-REBOOT]'
            ); {v1.26}
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
            WrtCenter( Msg( 139 ) ); {v1.39}
            WrtCenter( Msg( 134 ) ); {v1.26}
            WrtCenter( Msg( 25 ) ); {v1.28}
            Halt;
          End
      Else
        If PStr = 'PCIROM' Then
          Begin
            PCIROM := True;
            Inc(X);
            PStr := ParamStr(X);
            If (PStr[1]<>'-') And (PStr[1]<>'/') And (ParamCount>=X) Then
              Begin
                Val(PStr,PCIROMBus,Int);
                Inc(X);
                PStr := ParamStr(X);
                If (ParamCount<X) Or (PStr[1]='-') Or (PStr[1]='/') Then Err(Msg
                                                                             (
                                                                             135
                  ));
                Val(PStr,PCIROMDev,Int);
                Inc(X);
                PStr := ParamStr(X);
                If (ParamCount<X) Or (PStr[1]='-') Or (PStr[1]='/') Then Err(Msg
                                                                             (
                                                                             135
                  ));
                Val(PStr,PCIROMFun,Int);
              End
            Else Dec(X);
          End
      Else
        If PStr = 'CTFLASH' Then {v1.32}
          Begin
            CTFlash := True;
            Inc(X);
            PStr := ParamStr(X);
            If (PStr[1]<>'-') And (PStr[1]<>'/') And (ParamCount>=X) Then
              CTFlashPort := Hex2Dec(PStr)
            Else
              Begin
                CTFlashPort := 0;
                Dec(X);
              End;
            CTFlashPort := CTFlashPort And $FFFC;
            If (CTFlashPort<$200) Or (CTFlashPort>$3FC) Then CTFlashPort := 0;
          End
      Else
        If PStr = 'AMI' Then WantToUseAmi := True
      Else
        If PStr = 'ASUS' Then WantToUseAsus := True
      Else {v1.39}
        If PStr = 'MONO' Then Mono := True
      Else {v1.27}
        If PStr = 'LOG' Then
          Begin
            Logging := True;
            LogStart;
          End
      Else {v1.23}
        If PStr = 'CHIPLIST' Then
          Begin
            WriteLnStd( '' );
            WriteLnStd( '  List of supported flash chips' );
            WriteLnStd( '  -----------------------------' );
            CurManuf := ManuRoot;
            Repeat
              With CurManuf^ Do
                Begin
                  M := Manuf;
                  For D := 0 To $FF Do {v1.21 FF}
                    If CanIdentifyChip( CurManuf, D, CurCInfo ) Then With 
                                                                        CurCInfo
                                                                       Do
                                                                       If Not
                                                                      WriteLnStd
                                                                          ( '  '
                                                                          + Hb(
                                                                          M )+
                                                                          Hb( D
                                                                          )+
                                                                          ' - '+
                                                                          Manuf^
                                                                          + ' '+
                                                                          Name^
                                                                          ) Then
                                                                         Begin

                                                                        ClrKbBuf
                                                                           ;
                                                                           Exit;
                                                                         End;
                End;
              CurManuf := CurManuf^.Next;
            Until ( CurManuf = Nil );
            Exit;
          End
      Else
        If PStr = 'FORCE' Then
          Begin
            Inc( X );
            If ParamCount < X Then Err( Msg( 106 ) );
            PStr := ParamStr( X );
            If Length( PStr ) <> 4 Then Err( Msg( 106 ) );
            ForceIdVal := 0;
            For M := 1 To 4 Do
              Begin
                ForceIdVal := ForceIdVal shl 4;
                If ( PStr[ M ] >= '0' ) And ( PStr[ M ] <= '9' ) Then
                  ForceIdVal := ForceIdVal Or ( Byte( PStr[ M ] ) - Byte( '0' )
                                )
                Else
                  If ( UpCase( PStr[ M ] ) >= 'A' ) And ( UpCase( PStr[ M ] ) <=
                     'F' ) Then
                    ForceIdVal := ForceIdVal Or ( Byte( UpCase( PStr[ M ] ) ) -
                                  Byte( 'A' ) + 10 )
                Else Err( Msg( 106 ) );
              End;
            ForceId := True;
          End
      Else
        If PStr = 'REPAIR' Then {v1.28}
          Begin
            If Not ForceID Then Err(Msg(137));
            If (Hi(ForceIDVal)<>$BF) And (Hi(ForceIDVal)<>$DA) Then Err(Msg(138)
              );
            Repair := True;
          End
      Else
        If PStr = 'UNLOCK' Then {v1.39}
          Begin
            Unlock := True;
          End
      Else
        If PStr = 'SAVE' Then
          Begin
            Inc( X );
            If ParamCount < X Then Err( Msg( 29 ) );
            SaveBIOS := True;
            SaveName := ParamStr( X );
          End
      Else
        If PStr = 'CMOSS' Then {v1.25}
          Begin
            CMOS := True;
            Inc(X);
            If ParamCount<X Then Err(Msg(29)+'CMOSS');
            CMOSSize := GetCMOSSize;
            Assign(IFile,ParamStr(X));
            ReWrite(IFile,1);
            If IOResult=0 Then
              Begin
                CMOSWrite(IFile);
                Close(IFile);
                IOError;
                WriteLn;
                WriteLn;
                LogWrite('CMOS settings saved to '+ParamStr(X));
                WrtCenter('CMOS settings saved to '+ParamStr(X));
              End
            Else Err(Msg(7)+ParamStr(X)+' !'#7);
          End
      Else
        If PStr = 'CMOSR' Then {v1.25}
          Begin
            CMOS := True;
            Inc(X);
            If ParamCount<X Then Err(Msg( 29 )+'CMOSR');
            CMOSSize := GetCMOSSize;
            Assign(IFile,ParamStr(X));
            Reset(IFile,1);
            If IOResult=0 Then
              Begin
                If FileSize(IFile)=(CMOSSize-$0D) Then
                  Begin
                    CMOSRestore(IFile);
                    Close(IFile);
                    IOError;
                    WriteLn;
                    WriteLn;
                    LogWrite('CMOS settings restored from '+ParamStr(X));
                    WrtCenter('CMOS settings restored from '+ParamStr(X));
                  End
                Else Err(Msg(98)+_Str(CMOSSize-$0A)+Msg(99));
              End
            Else Err(Msg(8)+ParamStr(X)+' !'#7);
          End
      Else
        If PStr = 'CMOSC' Then {v1.25}
          Begin
            CMOS := True;
            CMOSSize := GetCMOSSize;
            If CMOSClr Then
              Begin
                WriteLn;
                WriteLn;
                LogWrite('CMOS settings cleared');
                WrtCenter('CMOS settings cleared');
              End
            Else Err(Msg(24));
          End
      Else
        If PStr = 'QUIT' Then Quit := True
      Else {v1.28}
        If PStr = 'REBOOT' Then Reboot := True
      Else {v1.28}
        If PStr = 'BASE' Then {v1.28}
          Begin
            Inc(X);
            If ParamCount<X Then Err(Msg(92));
            PStr := ParamStr(X);
            If Length(PStr)<5 Then Err(Msg(92));
            For M:=1 To Length(PStr) Do
              Begin
                BaseForced := BaseForced shl 4;
                If (PStr[M]>='0') And (PStr[M]<='9') Then
                  BaseForced := BaseForced Or (Byte(PStr[M])-Byte('0'))
                Else
                  If (UpCase(PStr[M])>='A') And (UpCase(PStr[M])<='F') Then
                    BaseForced := BaseForced Or (Byte(UpCase(PStr[M]))-Byte('A')
                                  +10)
                Else Err(Msg(92));
              End;
          End;
      Inc( X );
    End;

  If CMOS And Not Emergency And Not SaveBIOS Then Exit;
  If Windows Then Err( Msg( 110 ) ); {v1.22}

  If (Not LocatePIIX) And (BaseForced=0) And Not CTFlash Then Err(Msg(111));
  {v1.22}

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

  BIOSID := #0#0#0#0#0#0#0#0;
  If Not DMI_Info Or (Copy(DMI_BIOS.Vendor, 1, 5)='Award')
     Or (Copy(DMI_BIOS.Version, 1, 5)='Award') Then
    GetBIOSID; {v1.39}
  ROMSelect; {v1.24}

  If ForceId Then
    Begin
      FlashError := 1;
      CurManuf := ManuRoot;
      FlashInfo := @CurCInfo;
{   CurCInfo.Count` := 1;}
      Repeat
        With CurManuf^ Do
          If ( Manuf = Hi( ForceIdVal ) ) And
             CanIdentifyChip( CurManuf, Lo( ForceIdVal ), CurCInfo ) Then
            FlashError := 0;
        CurManuf := CurManuf^.Next;
      Until ( FlashError = 0 ) Or ( CurManuf = Nil );
      If ROMBase = 0 Then
        ROMBase := - LongInt( FlashInfo^.Size ) shl 10;
      {rom starts at top of memory}
      Size512K := CurCInfo.Size>=512; {v1.34}
    End
  Else FlashInfo := FlashDetect;

  ROMType; {v1.24}

 {Backup current BIOS}
  Flash_ReadBlock(0,OldBios,FlashSize); {v1.29}

  If SaveBIOS Then
    Begin
      WriteBIOSImg;
      GotoXY( 1, Hi( WindMax ) );
    End;

  If Quit Then Exit; {v1.28}

  If Repair Then
    Begin
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
    End;

  If Unlock Then
    Begin
      FlashCmd($80);
      FlashCmd($40);
      Flash_Write($2AAA,$AA);
      Halt;
    End;

  If Emergency Then
    Begin
      LogWrite('Entering emergency mode');
      If FlashError <> 0 Then Err( Msg( 60 ) );
      Beep( 1000, 500 ); {single beep, start reading}
      Assign( IFile, EmFName );
      Reset( IFile, 1 );
      If IOResult <> 0 Then Err( Msg( 8 ) + EMFName + Msg( 95 ) );
      FlashFile( IFile, True {force boot block write, from personal experience}
                          {I really think that it can't be avoided !!      } );
      Close( IFile );
      IOError;
      If Reboot Then
        asm
        db 0EAh,00h,00h,0FFh,0FFh
    End;
  Halt;
End;

InitKB; {v1.38}

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
Z := CMOSSize;
If Z>127 Then Z := 127;
For X:=$0E To Z Do
  Begin
    Port[$70] := X;
    CMOSBack[X] := Port[$71];
  End;
If CMOSSize>Z Then
  Begin
    For X:=$80 To $FF Do
      Begin
        Port[$72] := X;
        CMOSBack[X] := Port[$73];
      End;
  End;

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
            AddSubMenuItem( Msg( 101 ), Msg( 126 ), 4, 3, CMOSMenu,
{             AddMenuItem( Msg( 90 ),  Msg( 127 ), 5, 3, PnPDMIMenu,}
            AddSubMenuItem( Msg( 91 ),  Msg( 128 ), 5, 3, AdvMenu,
            AddMenuItem( Msg( 93 ),  Msg( 129 ), 7, 1, Nil, Nil ) ) ) ) ) ) )
            {)};

If FlashInfo = Nil Then
  Begin
    SetMenuItemStatus( MainMenu, 1, False );
    SetMenuItemStatus( MainMenu, 5, False );
  End;
If ( FlashInfo^.Flags And 3 ) = 2 Then SetMenuItemStatus( MainMenu, 5, False );

If PCIROM Then
  Begin
    SetMenuItemStatus( MainMenu, 4, False );
    SetMenuItemStatus( MainMenu, 5, False );
  End;
LogWrite('UniFlash running in interactive mode'); {v1.23}
VErr := False;
Repeat
  RunMenu( MainMenu );
  If VErr Then
    Begin
      Text_Color( 12 );
      GotoXY( 11, 22 );
      Write( Msg( 94 ) );
      Repeat
        A := UpCase( _ReadKey )
      Until ( A = AnswYes ) Or ( A = AnswNo );
      GotoXY( 11, 22 );
      ClrEol;
    End;
Until ( Not VErr ) Or ( A = AnswYes );

GotoXY( 1, Hi( WindMax ) );
End.
