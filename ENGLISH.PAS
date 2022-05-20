unit English;

Interface

Implementation

Uses Language;

Var
LId : Byte;

Begin
 LId := RegisterLanguage( 'English' );
 AddMsg( LId, 1, 'Blanking in progress' );
 AddMsg( LId, 2, 'Flashing in progress' );
 AddMsg( LId, 3, 'Verifying data' );
 AddMsg( LId, 4, '         FLASH DATA VERIFICATION ERROR. RETRY WRITE OPERATION [Y/N]?' );
 AddMsg( LId, 5, '         WARNING: BOOTBLOCK MISMATCH !! PROCEED ANYWAY [Y,N]?' );
 AddMsg( LId, 6, 'Image file name: ' );
 AddMsg( LId, 7, 'Unable to create file ' );
 AddMsg( LId, 8, 'Unable to open file ' );
 AddMsg( LId, 9, 'FILE SIZE DOES NOT MATCH FLASH ROM CHIP SIZE. PROCEED [Y,N]?' );
 AddMsg( Lid, 10, 'WARNING: ABOUT TO ALTER THE BOOT BLOCK. PROCEED [Y,N]?' );
 AddMsg( Lid, 11, 'ERROR' );
 AddMsg( Lid, 12, 'SUCCESS' );
 AddMsg( Lid, 13, ' data file name: ' );
 AddMsg( Lid, 14, 'Invalid file size - must be exactly 4K !'#7 );
 AddMsg( Lid, 15, 'Do you want to proceed (Y/N)?' );
 AddMsg( Lid, 16, 'WARNING: YOU WILL LOSE ALL ' );
 AddMsg( Lid, 17, ' SETTINGS. PROCEED [Y,N]?' );
 AddMsg( Lid, 18, ' data file name: ' );
 AddMsg( Lid, 19, 'Bootblock file name: ' );
 AddMsg( Lid, 20, 'FLASH THE BACKUP BIOS IMAGE BACK INTO THE FLASH ROM [Y,N]?' );
 AddMsg( Lid, 21, '         WARNING: YOU WILL LOSE ALL BIOS SETTINGS. PROCEED [Y,N]?' );
 AddMsg( Lid, 22, 'CLEARED ' );
 AddMsg( Lid, 23, ' BYTES OF CMOS RAM.' );
 AddMsg( Lid, 24, 'ERROR CLEARING CMOS RAM - MAY BE (PARTIALLY) WRITE PROTECTED.'#7 );
 AddMsg( Lid, 25, '-REBOOT         Reboot after flashing (use together with -E)' ); {v1.28}
 AddMsg( Lid, 26, 'ERROR WRITING TO CMOS RAM - MAY BE (PARTIALLY) WRITE PROTECTED.'#7 );
 AddMsg( Lid, 27, 'RESTORE BACKUP CMOS DATA [Y,N]?' );
 AddMsg( Lid, 28, ' BYTES OF CMOS RAM WRITTEN.'#7 );
 AddMsg( Lid, 29, 'Missing file name with option -' );
 AddMsg( Lid, 30, '-H or -?        Shows this help screen' );
 AddMsg( Lid, 31, '-E fname        Flashes bios image from file fname to Flash' );
 AddMsg( Lid, 32, '                ROM without any user intervention' );
 AddMsg( Lid, 33, '-LOG            Enables auto-logging to UNIFLASH.LOG' ); {v1.23}
 AddMsg( Lid, 34, '-PCIROM         Flash ROM on a PCI card instead of system ROM' ); {v1.29}
 AddMsg( Lid, 35, '  [BUS DEV FUN] Manually specify PCI device (decimal numbers)' );
 AddMsg( Lid, 36, '-AMI            Use AMI Flash Interface' ); {v1.24}
 AddMsg( Lid, 37, 'Unable to access memory beyond 1Mb - try using HIMEM.SYS.' );
 AddMsg( Lid, 38, 'Sorry, but either you don''t have a 486+ or CPU is in V86 mode.' );
 AddMsg( Lid, 39, 'Select PCI card from list below:' ); {v1.29}
 AddMsg( Lid, 40, 'Bus ' );
 AddMsg( Lid, 41, ' device ' );
 AddMsg( Lid, 42, ' function ' );
 AddMsg( Lid, 43, '0. Quit' );
 AddMsg( Lid, 44, 'Select: 0' );
 AddMsg( Lid, 45, 'No PCI card with ROM found.' ); {v1.29}
 AddMsg( Lid, 46, 'Do you want to save this BIOS to a file? ' );
 AddMsg( Lid, 47, 'Name of the file: ' );
 AddMsg( Lid, 48, '            Done.' );
{ AddMsg( Lid, 49, 'Selected device''s option ROM is not a supported Flash ROM.' );}
 AddMsg( Lid, 50, 'Not enough free memory.' );
 AddMsg( Lid, 51, '              Flash ROM chip: ' );
 AddMsg( Lid, 52, 'UNKNOWN' );
 AddMsg( Lid, 53, '                Organisation: ' );
 AddMsg( Lid, 54, 'N/A (Is write protect disabled?)' ); {v1.23}
 AddMsg( Lid, 55, 'sectored: ' );
 AddMsg( Lid, 56, ' pages of ' );
 AddMsg( Lid, 57, ' bytes' );
 AddMsg( Lid, 58, 'bulk erase' );
 AddMsg( Lid, 59, ' sectors of ' );
 AddMsg( Lid, 60, 'Unknown flash chip !' );
 AddMsg( Lid, 61, '                 PCI chipset: ' );
 AddMsg( Lid, 62, '           Last write status: ' );
 AddMsg( Lid, 63, 'not available' );
 AddMsg( Lid, 64, 'Unable to read file!'#7 ); {v1.28}
 AddMsg( Lid, 65, 'Unable to write file!'#7 ); {v1.28}
 AddMsg( Lid, 66, '           Selected PCI card: ' ); {v1.29}
(* AddMsg( Lid, 66, ', Device=' );
 AddMsg( Lid, 67, ' at ' ); *)
 AddMsg( Lid, 68, 'Memory: ' );
 AddMsg( Lid, 69, 'ROM base: ' );
 AddMsg( Lid, 70, ', memory dump at ' );
{ AddMsg( Lid, 71, '              Option ROM for: ' );}
 AddMsg( Lid, 72, 'device at ' );
 AddMsg( Lid, 73, 'Write ESCD (PnP data) to file' );
 AddMsg( Lid, 74, 'Flash ESCD (PnP data) image to Flash ROM' );
 AddMsg( Lid, 75, 'Clear ESCD (PnP data)' );
{ AddMsg( Lid, 76, 'Write DMI data to file' );
 AddMsg( Lid, 77, 'Flash DMI data image to Flash ROM' );
 AddMsg( Lid, 78, 'Clear DMI data' );}
 AddMsg( Lid, 79, '® Back to main menu' );
 AddMsg( Lid, 80, 'Save CMOS data to file' );
 AddMsg( Lid, 81, 'Restore CMOS data from file' );
 AddMsg( Lid, 82, 'Flash BIOS image INCLUDING bootblock' );
 AddMsg( Lid, 83, 'Write boot block to file' );
 AddMsg( Lid, 84, 'Flash bootblock to Flash ROM' );
 AddMsg( Lid, 85, 'Write backup BIOS image to file' );
 AddMsg( Lid, 86, 'Flash BIOS image file to Flash ROM' );
 AddMsg( Lid, 87, 'Flash backup BIOS image to Flash ROM' );
 AddMsg( Lid, 88, 'Clear CMOS data' );
 AddMsg( Lid, 89, 'Restore backup CMOS data' );
 AddMsg( Lid, 90, 'ESCD (PnP) submenu ¯' );
 AddMsg( Lid, 91, 'ADVANCED submenu ¯' );
 AddMsg( Lid, 92, '-BASE option must be followed by at least 5 hex digits' );
{ AddMsg( Lid, 92, 'Additional BIOS info' );}
 AddMsg( Lid, 93, 'Quit' );
 AddMsg( Lid, 94, 'LAST FLASH WRITE WAS UNSUCCESFULL. QUIT ANYHOW [Y/N]?'#7 );
 AddMsg( Lid, 95, ' !'#7 );  {Last part of msg 7 & 8 !!!!}
 AddMsg( Lid, 96, 'Invalid file size - must be exactly 8K !'#7 );
 AddMsg( Lid, 97, '' ); {->18}
 AddMsg( Lid, 98, 'Invalid file size - must be exactly ' );
 AddMsg( Lid, 99, ' bytes !'#7 );
 AddMsg( Lid, 100, 'Redetect Flash ROM' ); {v1.23}
 AddMsg( Lid, 101, 'CMOS submenu ¯' ); {v1.23}
{ AddMsg( Lid, 100, 'BIOS Mfg: ' );
 AddMsg( Lid, 101, '   BIOS Model: ' );
 AddMsg( Lid, 102, '  Part number: ' );
 AddMsg( Lid, 103, '    Id string: ' );
 AddMsg( Lid, 104, 'Mfg id string: ' );}
 AddMsg( Lid, 105, 'YN' );   {Yes No}
 AddMsg( Lid, 106, '-FORCE option must be followed by 4 hex digits' );
 AddMsg( Lid, 107, '-CHIPLIST       Show list of supported flash chips with their numbers' );
 AddMsg( Lid, 108, '-FORCE xxxx     Force using routines for chip xxxx (4 hex digits)' );
 AddMsg( Lid, 109, '-SAVE fname     Write current bios image to file fname' );
 AddMsg( Lid, 110, 'This program can''t be run under Windows.' ); {v1.22}
 AddMsg( Lid, 111, 'PCI bus not found or not responding.' ); {v1.22}
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
 AddMsg( Lid, 135, '-PCIROM must have either zero or three parameters (BUS, DEV, FUN)'); {v1.27}
 AddMsg( Lid, 136, '-REPAIR         Repair erased chip ID (Winbond and SST chips)'); {v1.28}
 AddMsg( Lid, 137, '-REPAIR must be preceded by -FORCE parameter with correct ID'); {v1.28}
 AddMsg( Lid, 138, 'Only Winbond and SST chips can be repaired'); {v1.28}
End.