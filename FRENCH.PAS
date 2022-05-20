Unit French;

Interface

Implementation

Uses Language;

{$F+}
procedure InitFrench;
begin
 AddMsg(1, 'En train d''effacer' );
 AddMsg(2, 'En train d''‚crire' );
 AddMsg(3, 'V‚rification des donn‚es' );
 AddMsg(4, '         ERREUR DE VERIFICATION DE DONNEES DU CIRCUIT FLASH. REESSAYER [O/N]?' );
 AddMsg(5, '         ATTENTION: LES BOOTBLOCKs SONT DIFFERENTS !! CONTINUER [O,N]?' );
 AddMsg(6, 'Nom du fichier-image: ' );
 AddMsg(7, 'Cr‚ation du fichier ' );
 AddMsg(8, 'Ouverture du fichier ' );
 AddMsg(9, 'LA TAILLE DU FICHIER EST DIFFERENTE DE CELLE DU CIRCUIT FLASH ROM. CONTINUER [O,N]?' );
 AddMsg(10, 'ATTENTION: LE BOOTBLOCK SERA MODIFIE. CONTINUER [O,N]?' );
 AddMsg(11, 'ERREUR' );
 AddMsg(12, 'REUSSITE' );
 AddMsg(13, 'Nom du fichier de donn‚es ' );
{ AddMsg(14, 'Mauvaise taille du fichier - doit ˆtre de 4Ko exactement !'#7 );}
 AddMsg(15, 'Voulez vous continuer ([O]ui/[N]on)? ' );
{ AddMsg(16, 'ATTENTION: VOUS ALLEZ PERDRE TOUS LES PARAMETRES ' );
 AddMsg(17, '. CONTINUER [O,N]?' );}
 AddMsg(18, ' : ' ); {->97}
 AddMsg(19, 'Nom du fichier bootblock: ' );
 AddMsg(20, 'REENREGISTRER LE BIOS DE SAUVEGARDE DANS LA FLASH ROM [O,N]?' );
 AddMsg(21, '   ATTENTION: TOUS LES PARAMETRES DU BIOS SERONT PERDUS. CONTINUER [O,N]?' );
 AddMsg(22, '' );  {-> 23}
 AddMsg(23, ' OCTETS DE LA CMOS RAM EFFACES.' );
 AddMsg(24, 'ERREUR D''EFFACEMENT DES DONNEES CMOS - POSSIBILITE DE PROTECTION EN ECRITURE.'#7 );
 AddMsg(25, '-REBOOT         Reboot after flashing (use together with -E)' ); {v1.28}
 AddMsg(26, 'ERREUR D''ECRITURE DES DONNEES CMOS - POSSIBILITE DE PROTECTION EN ECRITURE.'#7 );
 AddMsg(27, 'REENGREGISTRER LES DONNEES CMOS PRECEDENTES [O,N]?' );
 AddMsg(28, ' OCTETS DE LA CMOS RAM ECRITS.'#7 );
 AddMsg(29, 'Nom de fichier manquant avec option -' );
 AddMsg(30, '-H or -?        Affiche cet ‚cran d''aide' );
 AddMsg(31, '-E fname        Ecrit le bios du fichier fname dans la FLASH ROM' );
 AddMsg(32, '                sans intervention de la part de l''utilisateur' );
 AddMsg(33, '-LOG            Enables auto-logging to UNIFLASH.LOG' ); {v1.23}
 AddMsg(34, '-PCIROM         Utilise la FLASH ROM d''une carte PCI' );
 AddMsg(35, '  [BUS DEV FUN] Manually specify PCI device (decimal numbers)' );
 AddMsg(36, '-AMI            Forcer UniFlash … utiliser l''interface FLASH de AMI' );
 AddMsg(37, 'Impossible d''acc‚der … la m‚moire au-del… de 1Mo - utilisez HIMEM.SYS.' );
 AddMsg(38, 'Le processeur n''est pas un 486+ ou le processeur est en mode virtuel' );
 AddMsg(39, 'S‚lectionnez une carte PCI dans cette liste:' );
 AddMsg(40, 'Bus ' );
 AddMsg(41, ' p‚riph‚rique ' );
 AddMsg(42, ' fonction ' );
 AddMsg(43, '0. Quitter' );
 AddMsg(44, 'Votre choix: 0' );
 AddMsg(45, 'Pas de carte PCI avec circuit (Flash) ROM d‚tect‚e.' );
 AddMsg(46, 'Voulez-vous sauvegarder ce BIOS dans un fichier? ' );
 AddMsg(47, 'Nom du fichier: ' );
 AddMsg(48, '            Fait.' );
 AddMsg(49, 'BOOTBLOCK MISMATCH. FLASH INCLUDING BOOTBLOCK (HIGHLY RECOMMENDED) [Y,N]?' ); {v1.30}
 AddMsg(50, 'Pas assez de m‚moire libre.' );
 AddMsg(51, '           Circuit Flash ROM: ' );
 AddMsg(52, 'INCONNU' );
 AddMsg(53, '                Organisation: ' );
 AddMsg(54, 'N/A (Is write protect disabled?)' ); {v1.23}
 AddMsg(55, 'secteurs: ' );
 AddMsg(56, ' pages de ' );
 AddMsg(57, ' octets' );
 AddMsg(58, 'bulk erase' );
 AddMsg(59, ' secteurs de ' );
 AddMsg(60, 'Circuit Flash inconnu !' );
 AddMsg(61, '            Jeu de puces PCI: ' );
 AddMsg(62, 'Etat de la derniŠre ‚criture: ' );
 AddMsg(63, 'pas disponible' );
 AddMsg(64, 'Unable to read file!'#7 ); {v1.28}
 AddMsg(65, 'Unable to write file!'#7 ); {v1.28}
 AddMsg(66, '           Selected PCI card: ' ); {v1.29}
(* AddMsg(66, ', P‚riph‚rique=' );
 AddMsg(67, ' … ' ); *)
 AddMsg(68, 'M‚moire: ' );
 AddMsg(69, 'Addresse de base de la ROM: ' );
 AddMsg(70, ', memory dump at ' );
 AddMsg(71, '              Option ROM for: ' );
 AddMsg(72, 'device at ' );
{ AddMsg(73, 'Sauvegarder l''ESCD (donn‚es PnP)' );
 AddMsg(74, 'Flasher l''ESCD (donn‚es PnP)' );
 AddMsg(75, 'Effacer ESCD (donn‚es PnP)' );
 AddMsg(76, 'Sauvegarder les donn‚es DMI' );
 AddMsg(77, 'Flasher les donn‚es DMI' );
 AddMsg(78, 'Effacer les donn‚es DMI' );}
 AddMsg(79, 'Revenir au menu principal' );
 AddMsg(80, 'Sauvegarder les donn‚es CMOS' );
 AddMsg(81, 'Restaurer les donn‚es CMOS' );
 AddMsg(82, 'Flasher le BIOS AVEC le bootblock' );
 AddMsg(83, 'Sauvegarder le bootblock' );
 AddMsg(84, 'Flasher le bootblock' );
 AddMsg(85, 'Sauvegarder le BIOS sur le disque' );
 AddMsg(86, 'Flasher le BIOS' );
 AddMsg(87, 'Flasher le BIOS pr‚cedent' );
 AddMsg(88, 'Effacer les donn‚es CMOS' );
 AddMsg(89, 'R‚‚crire les pr‚c‚dentes donn‚es CMOS' );
{ AddMsg(90, 'Menu ESCD (PnP)' );}
 AddMsg(91, 'Menu avanc‚' );
{ AddMsg(92, 'Informations BIOS suppl‚mentaires' );}
 AddMsg(93, 'Quitter' );
 AddMsg(94, 'LA DERNIERE ECRITURE A ECHOUE. QUITTER QUAND MEME [O/N]?'#7 );
 AddMsg(95, ' impossible !'#7 ); {Last part of msg 7 & 8 !!}
 AddMsg(96, 'Taille du fichier invalide - doit ˆtre de 8Ko exactement !'#7 );
 AddMsg(97, 'Nom de fichier de donn‚es ' );
 AddMsg(98, 'Taille du fichier incorrecte - doit ˆtre de ' );
 AddMsg(99, ' octets exactement!'#7 );
 AddMsg(100, 'Redetect Flash ROM' ); {v1.23}
 AddMsg(101, 'CMOS submenu ¯' ); {v1.23}
{ AddMsg(100, '  Fabriquant du BIOS: ' );
 AddMsg(101, '           ModŠle du BIOS: ' );
 AddMsg(102, '          Num‚ro de s‚rie: ' );
 AddMsg(103, '  ChaŒne d''identification: ' );
 AddMsg(104, 'ChaŒne d''id du fabriquant: ' );}
 AddMsg(105, 'ON' ); {Oui Non}
 AddMsg(106, '-FORCE option must be followed by 4 hex digits' );
 AddMsg(107, '-CHIPLIST       Show list of supported flash chips' );
 AddMsg(108, '-FORCE xxxx     Force using routines for chip xxxx (4 hex digits)' );
 AddMsg(109, '-SAVE fname     Write current bios image to file fname' );
 AddMsg(110, 'This program can''t be run under Windows.' ); {v1.22}
 AddMsg(111, 'PCI bus not found or not responding.' ); {v1.22}
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
 RegisterLanguage('Fran‡ais',InitFrench);
End.