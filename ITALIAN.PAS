Unit Italian; {v1.23}

Interface

Implementation

Uses Language;

Var
LId : Byte;

Begin
 LId := RegisterLanguage( 'Italiano' );
 AddMsg( LId, 1, 'Cancellazione...' );
 AddMsg( LId, 2, 'Programmazione...' );
 AddMsg( LId, 3, 'Verifica dati' );
 AddMsg( LId, 4, '         ERRORE NELLA VERIFICA DATI. RIPROVARE [S/N]?' );
 AddMsg( LId, 5, '         ATTENZIONE: BOOTBLOCK NON CORRISPONDE!! CONTINUARE [S,N]?' );
 AddMsg( LId, 6, 'NOme file immagine: ' );
 AddMsg( LId, 7, 'Impossibile creare il file ' );
 AddMsg( LId, 8, 'Impossibile aprire il file ' );
 AddMsg( LId, 9, 'LA DIMENSIONE DEL FILE NON CORRISPONDE ALLA FLASH ROM. CONTINUARE [S,N]?' );
 AddMsg( Lid, 10, 'ATTNZIONE: SI STA PER MODIFICARE IL BOOT BLOCK. CONTINUARE [S,N]?' );
 AddMsg( Lid, 11, 'ERRORE' );
 AddMsg( Lid, 12, 'SUCCESSO' );
 AddMsg( Lid, 13, ' nome file di dati: ' );
 AddMsg( Lid, 14, 'Dimensioni del file non valide - deve essere 4K !'#7 );
 AddMsg( Lid, 15, 'Vuoi Continuare (S/N)?' );
 AddMsg( Lid, 16, 'Attenzione: TUTTI I SETTAGGI SARANNO' );
 AddMsg( Lid, 17, ' CANCELLATI. CONTINUARE [S,N]?' );
 AddMsg( Lid, 18, ' nome file dati: ' );
 AddMsg( Lid, 19, 'nome del file Bootblock: ' );
 AddMsg( Lid, 20, 'RIPRISTINA IL BACKUP DEL BIOS NELLA ROM [S,N]?' );
 AddMsg( Lid, 21, '         ATTENZIONE: TUTTI I SETTAGGI DEL BIOS SARANNO PERSI. CONTINAURE [S,N]?' );
 AddMsg( Lid, 22, 'CANCELLATI ' );
 AddMsg( Lid, 23, ' BYTES DALLA RAM CMOS.' );
 AddMsg( Lid, 24, 'ERRORE CANCELLANDO LA RAM CMOS - POTREBBE ESSERE (IN PARTE) PROTETTA.'#7 );
 AddMsg( Lid, 25, '-REBOOT         Reboot after flashing (use together with -E)' ); {v1.28}
 AddMsg( Lid, 26, 'ERRORE DI SCRITTURA NELLA RAM CMOS - POTREBBE ESSERE(IN PARTE) PROTETTA.'#7 );
 AddMsg( Lid, 27, 'RIPRISTINA I DATI CMOS DI BACKUP [S,N]?' );
 AddMsg( Lid, 28, ' BYTES DI RAM CMOS SCRITTI.'#7 );
 AddMsg( Lid, 29, 'Manca il nome del file con l''opzione -' );
 AddMsg( Lid, 30, '-H or -?        Mostra questa schermata' );
 AddMsg( Lid, 31, '-E nomef        Programma il bios con il file nomef nella FLASH' );
 AddMsg( Lid, 32, '                ROM senza intervento dell utente' );
 AddMsg( Lid, 33, '-LOG            Enables auto-logging to UNIFLASH.LOG' ); {v1.23}
 AddMsg( Lid, 34, '-PCIOR          Opzione per flashare una ROM PCI' );
 AddMsg( Lid, 35, '  [BUS DEV FUN] Manually specify PCI device (decimal numbers)' );
 AddMsg( Lid, 36, '-AMI            Forza l''utilizzo dell'' AMI FLASH INTERFACE' );
 AddMsg( Lid, 37, 'Impossibile accedere alla maemoria estesa - prova con HIMEM.SYS.' );
 AddMsg( Lid, 38, 'Spiacente ma o non hai un 486+ la CPU è in V86 mode.' );
 AddMsg( Lid, 39, 'Seleziona la ROM PCI dalla lista sottostante:' );
 AddMsg( Lid, 40, 'BUS ' );
 AddMsg( Lid, 41, ' periferica ' );
 AddMsg( Lid, 42, ' functione ' );
 AddMsg( Lid, 43, '0. Esci' );
 AddMsg( Lid, 44, 'Select: 0' );
 AddMsg( Lid, 45, 'Non sono state trovate ROM PCI.' );
 AddMsg( Lid, 46, 'Vuoi salvare questo bios BIOS in un file? ' );
 AddMsg( Lid, 47, 'Nome del file: ' );
 AddMsg( Lid, 48, '            Fatto.' );
{ AddMsg( Lid, 49, 'La periferica selezionata non supporta Flash ROM.' );}
 AddMsg( Lid, 50, 'Non c''è abbastanza memoria..' );
 AddMsg( Lid, 51, '              Flash ROM chip: ' );
 AddMsg( Lid, 52, 'SCONOSCIUTO' );
 AddMsg( Lid, 53, '                Organisation: ' );
 AddMsg( Lid, 54, 'N/A (Is write protect disabled?)' ); {v1.23}
 AddMsg( Lid, 55, 'sectored: ' );
 AddMsg( Lid, 56, ' pagine di ' );
 AddMsg( Lid, 57, ' bytes' );
 AddMsg( Lid, 58, 'cancellazione bulk' );
 AddMsg( Lid, 59, ' sectori di ' );
 AddMsg( Lid, 60, 'Chip sconosciuto!' );
 AddMsg( Lid, 61, '                 PCI chipset: ' );
 AddMsg( Lid, 62, '           Stato ultima scrittura: ' );
 AddMsg( Lid, 63, 'non disponibile' );
 AddMsg( Lid, 64, 'Unable to read file!'#7 ); {v1.28}
 AddMsg( Lid, 65, 'Unable to write file!'#7 ); {v1.28}
(* AddMsg( Lid, 66, ', Periferica=' );
 AddMsg( Lid, 67, ' at ' ); *)
 AddMsg( Lid, 68, 'Memoria ' );
 AddMsg( Lid, 69, 'ROM base: ' );
 AddMsg( Lid, 70, ', dump memoria a ' );
 AddMsg( Lid, 71, '              Optione ROM per: ' );
 AddMsg( Lid, 72, 'periferica a ' );
 AddMsg( Lid, 73, 'Scrivi ESCD (PnP data) in un file' );
 AddMsg( Lid, 74, 'Programma ESCD (PnP data) nella Flash ROM' );
 AddMsg( Lid, 75, 'Cancella ESCD (PnP data)' );
{ AddMsg( Lid, 76, 'Scrivi i dati DMI in un file' );
 AddMsg( Lid, 77, 'Programma i dati DMI nella Flash ROM' );
 AddMsg( Lid, 78, 'Clear DMI data' );}
 AddMsg( Lid, 79, '® Ritorna a l menu principale' );
 AddMsg( Lid, 80, 'Salva i dati CMOS in un file' );
 AddMsg( Lid, 81, 'Ripristina i dati CMOS da un file' );
 AddMsg( Lid, 82, 'Programma il BIOS COMPRESO il bootblock' );
 AddMsg( Lid, 83, 'Scrivi il boot block in un file' );
 AddMsg( Lid, 84, 'Programma il bootblock nella Flash ROM' );
 AddMsg( Lid, 85, 'Scrivi il backup del BIOS in un file' );
 AddMsg( Lid, 86, 'Programma il BIOS nella Flash ROM' );
 AddMsg( Lid, 87, 'Programa il backup del BIOS Nella Flash ROM' );
 AddMsg( Lid, 88, 'Cancella i dati CMOS' );
 AddMsg( Lid, 89, 'Ripristina il backup dei dati CMOS' );
 AddMsg( Lid, 90, 'sottomenu'' ESCD (PnP) ¯' );
 AddMsg( Lid, 91, 'Sottomenu AVANZATO ¯' );
{ AddMsg( Lid, 92, 'Informazioni aggiuntive BIOS' );}
 AddMsg( Lid, 93, 'ESCI' );
 AddMsg( Lid, 94, 'L''ULTIMA PROGRAMMAZIONE NON HA AVUTO SUCCESSO. USCIRE [S/N]?'#7 );
 AddMsg( Lid, 95, ' !'#7 );  {Last part of msg 7 & 8 !!!!}
 AddMsg( Lid, 96, 'Invalid file size - Deve essere 8K !'#7 );
 AddMsg( Lid, 97, '' ); {->18}
 AddMsg( Lid, 98, 'Dimensioni del file non valide - must be exactly ' );
 AddMsg( Lid, 99, ' bytes !'#7 );
 AddMsg( Lid, 100, 'Redetect Flash ROM' ); {v1.23}
 AddMsg( Lid, 101, 'CMOS submenu ¯' ); {v1.23}
{ AddMsg( Lid, 100, 'BIOS Mfg: ' );
 AddMsg( Lid, 101, ' Modello BIOS: ' );
 AddMsg( Lid, 102, '  Part number: ' );
 AddMsg( Lid, 103, '    Id string: ' );
 AddMsg( Lid, 104, 'Mfg id string: ' );}
 AddMsg( Lid, 105, 'SN' );   {SI No}
 AddMsg( Lid, 106, 'l''opzione -FORCE deve essere seguta da 4 cifre hex' );
 AddMsg( Lid, 107, '-CHIPLIST       Mostra la lista dei fash chips supportati' );
 AddMsg( Lid, 108, '-FORCE xxxx     Forza le routines del chip xxxx (4 cifre hex)' );
 AddMsg( Lid, 109, '-SAVE nomef     Scrive il bios corrente nel file nomef' );
 AddMsg( Lid, 110, 'Questo programma non puo'' funzionare in Windows.' ); {v1.22}
 AddMsg( Lid, 111, 'Il Bus PCI non è presente o non risponde.' ); {v1.22}
 AddMsg( Lid, 112, 'Write ESCD (Plug & Play) data to file' ); {v1.23}
 AddMsg( Lid, 113, 'Flash ESCD (Plug & Play) data from file to Flash ROM' ); {v1.23}
 AddMsg( Lid, 114, 'Clear ESCD (Plug & Play) data in Flash ROM' ); {v1.23}
 AddMsg( Lid, 115, 'Flash BIOS image from file to Flash ROM including BootBlock' ); {v1.23}
 AddMsg( Lid, 116, 'Write BootBlock to file' ); {v1.23}
 AddMsg( Lid, 117, 'Flash BootBlock from file to Flash ROM' ); {v1.23}
 AddMsg( Lid, 118, 'Save current CMOS settings to file' ); {v1.23}
 AddMsg( Lid, 119, 'Restore CMOS settings from file' ); {v1.23}
 AddMsg( Lid, 120, 'Clear CMOS settings' ); {v1.23}
 AddMsg( Lid, 121, 'Restore backup CMOS settings from memory' ); {v1.23}
 AddMsg( Lid, 122, 'Write backup BIOS image from memory to file' ); {v1.23}
 AddMsg( Lid, 123, 'Flash BIOS image from file to Flash ROM (without BootBlock)' ); {v1.23}
 AddMsg( Lid, 124, 'Flash backup BIOS image from memory to Flash ROM' ); {v1.23}
 AddMsg( Lid, 125, 'Detect Flash ROM type and read its contents to backup in memory' ); {v1.23}
 AddMsg( Lid, 126, 'Enter CMOS settings submenu...' ); {v1.23}
 AddMsg( Lid, 127, 'Enter ESCD (PnP) submenu...' ); {v1.23}
 AddMsg( Lid, 128, 'Enter Advanced submenu...' ); {v1.23}
 AddMsg( Lid, 129, 'Exit UniFlash' ); {v1.23}
 AddMsg( Lid, 130, 'Return back to main menu' ); {v1.23}
 AddMsg( Lid, 131, '-CMOSS/R fname  Save/restore CMOS settings to/from file fname' ); {v1.28}
 AddMsg( Lid, 132, '-BASE xxxxx     Set ROM Base to address xxxxx (at least 5 hex digits)' ); {v1.28}
 AddMsg( Lid, 133, '-CMOSC          Clears CMOS settings' ); {v1.25}
 AddMsg( Lid, 134, '-QUIT           Quits (e.g. UNIFLASH -SAVE BACKUP.BIN -QUIT)'); {v1.26}
 AddMsg( Lid, 135, '-PCIOR must have either zero or three parameters (BUS, DEV, FUN)'); {v1.27}
 AddMsg( Lid, 136, '-REPAIR         Repair erased chip ID (Winbond and SST chips)'); {v1.28}
 AddMsg( Lid, 137, '-REPAIR must be preceded by -FORCE parameter with correct ID'); {v1.28}
 AddMsg( Lid, 138, 'Only Winbond and SST chips can be repaired'); {v1.28}
End.