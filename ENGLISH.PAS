unit English;

Interface

Implementation

Uses Language;

{$F+}
procedure InitEnglish;
begin
 AddMsg(1, 'Blanking in progress' );
 AddMsg(2, 'Flashing in progress' );
 AddMsg(3, 'Verifying data' );
 AddMsg(4, '         FLASH DATA VERIFICATION ERROR. RETRY WRITE OPERATION [Y/N]?' );
 AddMsg(5, '         WARNING: BOOTBLOCK MISMATCH !! PROCEED ANYWAY [Y,N]?' );
 AddMsg(6, 'Image file name: ' );
 AddMsg(7, 'Unable to create file ' );
 AddMsg(8, 'Unable to open file ' );
 AddMsg(9, 'FILE SIZE DOES NOT MATCH FLASH ROM CHIP SIZE!'#7 );
 AddMsg(10, 'FLASH BIOS INCLUDING BOOTBLOCK. PROCEED [Y,N]?' );
 AddMsg(11, 'ERROR' );
 AddMsg(12, 'SUCCESS' );
 AddMsg(13, ' data file name: ' );
{ AddMsg(14, 'Invalid file size - must be exactly 4K !'#7 );}
 AddMsg(15, 'Do you want to proceed (Y/N)?' );
{ AddMsg(16, 'WARNING: YOU WILL LOSE ALL ' );
 AddMsg(17, ' SETTINGS. PROCEED [Y,N]?' );}
 AddMsg(18, ' data file name: ' );
 AddMsg(19, 'Bootblock file name: ' );
 AddMsg(20, 'FLASH THE BACKUP BIOS IMAGE BACK INTO THE FLASH ROM [Y,N]?' );
 AddMsg(21, '         WARNING: YOU WILL LOSE ALL BIOS SETTINGS. PROCEED [Y,N]?' );
 AddMsg(22, 'CLEARED ' );
 AddMsg(23, ' BYTES OF CMOS RAM.' );
 AddMsg(24, 'ERROR CLEARING CMOS RAM - MAY BE (PARTIALLY) WRITE PROTECTED.'#7 );
 AddMsg(25, '-REBOOT         Reboot after flashing (use together with -E)' ); {v1.28}
 AddMsg(26, 'ERROR WRITING TO CMOS RAM - MAY BE (PARTIALLY) WRITE PROTECTED.'#7 );
 AddMsg(27, 'RESTORE BACKUP CMOS DATA [Y,N]?' );
 AddMsg(28, ' BYTES OF CMOS RAM WRITTEN.'#7 );
 AddMsg(29, 'Missing file name with option -' );
 AddMsg(30, '-H or -?        Shows this help screen' );
 AddMsg(31, '-E fname        Flashes fname to Flash ROM with no prompts' );
 AddMsg(32, '-CTFLASH [xxx]  Flash ROM in c''t Flasher 8-bit ISA card [xxx=port]' ); {v1.32}
 AddMsg(33, '-LOG            Enables auto-logging to UNIFLASH.LOG' ); {v1.23}
 AddMsg(34, '-PCIROM         Flash ROM on a PCI card instead of system ROM' ); {v1.29}
 AddMsg(35, '  [BUS DEV FUN] Manually specify PCI device (decimal numbers)' );
 AddMsg(36, '-AMI            Use AMI Flash Interface' ); {v1.24}
 AddMsg(37, 'Unable to access memory beyond 1Mb - try using HIMEM.SYS.' );
 AddMsg(38, 'Sorry, but either you don''t have a 486+ or CPU is in V86 mode.' );
 AddMsg(39, 'Select PCI card from list below:' ); {v1.29}
 AddMsg(40, 'Bus ' );
 AddMsg(41, ' device ' );
 AddMsg(42, ' function ' );
 AddMsg(43, '0. Quit' );
 AddMsg(44, 'Select: 0' );
 AddMsg(45, 'No PCI card with ROM found.' ); {v1.29}
 AddMsg(46, 'Do you want to save this BIOS to a file? ' );
 AddMsg(47, 'Name of the file: ' );
 AddMsg(48, '            Done.' );
 AddMsg(49, 'BOOTBLOCK MISMATCH. FLASH INCLUDING BOOTBLOCK (HIGHLY RECOMMENDED) [Y,N]?' ); {v1.30}
 AddMsg(50, 'Not enough free memory.' );
 AddMsg(51, '              Flash ROM chip: ' );
 AddMsg(52, 'UNKNOWN' );
 AddMsg(53, '                Organisation: ' );
 AddMsg(54, 'N/A (Is write protect disabled?)' ); {v1.23}
 AddMsg(55, 'sectored: ' );
 AddMsg(56, ' pages of ' );
 AddMsg(57, ' bytes' );
 AddMsg(58, 'bulk erase' );
 AddMsg(59, ' sectors of ' );
 AddMsg(60, 'Unknown flash chip !' );
 AddMsg(61, '                 PCI chipset: ' );
 AddMsg(62, '           Last write status: ' );
 AddMsg(63, 'not available' );
 AddMsg(64, 'Unable to read file!'#7 ); {v1.28}
 AddMsg(65, 'Unable to write file!'#7 ); {v1.28}
 AddMsg(66, '           Selected PCI card: ' ); {v1.29}
(* AddMsg(66, ', Device=' );
 AddMsg(67, ' at ' ); *)
 AddMsg(68, 'Memory: ' );
 AddMsg(69, 'ROM base: ' );
 AddMsg(70, ', memory dump at ' );
{ AddMsg(71, '              Option ROM for: ' );}
 AddMsg(72, 'device at ' );
{ AddMsg(73, 'Write ESCD (PnP data) to file' );
 AddMsg(74, 'Flash ESCD (PnP data) image to Flash ROM' );
 AddMsg(75, 'Clear ESCD (PnP data)' );
 AddMsg(76, 'Write DMI data to file' );
 AddMsg(77, 'Flash DMI data image to Flash ROM' );
 AddMsg(78, 'Clear DMI data' );}
 AddMsg(79, '® Back to main menu' );
 AddMsg(80, 'Save CMOS data to file' );
 AddMsg(81, 'Restore CMOS data from file' );
 AddMsg(82, 'Flash BIOS image WITHOUT bootblock' );
 AddMsg(83, 'Write boot block to file' );
 AddMsg(84, 'Flash bootblock to Flash ROM' );
 AddMsg(85, 'Write backup BIOS image to file' );
 AddMsg(86, 'Flash BIOS image INCLUDING bootblock' );
 AddMsg(87, 'Flash backup BIOS image to Flash ROM' );
 AddMsg(88, 'Clear CMOS data' );
 AddMsg(89, 'Restore backup CMOS data' );
{ AddMsg(90, 'ESCD (PnP) submenu ¯' );}
 AddMsg(91, 'ADVANCED submenu ¯' );
 AddMsg(92, '-BASE option must be followed by at least 5 hex digits' );
{ AddMsg(92, 'Additional BIOS info' );}
 AddMsg(93, 'Quit' );
 AddMsg(94, 'LAST FLASH WRITE WAS UNSUCCESFULL. QUIT ANYHOW [Y/N]?'#7 );
 AddMsg(95, ' !'#7 );  {Last part of msg 7 & 8 !!!!}
 AddMsg(96, 'Invalid file size - must be exactly 8K !'#7 );
 AddMsg(97, '' ); {->18}
 AddMsg(98, 'Invalid file size - must be exactly ' );
 AddMsg(99, ' bytes !'#7 );
 AddMsg(100, 'Redetect Flash ROM' ); {v1.23}
 AddMsg(101, 'CMOS submenu ¯' ); {v1.23}
{ AddMsg(100, 'BIOS Mfg: ' );
 AddMsg(101, '   BIOS Model: ' );
 AddMsg(102, '  Part number: ' );
 AddMsg(103, '    Id string: ' );
 AddMsg(104, 'Mfg id string: ' );}
 AddMsg(105, 'YN' );   {Yes No}
 AddMsg(106, '-FORCE option must be followed by 4 hex digits' );
 AddMsg(107, '-CHIPLIST       Show list of supported flash chips with their numbers' );
 AddMsg(108, '-FORCE xxxx     Force using routines for chip xxxx (4 hex digits)' );
 AddMsg(109, '-SAVE fname     Write current bios image to file fname' );
 AddMsg(110, 'This program can''t be run under Windows.' ); {v1.22}
 AddMsg(111, 'PCI bus not found or not responding.' ); {v1.22}
 AddMsg(112, 'c''t Flasher not found.'); {v1.32}
(* AddMsg(112, 'Write ESCD (Plug & Play) data to file' ); {v1.23}
 AddMsg(113, 'Flash ESCD (Plug & Play) data from file to Flash ROM' ); {v1.23}
 AddMsg(114, 'Clear ESCD (Plug & Play) data in Flash ROM' ); {v1.23}*)
 AddMsg(115, 'Flash BIOS image from file to Flash ROM without BootBlock' ); {v1.23}
 AddMsg(116, 'Write BootBlock to file' ); {v1.23}
 AddMsg(117, 'Flash BootBlock from file to Flash ROM' ); {v1.23}
 AddMsg(118, 'Save current CMOS settings to file' ); {v1.23}
 AddMsg(119, 'Restore CMOS settings from file' ); {v1.23}
 AddMsg(120, 'Clear CMOS settings' ); {v1.23}
 AddMsg(121, 'Restore backup CMOS settings from memory' ); {v1.23}
 AddMsg(122, 'Write backup BIOS image from memory to file' ); {v1.23}
 AddMsg(123, 'Flash BIOS image from file to Flash ROM including BootBlock' ); {v1.23}
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
 RegisterLanguage('English',InitEnglish);
End.