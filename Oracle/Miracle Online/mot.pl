#!perl
#******************************************************************************
#** Prog name   : mot, Miracle Online Tool 
#** Function    : Various  
#** Input       : Command line options, see usage sub function for more
#**             :
#** Comments    :
#** History	    : 20090206, Miracle/HMH, version 0.1.0.14
#**             :           Initial version released for beta test
#******************************************************************************
#
# Current version var for use in sub function "printversion"
$currentversion="Release 1.0";

use Time::Local;
use Getopt::Std;
use Getopt::Long;
use Sys::Hostname;

%filelist = ();
@fileindex = ();
@exceptions = ();

# Reset debugo indents
$debugo_indent = 0;

#******************************************************************************
#** Sub name 	: debugo 
#** Function	: Prints debug information to screen if $debug_print = "yes"
#** Input	    : text to be printed
#** Output	    : output to screnn
#** Comments	: control undent by inc/dec the global var $debugo_indent++/--
#**             :
#** History	    : 20090206, Miracle/HMH	 Created 
#******************************************************************************
sub debugo (@) {
	$space="";
	$loop_idx = $debugo_indent;
	while ( $loop_idx > 0 ) {
		$space=$space." ";
		$loop_idx--;
	}
	if ( $debug_print =~ /^yes$/i ) {
		for (@_) { print $space.$_ };
	} 
}

#******************************************************************************
#** Sub name    : printversion 
#** Function    : Prints version and copyrights info
#** Input       : None
#** Output      : Print output to screen
#** Comments    :
#** History	    : 20090206, Miracle/HMH   Created
#******************************************************************************
sub printversion {
	print "\nMiracle Online Tool: $currentversion on " . localtime () . "\n\n";
}


#******************************************************************************
#** Sub name    : usage 
#** Function    : Prints usage info
#** Input       : None
#** Output      : Prints info to the screen
#** Comments    :
#** History	    : 20090206, Miracle/HMH	 Created 
#**             : 20090223, Miracle/HMH  Change of layout.
#******************************************************************************
sub usage {	
	print "\n";
	print "Sorry this program dosn't run without parameters, so please apply some :o)\n\n";
	print "Usage ...\n\n";
	print "mot: <command> <options>\n\n";
	print "Commands:\n";
	print "--scanlog <file>        : Scan a logfile.\n";
	print "--scan <directory>      : Scan a log directory.\n";
	print "--tail <filename>       : Tail the file <filename>\n";
	print "Options:\n";	
	print "--except <exceptions>   : Add exceptions to default exceptions, comma separated (ORA-01234,\"job 2384\",\[kgsbuf+002\], ...)\n";
	print "--noexcept              : Disable all exceptions.\n";
	print "--filemask <file>       : Filemask for use with scanning directory\n";
	print "--older                 : Used in conjunction with --scan to define whether files should be older than n days.\n";
	print "--newer                 : Used in conjunction with --scan to define whether files should be newer than n days.\n";
	print "--match                 : Add more matching to --scan, comma separated (htp-500,OC4J, ...)\n";
    print "--nextline              : Write out next x lines when condition met - only option for --SCAN \n\n"; 
	print "\n";
	print "Examples:\n\n";
	print "Scanning a logfile:\n";
	print "mot --scanlog <file> --except <excetions,comma,seperated>\n\n";
	print "Scanning a directory:\n";
	print "mot --scan <directory> --filemask <filemask> --older/newer\n\n";
	print "Tailing a file:\n";
	print "mot --tail <file>\n\n";
}
	
#******************************************************************************
#** Sub name    : get_option 
#** Function    : Get command line argumnts and setting up runtime environment
#** Input       : Use Perl lib getopt::long
#** Output      : Setting global variables
#** Comments    : 
#** History	    : 20090206, Miracle/HMH	 Created 
#******************************************************************************
sub get_option {
	
	GetOptions(	"tail=s"		=> \$tailfile,
	           	"scan=s"		=> \$scandir,
        		"scanlog=s"		=> \$scanlog,
           		"except=s"		=> \$exceptions,
           		"noexcept!"  	=> \$noexceptions,
           		"help"			=> \$help,
           		"stats!"		=> \$statistics,
           		"filemask=s" 	=> \$filemask,
           		"newer=i"    	=> \$newer,
           		"older=i"    	=> \$older,
           		"match=s"    	=> \$match,
           		"debug=s"    	=> \$debugo,
                "nextlines=i"   => \$next
               		);
    
    if ( defined $debugo ) {
	    $debug_print = "yes";
    }                    
    
	unless ( $noexceptions )
	{
		@default_exceptions = (
			'ORA-00060'
		);   
		if ( defined $exceptions ) {
			print "There are some new exceptions\n";
			@exceptions = split ( ',', $exceptions);
			push (@exceptions, @default_exceptions);
			print join(', ', @exceptions) . "\n\n";
		}
		else {
			debugo "Setting exceptions\n";
	 		@exceptions = @default_exceptions;
			debugo join(', ', @exceptions) . "\n\n";
		}
	}
	
	# Checkout OS platform and decide directory delimiter
	if ( $^O eq "MSWin32" ) {   # Works under NT, XP, 2000 & 2003
		  debugo "Current environment is: " . $^O . "\n";
    	$os_type = "Windows";
    	$dir_del = "\\";
    }
	else {                                # Unix, Linux
		  debugo "Current environment is: " . $^O . "\n";
    	$os_type = "UNIX";
    	$dir_del = "/";
    }

    
	# Check for empty parameters
	$dobparam = 0;
	if ( defined $scanlog || defined $scandir || defined $tailfile ) {
		debugo "Checking parameters\n";
		if ( defined $scandir ) { 
			$scandir =~ tr|\\+|\/|; 
			unless ( defined $filemask ) {
				print "Missing parameter \"--filemask\"\n\n";
				usage;
				exit 1;
			}
		}
		else { 
			$dobparam = 1; 
		}
		if ( defined $scanlog ) {
			if ( $dobparam == 0 ) {
				$help = 1;
				debugo "Double parameter\n";
			}
			$scanlog =~ tr|\\+|\/|;
		}
		else {
			$dobparam = 1;
		}
		if ( defined $tailfile ) {
			if ( $dobparam == 0 ) {
				$help = 1;
				debugo "Double parameter\n";
			}
			$tailfile =~ tr|\\+|\/|;
		}
		else {
			$dobparam = 1;
		}
	}
	else {
		$help = 1;
	}		 
	
	# print usage if help is required
	if ( $help ) {
		usage;
		exit 0;
	}
}

#******************************************************************************
#** Sub name    : get_hash
#** Function    : Return a hash value for a given string.
#** Input       : String
#** Output      : Hash value
#** Comments    :
#** History	: 20090319, Miracle/HMH   Created
#******************************************************************************
sub get_hash {
	my $a = 63689;
	my $b = 378551;    	# Constant value
	my $i = 0;
	my $l = 0;		# Length of string
	my $r = 0;		# Result value

	my $string = "Dette er en string med karakterer ABCabc123!\"#";
	my @chars = split("", $string);
	
	foreach $char (@chars) {
		$r = $r * $a + ord($char);
		$a = $a + $b;
		print "Char is : " . $char . ", a is : ". $a . ", b is : " . $b . " and r is : " . $r . "\n";
	}
	return $r;
}

#******************************************************************************
#** Sub name    : createfilelist 
#** Function    : Creates a filelist for for scanning depending on inputs
#** Input       : $directory, $filemask & $newer or $older
#** Output      : $filelist & $fileindex
#** Comments    :
#** History	: 20090206, Miracle/HMH	 Created 
#**		: 20090602, Miracle/HMH Corrected a bug in targettime calculation
#******************************************************************************
sub createfilelist ($) {
	$directory = @_[0];
	$oneday = 86400;
	$lt = timelocal(localtime());
	$scanallfiles = 0;  # Do not scan all files
    
	if ( defined $newer ) {
		debugo "** newer is $newer\n";
		$targettime = $lt-($oneday*$newer);
	}
	elsif ( defined $older ) {
		debugo "** older is $older\n";
		$targettime = $lt-($oneday*$older);
	}
	else {
		$scanallfiles = 1;  # Scan all files
		$targettime = $lt;
	}
	debugo "Localtime is  :$lt\n";
	debugo "Targettime is :$targettime\n";
	debugo "Filemask is   :$filemask\n";
		
	opendir TARGETDIR, $directory or die "Can't open the directory. \n";
	$index = 0;
	foreach $entry (readdir(TARGETDIR)) {
		unless ( -d $entry ) {
			($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat("$directory/$entry");
			if ( $entry =~ /$filemask/ ) {
				debugo "newer is: $newer, older is: $older, mtime is: $mtime, targettime is: $targettime, targetfile: $entry\n";
				if (  $newer > 0 && $mtime > $targettime ) {
					debugo "** newer ****\n";
					$fileindex[$index++] = $mtime;
					$filelist{$mtime} = $entry;
				}
				elsif ( $older > 0 && $mtime < $targettime) {
					debugo "** older ****\n";
					$fileindex[$index++] = $mtime;  # Skal det være mtime ???????????????????????????????????????????
					$filelist{$mtime} = $entry;
				}
				elsif ( $scanallfiles > 0 ) {
					debugo "In else part\n";
					$fileindex[$index++] = $mtime;
					$filelist{$mtime} = $entry;
				}
			}
		}
	}
	
    @fileindex = sort @fileindex;
    debugo  join(' - ',@fileindex) . "\n";
}

#******************************************************************************
#** Sub name    : tailfile
#** Function    : Tailing the input file 
#** Input       : $file
#** Output      : Prints appends to file
#** Comments    : Currently the last 1000 characters are printed first
#** History	    : 20090206, Miracle/HMH	 Created 
#******************************************************************************
sub tailfile {
	$file = $tailfile;
	open FH, "<".$file or  "Can't read the file $file";
	seek(FH, -1000, 2);
	<FH>;
	for (;;) {
		while (<FH>) {
			print;
		}
		#sleep some time before reset og EOF flag
		select(undef,undef,undef, 0.25);
		seek(FH, 0, 1);
	}
}

#******************************************************************************
#** Sub name    : scanfile 
#** Function    :  
#** Input       :
#** Output      :
#** Comments    :
#** History	    : 20090206, Miracle/HMH	 Created 
#******************************************************************************
sub scanfile {	
	
	 @default_rules = (
	'\[critical\]',
	);
		        
	if ( defined $match ) {
		debugo "There are some new match\n";
		@rules = split ( ',', $match);
		push (@rules, @default_rules);
		debugo join(', ', @rules) . "\n\n";
	}
	else {
		debugo "Setting match\n";
	 	@rules = @default_rules;
		debugo join(', ', @rules) . "\n\n";
	}

	foreach $fi (@fileindex) {
		debugo "Fileindex is : $fi\n";
		$moreprint = 0;
		$file = $filelist{$fi}; 
		$logfile = $scandir.$dir_del.$file;
		print "\n** ** Now scanning logfile: $logfile ** **\n\n";
		open INFILE, "<".$logfile or die "Can't open the file $logfile\n";
		while (<INFILE>) {
			if ($moreprint > 0) {
			   #print "vi printer en next " . $moreprint . "\n";
			   print $_;
			   $moreprint = $moreprint -1;
			} else {
			foreach $rule (@rules) {
				if ( /$rule/ )  {
					$exceptionfound = 0;
					debugo "** Exceptionfound is: $exceptionfound\n";
					debugo "Matching pool is: " . join(', ', @exceptions) . "\n";
					foreach $exception (@exceptions) {
						debugo "** ** Current Exceptions is: $exception\n";
						if ( /$exception/ ) {
							debugo "\n******************** Exception Found ********************\n\n";
							$debugo_indent++;
							debugo $_;
							$debugo_indent--;
							$exceptionfound = 1;
							debugo $exceptionfound."\n";
							$doprint = 0;
					      }
			        }
			      unless ( $exceptionfound ) {	
				    print;
                    if ($next>0) {
                      $moreprint = $next;
                    }
				  }
				}
			}
			}
		}
		close INFILE;
	}
}

#******************************************************************************
#** Sub name    : scanlog
#** Function    :  
#** Input       :
#** Output      :
#** Comments    :
#** History	    : 20090206, Miracle/HMH	 Created 
#******************************************************************************
sub scanlog () {
	
	$file = $scanlog;
	
	my @times = (
	'^(\w{3}) (\w{3}) (\d{2}) (\d{2}:\d{2}:\d{2}) (\d{4})',
	);
	
	my @rules = (
	'^ORA-',
	'^TNS-',
	'^DIA-',
	'Error',
	'Warning',
	'Fatal',
	'Shutting down instance',
	'Starting ORACLE instance',
	'Instance shutdown complete'
	);
	
	my @rules_start_stop = (
	'Starting ORACLE instance',
	'Shutting down instance:',
	#'Instance shutdown complete'
	);

	$count = 1;
	$doprint = 1;
	$old_line ="et eller andet";
	
	# Running through the log
	
	$first = 1;
	
	#Filesize - i Kb
	my $filesize = -s "$file";
	my $filesize_k = sprintf '%.0f', $filesize / 1024; 
	
	open INFILE, "<".$file or die "Can't read the file $file";

	while (<INFILE>) {
		if (( /^(\w{3}) (\w{3})\s{1,2}(\d{1,2}) (\d{2}:\d{2}:\d{2}) (.+)$/ )) {
			$timestamp = "$1 $2 $3 $4 $5 $6\n";
			debugo "Extracted timestamp is ${timestamp}";
			if ($first) {
			    $first_timestamp = $timestamp;
			$first = 0;
		}
			$timetick = 1;
			if ( $count > 1 && $doprint ) {                # Has there been found anything then print
				#print  $timestamp;
				foreach $line (@lines) {
					print $line;
				}
				print "\n";
			}
			$#lines = -1;                  # Reset the @lines array
			$count=1;
			$lines[0] = $timestamp;
			$doprint=1;
		}
		else {
			foreach $rule (@rules) {
				if ( /$rule/ ) {
					$exceptionfound = 0;
					debugo "** Exceptionfound is: $exceptionfound\n";
					debugo "Matching pool is: " . join(', ', @exceptions) . "\n";
					foreach $exception (@exceptions) {
						debugo "** ** Current Exceptions is: $exception\n";
						if ( /$exception/ ) {
							debugo "\n******************** Exception Found ********************\n\n";
							$debugo_indent++;
							debugo $_;
							$debugo_indent--;
							$exceptionfound = 1;
							debugo $exceptionfound."\n";
							$doprint = 0;
						}
					}
					unless ( $exceptionfound ) {
						if ($old_line ne $_) {			#Vi printer kun den sammeline ud een gang, selvom den rammer flere søgekrits
							$lines[$count++] = " $_"; 
						}
						$exceptionfound = 0;
						$old_line = $_;
					}
				}
			}
		}
	}
	if ( $count > 1 ) {                # Print the last buffer if not empty
	    foreach $line (@lines) {
		    print $line;
		}
		print "\n";
	}
	close INFILE;
	
	####   Lav et summery af ORA- / TNS- fejl nederst
	
	sub byDescendingValues {
		$value = $dictionary{$b} <=> $dictionary{$a};
	#	if ($value == 0) { return 1;
	#	} else {
			return $a cmp $b;
	#	}
	}
	open INFILE, "<".$file or die "Can't read the file $file";

	while (<INFILE>) {
		chomp;
		@words = split(/ /);

		foreach $word (@words) {
			foreach $rule (@rules) {
				if ( $word =~ $rule ) {
					$dictionary{$word} += 1;  
				}
			}
		}
	}
	
	close INFILE;		
	
	## tæl shutdown/start af Oracle
	open INFILE, "<".$file or die "Can't read the file $file";

	while (<INFILE>) {
		foreach $rule (@rules_start_stop) {
				if ( /$rule/ ) {
				    $dictionary2{$rule} += 1;
				}
		}
	}
	
	close INFILE;
	
	### Print Summary delen 
	
	print "-----------------------------------------------------------------------------------------------\n";
	print "Scanlog of: $file\n";
	print "    - size: $filesize_k Kb\n";
	print "    - from: $first_timestamp";
	print "    -   to: $timestamp";
	print "\n";
	print "    - exceptions: @exceptions\n";
	print "-----------------------------------------------------------------------------------------------\n";
	print "\n";

	foreach $word ( sort byDescendingValues keys %dictionary) {
		print "$word $dictionary{$word}\n" ; 
		}
		
	print "\n";
	
	foreach $word ( sort byDescendingValues keys %dictionary2) {
		print "$word $dictionary2{$word}\n" ; 
		}

	print "\n";
	
}

#******************************************************************************************
# Mainprogram
#******************************************************************************************

printversion ;

get_option;

if ( $scanlog ) {
	scanlog;
}

if ( $scandir ) {
	createfilelist($scandir);
	scanfile;
}

if ( $tailfile ) {
	tailfile;
}
