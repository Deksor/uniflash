Unit Italian; {v1.23}

Interface

Implementation

Uses Language;

{$F+}
procedure InitItalian;
begin
 AddMsg(1, 'Cancellazione...' );
 AddMsg(2, 'Programmazione...' );
 AddMsg(3, 'Verifica dati' );
 AddMsg(4, '         ERRORE NELLA VERIFICA DATI. RIPROVARE [S/N]?' );
 AddMsg(5, '         ATTENZIONE: BOOTBLOCK NON CORRISPONDE!! CONTINUARE [S,N]?' );
 AddMsg(6, 'NOme file immagine: ' );
 AddMsg(7, 'Impossibile creare il file ' );
 AddMsg(8, 'Impossibile aprire il file ' );
 AddMsg(9, 'LA DIMENSIONE DEL FILE NON CORRISPONDE ALLA FLASH ROM. CONTINUARE [S,N]?' );
 AddMsg(10, 'ATTNZIONE: SI STA PER MODIFICARE IL BOOT BLOCK. CONTINUARE [S,N]?' );
 AddMsg(11, 'ERRORE' );
 AddMsg(12, 'SUCCESSO' );
 AddMsg(13, ' nome file di dati: ' );
{ AddMsg(14, 'Dimensioni del file non valide - deve essere 4K !'#7 );}
 AddMsg(15, 'Vuoi Continuare (S/N)?' );
{ AddMsg(16, 'Attenzione: TUTTI I SETTAGGI SARANNO' );
 AddMsg(17, ' CANCELLATI. CONTINUARE [S,N]?' );}
 AddMsg(18, ' nome file dati: ' );
 AddMsg(19, 'nome del file Bootblock: ' );
 AddMsg(20, 'RIPRISTINA IL BACKUP DEL BIOS NELLA ROM [S,N]?' );
 AddMsg(21, '         ATTENZIONE: TUTTI I SETTAGGI DEL BIOS SARANNO PERSI. CONTINAURE [S,N]?' );
 AddMsg(22, 'CANCELLATI ' );
 AddMsg(23, ' BYTES DALLA RAM CMOS.' );
 AddMsg(24, 'ERRORE CANCELLANDO LA RAM CMOS - POTREBBE ESSERE (IN PARTE) PROTETTA.'#7 );
 AddMsg(25, '-REBOOT         Reboot after flashing (use together with -E)' ); {v1.28}
 AddMsg(26, 'ERRORE DI SCRITTURA NELLA RAM CMOS - POTREBBE ESSERE(IN PARTE) PROTETTA.'#7 );
 AddMsg(27, 'RIPRISTINA I DATI CMOS DI BACKUP [S,N]?' );
 AddMsg(28, ' BYTES DI RAM CMOS SCRITTI.'#7 );
 AddMsg(29, 'Manca il nome del file con l''opzione -' );
 AddMsg(30, '-H or -?        Mostra questa schermata' );
 AddMsg(31, '-E nomef        Programma il bios nomef nella FLASH' );
 AddMsg(32, '-CTFLASH [xxx]  Flash ROM in c''t Flasher 8-bit ISA card [xxx=port]' ); {v1.32}
 AddMsg(33, '-LOG            Enables auto-logging to UNIFLASH.LOG' ); {v1.23}
 AddMsg(34, '-PCIROM         Flash ROM on a PCI card instead of system ROM' ); {v1.29}
 AddMsg(35, '  [BUS DEV FUN] Manually specify PCI device (decimal numbers)' );
 AddMsg(36, '-AMI            Forza l''utilizzo dell'' AMI FLASH INTERFACE' );
 AddMsg(37, 'Impossibile accedere alla maemoria estesa - prova con HIMEM.SYS.' );
 AddMsg(38, 'Spiacente ma o non hai un 486+ la CPU è in V86 mode.' );
 AddMsg(39, 'Seleziona la ROM PCI dalla lista sottostante:' );
 AddMsg(40, 'BUS ' );
 AddMsg(41, ' periferica ' );
 AddMsg(42, ' functione ' );
 AddMsg(43, '0. Esci' );
 AddMsg(44, 'Select: 0' );
 AddMsg(45, 'Non sono state trovate ROM PCI.' );
 AddMsg(46, 'Vuoi salvare questo bios BIOS in un file? ' );
 AddMsg(47, 'Nome del file: ' );
 AddMsg(48, '            Fatto.' );
 AddMsg(49, 'BOOTBLOCK MISMATCH. FLASH INCLUDING BOOTBLOCK (HIGHLY RECOMMENDED) [Y,N]?' ); {v1.30}
 AddMsg(50, 'Non c''è abbastanza memoria..' );
 AddMsg(51, '              Flash ROM chip: ' );
 AddMsg(52, 'SCONOSCIUTO' );
 AddMsg(53, '                Organisation: ' );
 AddMsg(54, 'N/A (Is write protect disabled?)' ); {v1.23}
 AddMsg(55, 'sectored: ' );
 AddMsg(56, ' pagine di ' );
 AddMsg(57, ' bytes' );
 AddMsg(58, 'cancellazione bulk' );
 AddMsg(59, ' sectori di ' );
 AddMsg(60, 'Chip sconosciuto!' );
 AddMsg(61, '                 PCI chipset: ' );
 AddMsg(62, '      Stato ultima scrittura: ' );
 AddMsg(63, 'non disponibile' );
 AddMsg(64, 'Unable to read file!'#7 ); {v1.28}
 AddMsg(65, 'Unable to write file!'#7 ); {v1.28}
 AddMsg(66, '           Selected PCI card: ' ); {v1.29}
(* AddMsg(66, ', Periferica=' );
 AddMsg(67, ' at ' ); *)
 AddMsg(68, 'Memoria ' );
 AddMsg(69, 'ROM base: ' );
 AddMsg(70, ', dump memoria a ' );
 AddMsg(71, '              Optione ROM per: ' );
 AddMsg(72, 'periferica a ' );
{ AddMsg(73, 'Scrivi ESCD (PnP data) in un file' );
 AddMsg(74, 'Programma ESCD (PnP data) nella Flash ROM' );
 AddMsg(75, 'Cancella ESCD (PnP data)' );
 AddMsg(76, 'Scrivi i dati DMI in un file' );
 AddMsg(77, 'Programma i dati DMI nella Flash ROM' );
 AddMsg(78, 'Clear DMI data' );}
 AddMsg(79, '® Ritorna a l menu principale' );
 AddMsg(80, 'Salva i dati CMOS in un file' );
 AddMsg(81, 'Ripristina i dati CMOS da un file' );
 AddMsg(82, 'Programma il BIOS COMPRESO il bootblock' );
 AddMsg(83, 'Scrivi il boot block in un file' );
 AddMsg(84, 'Programma il bootblock nella Flash ROM' );
 AddMsg(85, 'Scrivi il backup del BIOS in un file' );
 AddMsg(86, 'Programma il BIOS nella Flash ROM' );
 AddMsg(87, 'Programa il backup del BIOS Nella Flash ROM' );
 AddMsg(88, 'Cancella i dati CMOS' );
 AddMsg(89, 'Ripristina il backup dei dati CMOS' );
{ AddMsg(90, 'sottomenu'' ESCD (PnP) ¯' );}
 AddMsg(91, 'Sottomenu AVANZATO ¯' );
{ AddMsg(92, 'Informazioni aggiuntive BIOS' );}
 AddMsg(93, 'ESCI' );
 AddMsg(94, 'L''ULTIMA PROGRAMMAZIONE NON HA AVUTO SUCCESSO. USCIRE [S/N]?'#7 );
 AddMsg(95, ' !'#7 );  {Last part of msg 7 & 8 !!!!}
 AddMsg(96, 'Invalid file size - Deve essere 8K !'#7 );
 AddMsg(97, '' ); {->18}
 AddMsg(98, 'Dimensioni del file non valide - must be exactly ' );
 AddMsg(99, ' bytes !'#7 );
 AddMsg(100, 'Redetect Flash ROM' ); {v1.23}
 AddMsg(101, 'CMOS submenu ¯' ); {v1.23}
{ AddMsg(100, 'BIOS Mfg: ' );
 AddMsg(101, ' Modello BIOS: ' );
 AddMsg(102, '  Part number: ' );
 AddMsg(103, '    Id string: ' );
 AddMsg(104, 'Mfg id string: ' );}
 AddMsg(105, 'SN' );   {SI No}
 AddMsg(106, 'l''opzione -FORCE deve essere seguta da 4 cifre hex' );
 AddMsg(107, '-CHIPLIST       Mostra la lista dei fash chips supportati' );
 AddMsg(108, '-FORCE xxxx     Forza le routines del chip xxxx (4 cifre hex)' );
 AddMsg(109, '-SAVE nomef     Scrive il bios corrente nel file nomef' );
 AddMsg(110, 'Questo programma non puo'' funzionare in Windows.' ); {v1.22}
 AddMsg(111, 'Il Bus PCI non è presente o non risponde.' ); {v1.22}
 AddMsg(112, 'c''t Flasher not found.'); {v1.32}
(* AddMsg(112, 'Write ESCD (Plug & Play) data to file' ); {v1.23}
 AddMsg(113, 'Flash ESCD (Plug & Play) data from file to Flash ROM' ); {v1.23}
 AddMsg(114, 'Clear ESCD (Plug & Play) data in Flash ROM' ); {v1.23}*)
 AddMsg(115, 'Flash BIOS image from file to Flash ROM including BootBlock' ); {v1.23}
 AddMsg(116, 'Write BootBlock to file' ); {v1.23}
 AddMsg(117, 'Flash BootBlock from file to Flash ROM' ); {v1.23}
 AddMsg(118, 'Save current CMOS settings to file' ); {v1.23}
 AddMsg(119, 'Restore CMOS settings from file' ); {v1.23}
 AddMsg(120, 'Clear CMOS settings' ); {v1.23}
 AddMsg(121, 'Restore backup CMOS settings from memory' ); {v1.23}
 AddMsg(122, 'Write backup BIOS image from memory to file' ); {v1.23}
 AddMsg(123, 'Flash BIOS image from file to Flash ROM (without BootBlock)' ); {v1.23}
 AddMsg(124, 'Flash backup BIOS image from memory to Flash ROM' ); {v1.23}
 AddMsg(125, 'Detect Flash ROM type and read its contents to backup in memory' ); {v1.23}
 AddMsg(126, 'Enter CMOS settings submenu...' ); {v1.23}
(* AddMsg(127, 'Enter ESCD (PnP) submenu...' ); {v1.23}*)
 AddMsg(128, 'Enter Advanced submenu...' ); {v1.23}
 AddMsg(129, 'Exit UniFlash' ); {v1.23}
 AddMsg(130, 'Return back to main menu' ); {v1.23}
 AddMsg(131, '-CMOSS/R fname  Save/restore CMOS settings to/from file fname' ); {v1.28}
 AddMsg(132, '-BASE xxxxx     Set ROM Base to address xxxxx (at least 5 hex digits)' ); {v1.28}
 AddMsg(133, '-CMOSC          Clears CMOS settings' ); {v1.25}
 AddMsg(134, '-QUIT           Quits (e.g. UNIFLASH -SAVE BACKUP.BIN -QUIT)'); {v1.26}
 AddMsg(135, '-PCIROM must have either zero or three parameters (BUS, DEV, FUN)'); {v1.27}
 AddMsg(136, '-REPAIR         Repair erased chip ID (Winbond and SST chips)'); {v1.28}
 AddMsg(137, '-REPAIR must be preceded by -FORCE parameter with correct ID'); {v1.28}
 AddMsg(138, 'Only Winbond and SST chips can be repaired'); {v1.28}
end;
{$F-}

Begin
  RegisterLanguage('Italiano',InitItalian);
End.