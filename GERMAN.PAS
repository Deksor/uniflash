unit German; {v1.26}

Interface

Implementation

Uses Language;

{$F+}
procedure InitGerman;
begin
 AddMsg(1, 'L�schen in Arbeit' );
 AddMsg(2, 'Flashen in Arbeit' );
 AddMsg(3, 'Vergleiche Daten' );
 AddMsg(4, ' Inhalt des FLASH ist nicht identisch mit Datei! Schreiben wiederholen [Y/N]?' );
 AddMsg(5, '         Achtung: BOOTBLOCK Fehler !! Weiter [Y,N]?' );
 AddMsg(6, 'Dateiname: ' );
 AddMsg(7, 'Datei kann nicht erstellt werden ' );
 AddMsg(8, 'Datei kann nicht ge�ffnet werden ' );
 AddMsg(9, 'DIE GR�SSE DER DATEI WEICHT VOM CHIP AB! Weiter [Y,N]?' );
 AddMsg(10, 'ACHTUNG: BOOT BLOCK wird ver�ndert. Weiter [Y,N]?' );
 AddMsg(11, 'FEHLER' );
 AddMsg(12, 'ERFOLGREICH' );
 AddMsg(13, ' Dateiname: ' );
{ AddMsg(14, 'Falsche Dateigr�sse - muss genau 4K betragen!'#7 );}
 AddMsg(15, 'Wollen Sie weitermachen (Y/N)?' );
{ AddMsg(16, 'Achtung: Alles wird gel�scht! ' );
 AddMsg(17, ' Einstellungen. Weiter [Y,N]?' );}
 AddMsg(18, ' Dateiname: ' );
 AddMsg(19, 'Dateiname f�r Bootblock: ' );
 AddMsg(20, 'Flashe Datei in das FLASH ROM [Y,N]?' );
 AddMsg(21, '         ACHTUNG! Sie verlieren alle BIOS Einstellungen. Weiter [Y,N]?' );
 AddMsg(22, 'Gel�scht ' );
 AddMsg(23, ' BYTES von CMOS RAM.' );
 AddMsg(24, 'Fehler beim L�schen von CMOS RAM - eventuell (teilweise) SCHREIBGESCH�TZT.'#7 );
 AddMsg(25, '-REBOOT         Reboot after flashing (use together with -E)' ); {v1.28}
 AddMsg(26, 'Fehler beim Schreiben in das CMOS RAM - eventuell (teilweise) SCHREIBGESCH�TZT.'#7 );
 AddMsg(27, 'CMOS Daten aus Backup wiederherstellen [Y,N]?' );
 AddMsg(28, ' BYTES von CMOS RAM geschrieben.'#7 );
 AddMsg(29, 'Vermisse Dateiname mit Option -' );
 AddMsg(30, '-H oder -?      Zeigt die Hilfe an' );
 AddMsg(31, '-E fname        Flasht Bios Abbild fname in das Flash ROM' );
 AddMsg(32, '-CTFLASH [xxx]  Flash ROM in c''t Flasher 8-bit ISA card [xxx=port]' ); {v1.32}
 AddMsg(33, '-LOG            Aktiviert Protokollierung in UNIFLASH.LOG' ); {v1.23}
 AddMsg(34, '-PCIROM         Flash ROM on a PCI card instead of system ROM' ); {v1.29}
 AddMsg(35, '  [BUS DEV FUN] Manually specify PCI device (decimal numbers)' );
 AddMsg(36, '-AMI            Verwendet AMI Flash Interface' ); {v1.24}
 AddMsg(37, 'Kein Speicherzugriff jenseits 1Mb - Benutzen Sie HIMEM.SYS.' );
 AddMsg(38, 'Sie d�rfen eine 486+ oder gr�ssere CPU nicht im V86 Modus betreiben.' );
 AddMsg(39, 'Select PCI card from list below:' ); {v1.29}
 AddMsg(40, 'Bus ' );
 AddMsg(41, ' Ger�t ' );
 AddMsg(42, ' Funktion ' );
 AddMsg(43, '0. Ende' );
 AddMsg(44, 'Gew�hlt: 0' );
 AddMsg(45, 'No PCI card with ROM found.' ); {v1.29}
 AddMsg(46, 'M�chten Sie das Bios in eine Datei sichern? ' );
 AddMsg(47, 'Name der Datei: ' );
 AddMsg(48, '            ausgef�hrt.' );
 AddMsg(49, 'BOOTBLOCK MISMATCH. FLASH INCLUDING BOOTBLOCK (HIGHLY RECOMMENDED) [Y,N]?' ); {v1.30}
 AddMsg(50, 'Nicht genug freier Speicher.' );
 AddMsg(51, '              Flash ROM Chip: ' );
 AddMsg(52, 'Unbekannt' );
 AddMsg(53, '                Organisation: ' );
 AddMsg(54, 'Nicht m�glich (Ist Schreibsch�tz ausgeschaltet?)' ); {v1.23}
 AddMsg(55, 'Sektoren: ' );
 AddMsg(56, ' Seiten zu je ' );
 AddMsg(57, ' Bytes' );
 AddMsg(58, 'vollst�ndig gel�scht' );
 AddMsg(59, ' Sektoren von ' );
 AddMsg(60, 'Unbekannter Flash Chip !' );
 AddMsg(61, '                PCI Chipsatz: ' );
 AddMsg(62, '       Letzter Schreibstatus: ' );
 AddMsg(63, 'nicht verf�gbar' );
 AddMsg(64, 'Unable to read file!'#7 ); {v1.28}
 AddMsg(65, 'Unable to write file!'#7 ); {v1.28}
 AddMsg(66, '           Selected PCI card: ' ); {v1.29}
(* AddMsg(66, ', Geraet=' );
 AddMsg(67, ' von ' ); *)
 AddMsg(68, 'Speicher: ' );
 AddMsg(69, 'ROM Basis: ' );
 AddMsg(70, ', Speicher Abbild von ' );
 AddMsg(71, '              Options ROM f�r: ' );
 AddMsg(72, 'Ger�t an ' );
{ AddMsg(73, 'Schreibe ESCD (PnP Daten) in Datei' );
 AddMsg(74, 'Flashe ESCD (PnP Daten) Datei in Flash ROM' );
 AddMsg(75, 'L�sche ESCD (PnP Daten)' );
 AddMsg(76, 'Schreibe DMI Daten in Datei' );
 AddMsg(77, 'Flashe DMI Datei ins Flash ROM' );
 AddMsg(78, 'L�sche DMI Daten' );}
 AddMsg(79, '� zur�ck zum Hauptmen�' );
 AddMsg(80, 'Sichere CMOS in Datei' );
 AddMsg(81, 'Wiederherstellen von CMOS aus Datei' );
 AddMsg(82, 'Flashe BIOS Image inklusive Bootblock' );
 AddMsg(83, 'Sichere Bootblock in Datei' );
 AddMsg(84, 'Flashe Bootblock ins Flash ROM' );
 AddMsg(85, 'Schreibe BIOS-Image in Datei' );
 AddMsg(86, 'Flashe BIOS-Image ins Flash ROM' );
 AddMsg(87, 'Flashe BIOS-Image noch 1x ins Flash ROM' );
 AddMsg(88, 'L�sche CMOS Daten' );
 AddMsg(89, 'Wiederherstellung des CMOS von Datentr�ger' );
{ AddMsg(90, 'ESCD (PnP) Submen� �' );}
 AddMsg(91, 'Fortgeschrittenen Submen� �' );
{ AddMsg(92, 'Zus�tzliche BIOS Info' );}
 AddMsg(93, 'Ende' );
 AddMsg(94, 'Letztes Schreiben des Flash war erfolgreich. Beenden [Y/N]?'#7 );
 AddMsg(95, ' !'#7 );  {Letzter Teil von msg 7 & 8 !!!!}
 AddMsg(96, 'Falsche Dateigr�sse - muss genau 8K betragen!'#7 );
 AddMsg(97, '' ); {->18}
 AddMsg(98, 'Falsche Dateigr�sse muss exakt betragen ' );
 AddMsg(99, ' Bytes !'#7 );
 AddMsg(100, 'Neue Suche nach Flash ROM Typ' ); {v1.23}
 AddMsg(101, 'CMOS Submen� �' ); {v1.23}
{ AddMsg(100, 'BIOS Hersteller: ' );
 AddMsg(101, '   BIOS Modell: ' );
 AddMsg(102, '  Zubeh�rnummer: ' );
 AddMsg(103, '    Identifikationsnummer: ' );
 AddMsg(104, 'Hersteller Identifikationsnummer: ' );}
 AddMsg(105, 'YN' );   {Ja Nein}
 AddMsg(106, '-FORCE Option muss gefolgt werden von 4 hex Ziffern' );
 AddMsg(107, '-CHIPLIST       Liste der unterst�tzten Flash Chips' );
 AddMsg(108, '-FORCE xxxx     Force benutzt Routinen f�r Chip xxxx (4 hex Ziffern)' );
 AddMsg(109, '-SAVE fname     schreibt verwendetes Bios in Datei fname' );
 AddMsg(110, 'Dieses programm kann nicht unter Windows laufen.' ); {v1.22}
 AddMsg(111, 'PCI Bus nicht gefunden oder antwortet nicht.' ); {v1.22}
 AddMsg(112, 'c''t Flasher not found.'); {v1.32}
(* AddMsg(112, 'Schreibe ESCD (Plug & Play) Daten in Datei' ); {v1.23}
 AddMsg(113, 'Flashe ESCD (Plug & Play) Daten von Datei in Flash ROM' ); {v1.23}
 AddMsg(114, 'L�sche ESCD (Plug & Play) daten im Flash ROM' ); {v1.23}*)
 AddMsg(115, 'Flashe BIOS Image aus Datei in Flash ROM inklusive BootBlock' ); {v1.23}
 AddMsg(116, 'Sichere BootBlock in Datei' ); {v1.23}
 AddMsg(117, 'Flashe BootBlock aus Datei in Flash ROM' ); {v1.23}
 AddMsg(118, 'Sichere vorhandene CMOS Einstellungen in Datei' ); {v1.23}
 AddMsg(119, 'Stelle CMOS Einstellungen aus Datei wieder her' ); {v1.23}
 AddMsg(120, 'L�sche CMOS Einstellungen' ); {v1.23}
 AddMsg(121, 'Wiederherstellung der CMOS Einstellungen aus Speicher' ); {v1.23}
 AddMsg(122, 'Schreibe gesichertes BIOS Image vom FLASH in Datei' ); {v1.23}
 AddMsg(123, 'Flashe BIOS Image aus Datei in Flash ROM (ohne Bootblock)' ); {v1.23}
 AddMsg(124, 'Flashe eingelesenes BIOS Image aus RAM in das Flash ROM' ); {v1.23}
 AddMsg(125, 'Identifiziere Flash ROM Typ und lese Inhalt zur Sicherung in den Speicher' ); {v1.23}
 AddMsg(126, 'W�hle CMOS Einstellungen Untermen�...' ); {v1.23}
(* AddMsg(127, 'W�hle ESCD (PnP) Untwermen�...' ); {v1.23}*)
 AddMsg(128, 'W�hle Fortgeschrittenen Untermen�...' ); {v1.23}
 AddMsg(129, 'Beende UniFlash' ); {v1.23}
 AddMsg(130, 'Zur�ck zum Hauptmen�' ); {v1.23}
 AddMsg(131, '-CMOSS/R fname  Save/restore CMOS settings to/from file fname' ); {v1.28}
 AddMsg(132, '-BASE xxxxx     Set ROM Base to address xxxxx (at least 5 hex digits)' ); {v1.28}
 AddMsg(133, '-CMOSC          L�scht CMOS Einstellungen' ); {v1.25}
 AddMsg(134, '-QUIT           Quits (e.g. UNIFLASH -SAVE BACKUP.BIN -QUIT)'); {v1.26}
 AddMsg(135, '-PCIROM must have either zero or three parameters (BUS, DEV, FUN)'); {v1.27}
 AddMsg(136, '-REPAIR         Repair erased chip ID (Winbond and SST chips)'); {v1.28}
 AddMsg(137, '-REPAIR must be preceded by -FORCE parameter with correct ID'); {v1.28}
 AddMsg(138, 'Only Winbond and SST chips can be repaired'); {v1.28}
end;
{$F-}

Begin
  RegisterLanguage('German',@InitGerman);
End.