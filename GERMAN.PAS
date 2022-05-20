unit German; {v1.26}

Interface

Implementation

Uses Language;

Var
LId : Byte;

Begin
 LId := RegisterLanguage( 'German' );
 AddMsg( LId, 1, 'Loeschen in Arbeit' );
 AddMsg( LId, 2, 'Flashen in Arbeit' );
 AddMsg( LId, 3, 'Vergleiche Daten' );
 AddMsg( LId, 4, ' Inhalt des FLASH ist nicht identisch mit Datei! Schreiben wiederholen [Y/N]?' );
 AddMsg( LId, 5, '         Achtung: BOOTBLOCK Fehler !! Weiter [Y,N]?' );
 AddMsg( LId, 6, 'Dateiname: ' );
 AddMsg( LId, 7, 'Datei kann nicht erstellt werden ' );
 AddMsg( LId, 8, 'Datei kann nicht geoeffnet werden ' );
 AddMsg( LId, 9, 'DIE GROESSE DER DATEI WEICHT VOM CHIP AB! Weiter [Y,N]?' );
 AddMsg( Lid, 10, 'ACHTUNG: BOOT BLOCK wird veraendert. Weiter [Y,N]?' );
 AddMsg( Lid, 11, 'FEHLER' );
 AddMsg( Lid, 12, 'ERFOLGREICH' );
 AddMsg( Lid, 13, ' Dateiname: ' );
 AddMsg( Lid, 14, 'Falsche Dateigroesse - muss genau 4K betragen!'#7 );
 AddMsg( Lid, 15, 'Wollen Sie weitermachen (Y/N)?' );
 AddMsg( Lid, 16, 'Achtung: Alles wird geloescht! ' );
 AddMsg( Lid, 17, ' Einstellungen. Weiter [Y,N]?' );
 AddMsg( Lid, 18, ' Dateiname: ' );
 AddMsg( Lid, 19, 'Dateiname fÅr Bootblock: ' );
 AddMsg( Lid, 20, 'Flashe Datei in das FLASH ROM [Y,N]?' );
 AddMsg( Lid, 21, '         ACHTUNG! Sie verlieren alle BIOS Einstellungen. Weiter [Y,N]?' );
 AddMsg( Lid, 22, 'Geloescht ' );
 AddMsg( Lid, 23, ' BYTES von CMOS RAM.' );
 AddMsg( Lid, 24, 'Fehler beim Loeschen von CMOS RAM - eventuell (teilweise) SCHREIBGESCHUETZT.'#7 );
 AddMsg( Lid, 25, '-REBOOT         Reboot after flashing (use together with -E)' ); {v1.28}
 AddMsg( Lid, 26, 'Fehler beim Schreiben in das CMOS RAM - eventuell (teilweise) SCHREIBGESCHUETZT.'#7 );
 AddMsg( Lid, 27, 'CMOS Daten aus Backup wiederherstellen [Y,N]?' );
 AddMsg( Lid, 28, ' BYTES von CMOS RAM geschrieben.'#7 );
 AddMsg( Lid, 29, 'Vermisse Dateiname mit Option -' );
 AddMsg( Lid, 30, '-H oder -?      Zeigt die Hilfe an' );
 AddMsg( Lid, 31, '-E fname        Flasht Bios Abbild von Datei fname in das Flash' );
 AddMsg( Lid, 32, '                ROM ohne jeglichen Eigriff durch Benutzer' );
 AddMsg( Lid, 33, '-LOG            Aktiviert Protokollierung in UNIFLASH.LOG' ); {v1.23}
 AddMsg( Lid, 34, '-PCIOR          Flasht PCI Options ROM statt des System ROM' );
 AddMsg( Lid, 35, '  [BUS DEV FUN] Manually specify PCI device (decimal numbers)' );
 AddMsg( Lid, 36, '-AMI            Verwendet AMI Flash Interface' ); {v1.24}
 AddMsg( Lid, 37, 'Kein Speicherzugriff jenseits 1Mb - Benutzen Sie HIMEM.SYS.' );
 AddMsg( Lid, 38, 'Sie duerfen eine 486+ oder groessere CPU nicht im V86 Modus betreiben.' );
 AddMsg( Lid, 39, 'Selektiere PCI option ROM aus folgender Liste:' );
 AddMsg( Lid, 40, 'Bus ' );
 AddMsg( Lid, 41, ' Geraet ' );
 AddMsg( Lid, 42, ' Funktion ' );
 AddMsg( Lid, 43, '0. Ende' );
 AddMsg( Lid, 44, 'Gewaehlt: 0' );
 AddMsg( Lid, 45, 'Keine PCI Options ROMs gefunden.' );
 AddMsg( Lid, 46, 'Moechten Sie das Bios in eine Datei sichern? ' );
 AddMsg( Lid, 47, 'Name der Datei: ' );
 AddMsg( Lid, 48, '            ausgefuehrt.' );
{ AddMsg( Lid, 49, 'Gewaehlte Quelle''n Options ROM ist kein a unterstuetztes Flash ROM.' );}
 AddMsg( Lid, 50, 'Nicht genug freier Speicher.' );
 AddMsg( Lid, 51, '              Flash ROM Chip: ' );
 AddMsg( Lid, 52, 'Unbekannt' );
 AddMsg( Lid, 53, '                Organisation: ' );
 AddMsg( Lid, 54, 'Nicht moeglich (Ist Schreibschutz ausgeschaltet?)' ); {v1.23}
 AddMsg( Lid, 55, 'Sektoren: ' );
 AddMsg( Lid, 56, ' Seiten zu je ' );
 AddMsg( Lid, 57, ' Bytes' );
 AddMsg( Lid, 58, 'vollstaendig geloescht' );
 AddMsg( Lid, 59, ' Sectoren von ' );
 AddMsg( Lid, 60, 'Unbekannter Flash Chip !' );
 AddMsg( Lid, 61, '                 PCI Chipsatz: ' );
 AddMsg( Lid, 62, '           Letzter Schreibstatus: ' );
 AddMsg( Lid, 63, 'nicht verfuegbar' );
 AddMsg( Lid, 64, 'Unable to read file!'#7 ); {v1.28}
 AddMsg( Lid, 65, 'Unable to write file!'#7 ); {v1.28}
(* AddMsg( Lid, 66, ', Geraet=' );
 AddMsg( Lid, 67, ' von ' ); *)
 AddMsg( Lid, 68, 'Speicher: ' );
 AddMsg( Lid, 69, 'ROM Basis: ' );
 AddMsg( Lid, 70, ', Speicher Abbild von ' );
 AddMsg( Lid, 71, '              Options ROM fÅr: ' );
 AddMsg( Lid, 72, 'Geraet an ' );
 AddMsg( Lid, 73, 'Schreibe ESCD (PnP Daten) in Datei' );
 AddMsg( Lid, 74, 'Flashe ESCD (PnP Daten) Datei in Flash ROM' );
 AddMsg( Lid, 75, 'Loesche ESCD (PnP Daten)' );
{ AddMsg( Lid, 76, 'Schreibe DMI Daten in Datei' );
 AddMsg( Lid, 77, 'Flashe DMI Datei ins Flash ROM' );
 AddMsg( Lid, 78, 'Loesche DMI Daten' );}
 AddMsg( Lid, 79, 'Æ zurueck zum Hauptmenue' );
 AddMsg( Lid, 80, 'Sichere CMOS in Datei' );
 AddMsg( Lid, 81, 'Wiederherstellen von CMOS aus Datei' );
 AddMsg( Lid, 82, 'Flashe BIOS Image inklusive Bootblock' );
 AddMsg( Lid, 83, 'Sichere Bootblock in Datei' );
 AddMsg( Lid, 84, 'Flashe Bootblock ins Flash ROM' );
 AddMsg( Lid, 85, 'Schreibe BIOS-Image in Datei' );
 AddMsg( Lid, 86, 'Flashe BIOS-Image ins Flash ROM' );
 AddMsg( Lid, 87, 'Flashe BIOS-Image noch 1x ins Flash ROM' );
 AddMsg( Lid, 88, 'Loesche CMOS Daten' );
 AddMsg( Lid, 89, 'Wiederherstellung  des CMOS von Datentraeger' );
 AddMsg( Lid, 90, 'ESCD (PnP) Submenue Ø' );
 AddMsg( Lid, 91, 'Fortgeschrittenen Submenue Ø' );
{ AddMsg( Lid, 92, 'Zusaetzliche BIOS Info' );}
 AddMsg( Lid, 93, 'Ende' );
 AddMsg( Lid, 94, 'Letztes Schreiben des Flash war erfolgreich. Beenden [Y/N]?'#7 );
 AddMsg( Lid, 95, ' !'#7 );  {Letzter Teil von msg 7 & 8 !!!!}
 AddMsg( Lid, 96, 'Falsche Dateigroesse - muss genau  8K betragen!'#7 );
 AddMsg( Lid, 97, '' ); {->18}
 AddMsg( Lid, 98, 'Falsche Dateigroesse muss exakt betragen ' );
 AddMsg( Lid, 99, ' Bytes !'#7 );
 AddMsg( Lid, 100, 'Neue Suche nach Flash ROM Typ' ); {v1.23}
 AddMsg( Lid, 101, 'CMOS Submenue Ø' ); {v1.23}
{ AddMsg( Lid, 100, 'BIOS Hersteller: ' );
 AddMsg( Lid, 101, '   BIOS Modell: ' );
 AddMsg( Lid, 102, '  Zubehîrnummer: ' );
 AddMsg( Lid, 103, '    Identifikationsnummer: ' );
 AddMsg( Lid, 104, 'Hersteller Identifikationsnummer: ' );}
 AddMsg( Lid, 105, 'YN' );   {Ja Nein}
 AddMsg( Lid, 106, '-FORCE Option muss gefolgt werden von 4 hex Ziffern' );
 AddMsg( Lid, 107, '-CHIPLIST       Liste der unterstÅtzten Flash Chips' );
 AddMsg( Lid, 108, '-FORCE xxxx     Force benutzt Routinen fÅr Chip xxxx (4 hex Ziffern)' );
 AddMsg( Lid, 109, '-SAVE fname     schreibt verwendetes Bios in Datei fname' );
 AddMsg( Lid, 110, 'Dieses programm kann nicht unter Windows laufen.' ); {v1.22}
 AddMsg( Lid, 111, 'PCI Bus nicht gefunden oder antwortet nicht.' ); {v1.22}
 AddMsg( Lid, 112, 'Schreibe ESCD (Plug & Play) Daten in Datei' ); {v1.23}
 AddMsg( Lid, 113, 'Flashe ESCD (Plug & Play) Daten von Datei in Flash ROM' ); {v1.23}
 AddMsg( Lid, 114, 'Loesche ESCD (Plug & Play) daten im Flash ROM' ); {v1.23}
 AddMsg( Lid, 115, 'Flashe BIOS Image aus Datei in Flash ROM inclusive BootBlock' ); {v1.23}
 AddMsg( Lid, 116, 'Sichere BootBlock in Datei' ); {v1.23}
 AddMsg( Lid, 117, 'Flashe BootBlock aus Datei in Flash ROM' ); {v1.23}
 AddMsg( Lid, 118, 'Sichere vorhandene CMOS Einstellungen in Datei' ); {v1.23}
 AddMsg( Lid, 119, 'Stelle CMOS Einstellungen aus Datei wieder her' ); {v1.23}
 AddMsg( Lid, 120, 'Loesche CMOS Einstellungen' ); {v1.23}
 AddMsg( Lid, 121, 'Wiederherstellung der CMOS Einstellungen aus Speicher' ); {v1.23}
 AddMsg( Lid, 122, 'Schreibe gesichertes BIOS Image vom FLASH in Datei' ); {v1.23}
 AddMsg( Lid, 123, 'Flashe BIOS Image aus Datei in Flash ROM (ohne Bootblock)' ); {v1.23}
 AddMsg( Lid, 124, 'Flashe eingelesenes BIOS Image aus RAM in das Flash ROM' ); {v1.23}
 AddMsg( Lid, 125, 'Identifiziere Flash ROM Typ und lese Inhalt zur Sicherung in den Speicher' ); {v1.23}
 AddMsg( Lid, 126, 'Waehle CMOS Einstellungen Untermenue...' ); {v1.23}
 AddMsg( Lid, 127, 'Waehle ESCD (PnP) Untwermenue...' ); {v1.23}
 AddMsg( Lid, 128, 'Waehle Fortgeschrittenen Untermenue...' ); {v1.23}
 AddMsg( Lid, 129, 'Beende UniFlash' ); {v1.23}
 AddMsg( Lid, 130, 'Zurueck zum Hauptmenue' ); {v1.23}
 AddMsg( Lid, 131, '-CMOSS/R fname  Save/restore CMOS settings to/from file fname' ); {v1.28}
 AddMsg( Lid, 132, '-BASE xxxxx     Set ROM Base to address xxxxx (at least 5 hex digits)' ); {v1.28}
 AddMsg( Lid, 133, '-CMOSC          Loescht CMOS Einstellungen' ); {v1.25}
 AddMsg( Lid, 134, '-QUIT           Quits (e.g. UNIFLASH -SAVE BACKUP.BIN -QUIT)'); {v1.26}
 AddMsg( Lid, 135, '-PCIOR must have either zero or three parameters (BUS, DEV, FUN)'); {v1.27}
 AddMsg( Lid, 136, '-REPAIR         Repair erased chip ID (Winbond and SST chips)'); {v1.28}
 AddMsg( Lid, 137, '-REPAIR must be preceded by -FORCE parameter with correct ID'); {v1.28}
 AddMsg( Lid, 138, 'Only Winbond and SST chips can be repaired'); {v1.28}
End.