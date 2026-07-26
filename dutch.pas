Unit Dutch;

Interface

Implementation

Uses Language;

{$F+}
procedure InitDutch;
begin
 AddMsg(1, ' Bezig met wissen' );
 AddMsg(2, 'Bezig met flashen' );
 AddMsg(3, 'Controleren data' );
 AddMsg(4, 'DATA NIET CORRECT WEGGESCHREVEN. OVERNIEUW PROBEREN [J/N]?' );
 AddMsg(5, '         WARNING: BOOTBLOCK MISMATCH !! PROCEED ANYWAY [Y,N]?' );
 AddMsg(6, 'Bestandsnaam : ' );
 AddMsg(7, 'Creeren van bestand ' );
 AddMsg(8, 'Openen van bestand ' );
 AddMsg(9, 'BESTANDSGROOTTE KOMT NIET OVEREEN MET ROM. TOCH DOORGAAN [J,N]?' );
 AddMsg(10, 'WAARSCHUWING: BOOTBLOCK WORDT GEWIJZIGD. DOORGAAN [J,N]?' );
 AddMsg(11, 'FOUT' );
 AddMsg(12, 'SUCCES' );
 AddMsg(13, ' bestandsnaam: ' );
{ AddMsg(14, 'Foutieve bestandsgrootte - moet exact 4K zijn !'#7 );}
 AddMsg(15, 'Wilt u doorgaan (J/N)?' );
{ AddMsg(16, 'WAARSCHUWING: U ZAL ALLE ' );
 AddMsg(17, ' GEGEVENS VERLIEZEN. DOORGAAN [J,N]?' );}
 AddMsg(18, ' bestandsnaam : ' );
 AddMsg(19, 'Bootblock bestandsnaam: ' );
 AddMsg(20, 'OUDE BIOS TERUG FLASHEN NAAR FLASH ROM CHIP [J,N]?' );
 AddMsg(21, ' WAARSCHUWING: U ZAL ALLE BIOS INSTELLINGEN VERLIEZEN. DOORGAAN [J,N]?' );
 AddMsg(22, 'HEB ' );
 AddMsg(23, ' BYTES CMOS RAM GEWIST.' );
 AddMsg(24, 'FOUT BIJ HET WISSEN VAN CMOS - CMOS (GEDEELTELIJK) SCHRIJFBEVEILIGD.'#7 );
 AddMsg(25, '-REBOOT         Reboot after flashing (use together with -E)' ); {v1.28}
 AddMsg(26, 'FOUT BIJ HET SCHRIJVEN NAAR CMOS - CMOS (GEDEELTELIJK) SCHRIJFBEVEILIGD.'#7 );
 AddMsg(27, 'OUDE CMOS GEGEVENS TERUGSCHRIJVEN [J,N]?' );
 AddMsg(28, ' BYTES CMOS RAM GESCHREVEN.'#7 );
 AddMsg(29, 'Missing file name with option -' );
 AddMsg(30, '-H or -?        Toont dit hulp scherm' );
 AddMsg(31, '-E bnaam        Flasht bios image vanuit bestand bnaam automatisch' );
 AddMsg(32, '-CTFLASH [xxx]  Flash ROM in c''t Flasher 8-bit ISA card [xxx=port]' ); {v1.32}
 AddMsg(33, '-LOG            Enables auto-logging to UNIFLASH.LOG' ); {v1.23}
 AddMsg(34, '-PCIROM         Flash ROM on a PCI card instead of system ROM' ); {v1.29}
 AddMsg(35, '  [BUS DEV FUN] Manually specify PCI device (decimal numbers)' );
 AddMsg(36, '-AMI            Forceer het gebruik van de AMI FLASH INTERFACE' );
 AddMsg(37, 'Kan geheugen boven de 1M niet aanspreken - probeer HIMEM.SYS.' );
 AddMsg(38, 'Sorry, maar je hebt geen 486 of beter of de processor is in V86 Mode.' );
 AddMsg(39, 'Select PCI card from list below:' ); {v1.29}
 AddMsg(40, 'Bus ' );
 AddMsg(41, ' device ' );
 AddMsg(42, ' function ' );
 AddMsg(43, '0. Quit' );
 AddMsg(44, ' Keuze: 0' );
 AddMsg(45, 'No PCI card with ROM found.' ); {v1.29}
 AddMsg(46, 'Wilt u dit BIOS naar een bestand wegschrijven? ' );
 AddMsg(47, 'Bestandsnaam: ' );
 AddMsg(48, '           Klaar.' );
 AddMsg(49, 'BOOTBLOCK MISMATCH. FLASH INCLUDING BOOTBLOCK (HIGHLY RECOMMENDED) [Y,N]?' ); {v1.30}
 AddMsg(50, 'Niet genoeg vrij geheugen' );
 AddMsg(51, '              Flash ROM chip: ' );
 AddMsg(52, 'ONBEKEND' );
 AddMsg(53, '                 Organisatie: ' );
 AddMsg(54, 'nvt (Is write protect disabled?)' ); {v1.23}
 AddMsg(55, 'sectored: ' );
 AddMsg(56, ' pagina''s van ' );
 AddMsg(57, ' bytes' );
 AddMsg(58, 'bulk erase' );
 AddMsg(59, ' sectors van ' );
 AddMsg(60, 'Onbekende flash chip !' );
 AddMsg(61, '                 PCI chipset: ' );
 AddMsg(62, ' Status laatste schrijfactie: ' );
 AddMsg(63, 'niet beschikbaar' );
 AddMsg(64, 'Unable to read file!'#7 ); {v1.28}
 AddMsg(65, 'Unable to write file!'#7 ); {v1.28}
 AddMsg(66, '           Selected PCI card: ' ); {v1.29}
(* AddMsg(66, ', Device=' );
 AddMsg(67, ' at ' ); *)
 AddMsg(68, 'Geheugen: ' );
 AddMsg(69, 'ROM base: ' );
 AddMsg(70, ', geheugen dump op ' );
 AddMsg(71, '              Optie ROM voor: ' );
 AddMsg(72, 'device op ' );
{ AddMsg(73, 'Schrijf ESCD blok (PnP gegevens) naar schijf' );
 AddMsg(74, 'Flash ESCD blok (PnP gegevens) naar Flash ROM' );
 AddMsg(75, 'Wis ESCD blok (PnP data)' );
 AddMsg(76, 'Schrijf DMI gegevensblok naar disk' );
 AddMsg(77, 'Flash DMI gegevensblok naar Flash ROM' );
 AddMsg(78, 'Wis DMI gegevensblok' );}
 AddMsg(79, 'Terug naar hoofdmenu' );
 AddMsg(80, 'Schrijf CMOS gegevens naar schrijf' );
 AddMsg(81, 'Lees CMOS gegevens van schijf' );
 AddMsg(82, 'Flash BIOS INCLUSIEF bootblock' );
 AddMsg(83, 'Schrijf bootblock naar schijf' );
 AddMsg(84, 'Flash bootblock naar Flash ROM' );
 AddMsg(85, 'Schrijf oude BIOS naar schijf' );
 AddMsg(86, 'Flash BIOS naar Flash ROM' );
 AddMsg(87, 'Flash oude BIOS terug naar Flash ROM' );
 AddMsg(88, 'Wis CMOS gegevens' );
 AddMsg(89, 'Schrijf oude CMOS gegevens terug naar CMOS' );
{ AddMsg(90, 'ESCD (PnP) submenu' );}
 AddMsg(91, 'Geavanceerde opties submenu' );
{ AddMsg(92, 'Additionele BIOS informatie' );}
 AddMsg(93, 'Verlaat UNIFLASH' );
 AddMsg(94, 'LAATSTE SCHRIJFOPERATIE NAAR FLASHROM WAS ONSUCCESVOL. TOCH VERLATEN [J/N]?'#7 );
 AddMsg(95, ' niet gelukt !'#7 );  {Last part of msg 7 & 8 !!!!}
 AddMsg(96, 'Foutieve bestandsgrootte - moet exact 8K zijn !'#7 );
 AddMsg(97, '' ); {->18}
 AddMsg(98, 'Foutieve bestandsgrootte - moet exact ' );
 AddMsg(99, ' bytes zijn !'#7 );
 AddMsg(100, 'Redetect Flash ROM' ); {v1.23}
 AddMsg(101, 'CMOS submenu ¯' ); {v1.23}
{ AddMsg(100, 'BIOS Mfg: ' );
 AddMsg(101, '   BIOS Model: ' );
 AddMsg(102, '  Part number: ' );
 AddMsg(103, '    Id string: ' );
 AddMsg(104, 'Mfg id string: ' );}
 AddMsg(105, 'JN' );   {Ja Nee}
 AddMsg(106, 'Na -FORCE optie moeten 4 hex. karakters volgen' );
 AddMsg(107, '-CHIPLIST       Toon lijst met ondersteunde flash chips' );
 AddMsg(108, '-FORCE xxxx     Doe net alsof chip xxxx (4 hex cijfers) is gevonden' );
 AddMsg(109, '-SAVE bnaam     Schrijf huidige bios image naar bestand bnaam' );
 AddMsg(110, 'This program can''t be run under Windows.' ); {v1.22}
 AddMsg(111, 'PCI bus not found or not responding.' ); {v1.22}
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
 RegisterLanguage('Nederlands',InitDutch);
End.