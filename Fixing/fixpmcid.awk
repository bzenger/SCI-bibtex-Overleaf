# A program to pull PMCIDs from entries and then create new 
# entries for addition to individual bib files.
# To match the SCI standard
# We assume that
# a) the prefix will be derived from the last authors last name
# b) the file has been through bibclean and that "" are the 
#    marking for fields in the file
# c) there is at last one blank link between entries in the file
# To execute:
# awk -v outfile=filename -f fixpmcid.awk 
#  where filename is the name of the output filename
# When done, execute a sort-bibtex-entries command in emacs to 
#  get everything ordered properly
######################################################################
#
BEGIN{
    i=0; 
    numconverted = 0;
    if ( length(outfile) < 1 ) {
	outfile = "output.bib"; 
    }
    lastkey="";
    repsuffix[1] = "a";
    repsuffix[2] = "b";
    repsuffix[3] = "c";
    repsuffix[4] = "d";
    repsuffix[5] = "e";
}
/@/ {
  line1 = $0;
  line = $0;
  numlines = 0;
  qpmcid = 0;
  while ( length($0) > 1 ) {
      numlines = numlines + 1;
      thelines[numlines] = line;
      bigline = bigline " " $0;
      getline;
      line = $0;
  }
#  printf(" The full entry is %s\n", bigline);
#  printf("the first  lines are: %s\n%s\n%s\n%s\n",
#	 thelines[1], thelines[2], thelines[3], thelines[4]);
  for (linenum=1; linenum <= numlines; linenum++) {

# Scan for the first line and find the record type
      if ( linenum == 1 ) {
	  cnum = index(thelines[1], "{");
	  bibtype = substr(thelines[1], 1, cnum);
	  if ( length(substr(thelines[1],cnum+1)) > 1 ){
	      oldkey = substr(thelines[1],cnum+1);
	      gsub(/\,/, "", oldkey);
	  } else {
	      oldkey = "";
	  }
#	  printf("cnum = %d and bibtype is %s\n", cnum, bibtype);
#	  printf("oldkey = %s\n", oldkey);

# Now find the first author's last name and the last author's last name
      } else if ( index(tolower(thelines[linenum]), "author") > 0 ) {
#	  cnum = index(thelines[linenum], "\"");
#	  firstauth = substr(thelines[linenum], cnum+1, 3);
	  nameline = substr(thelines[linenum], 1);
	  gsub(/\"/, "", nameline);
#	  printf("name line is %s\n", nameline);
	  numnames = split(nameline,thenames," ");
	  if ( index(thenames[4],".") || length(thenames[4]) < 2 ) {
	      if ( index(thenames[5],".") || length(thenames[5]) < 2 ) {
		  if ( index(thenames[6],".") || length(thenames[6]) < 2 ) {
		      firstauth = FindAuth(thenames[7]);
		  } else {
		      firstauth = FindAuth(thenames[6]);
		  }
	      } else {
		  firstauth = FindAuth(thenames[5]);
	      }
	  } else {
	      firstauth = FindAuth(thenames[4]);
	  }
	  if ( index(firstauth,",") > 0 ) {
	      cnum = index(firstauth,",");
	      firstauth = substr(firstauth,1,cnum-1);
	  } else if ( length(firstauth) < 3 ) {
	      firstauth = substr(firstauth,1,length(firstauth));
	  }

	  lineinc = 0;
	  while ( match(thelines[linenum+lineinc],",") < 1 ) {
	      lineinc++;
	  }
	  numlastnames=split(thelines[linenum+lineinc], lastnames);
#	  printf("The last line of names is %s\n", thelines[linenum+lineinc]);
#	  printf("The last name is %s\n", lastnames[numlastnames]);
	  theprefix = FindPrefix(lastnames[numlastnames]);

# Find the year
      } else if ( index(tolower(thelines[linenum]), "year") > 0 ) {
	  split(thelines[linenum], theyears);
#	  cnum = index(thelines[linenum], "\"");
#	  theyear = substr(thelines[linenum], cnum+1, 4);
	  theyear = FindYear(theyears[3]);
#	  printf(" yearstring is %s from %s\n", 
#		 yearstring, thelines[linenum])

# Now report if a PMCID is found
      } else if ( index(tolower(thelines[linenum]), "pmcid") > 0 ) {
	  split(thelines[linenum], thepmcids);
#	  cnum = index(thelines[linenum], "\"");
#	  theyear = substr(thelines[linenum], cnum+1, 4);
	  thepmcid = FindPMCID(thepmcids[3]);
#	  printf(" pmcid is %s from %s \n", 
#		 thepmcid, thelines[linenum])
	  qpmcid = 1
      }
  }

# The key for the bibtex entry
  key = prefix ":" firstauth yearstring;
  if ( key == lastkey ) {
      repcount = repcount + 1;
      key = key repsuffix[repcount];
      printf(" Found double for key = %s so set to %s\n", lastkey, key);
  } else {
      repcount = 0;
      lastkey = key;
  }
  printf(" Key: %s\n", key);

# Now create the Bibtex entry

  firstnum = 2;
  if ( qpmcid ) {
      printf("%s%s,\n", bibtype, key ) > outfile; 
      for (linenum=firstnum; linenum <= numlines; linenum++) {
	  if ( match (tolower(thelines[linenum]),"url = ") == 0 ){
	      printf("%s\n", Packentry(thelines[linenum]))  > outfile;
	  }
      }
      if ( length(oldkey) > 1) {
	  printf("  oldkey =       \"%s\",\n", oldkey) > outfile;
      }
      printf("}\n") > outfile;
      printf("\n") > outfile;
      
      numconverted = numconverted + 1;
  }
}
END{
    printf("Converted %d entries\n", numconverted);
}
######################################################################
function Packentry( entryin ) {

# Clean up and pack an entry, get rid of funky characters or make the 
# proper LaTeX special characters

 #   gsub(/\|/, " ", entryin );
#    gsub(/  /, " ", entryin );
    #  gsub(/\"/, "", entryin );
#    gsub(/%/, "\\%", entryin); 
#    gsub(/\$/, "\\\$", entryin); 
#    gsub(/\#/, "\\\#", entryin); 
    return entryin;
}

function FindAuth( authname ) {

# Get rid of junk in author name and find first three letters

    gsub(/-/, "", authname);
    gsub(/{/, "", authname);
    gsub(/}/, "", authname);
    gsub(/'/, "", authname);
    gsub(/\"/, "", authname);
    gsub(/\\/, "", authname);
    shortname = substr(authname, 1, 3);
    return shortname;
}

function FindYear(  yearname ) {

# Fish out the year from the string

    gsub(/{/, "", yearname);
    gsub(/}/, "", yearname);
    gsub(/'/, "", yearname);
    gsub(/\"/, "", yearname);
    gsub(/\\/, "", yearname);
    theyear = substr(yearname,1,4);
# Adjust for Y2K
    if ( theyear < 2000 ) {
	yearstring = substr(theyear,3,2);
    } else {
	yearstring = theyear;
    }
    return yearstring;
}

function FindPMCID(  pmcidstring ) {

# Fish out the year from the string

    gsub(/{/, "", pmcidstring);
    gsub(/}/, "", pmcidstring);
    gsub(/'/, "", pmcidstring);
    gsub(/\"/, "", pmcidstring);
    gsub(/\\/, "", pmcidstring);
    thepmcid = substr(pmcidstring,1,10);
    return pmcidstring;
}


function FindPrefix(  lastname ) {

# Look up prefix based on the last name string

#    printf("Testing %s  ",lastname);
    if( match(lastname,"MacLeod")) {
	prefix = "RSM"
    } else if (match(tolower(lastname),"marrouche")) {
	prefix = "RSM";
    } else if (match(tolower(lastname),"trayanova")) {
	prefix = "RSM";
    } else if (match(tolower(lastname),"whitaker")) {
	prefix = "RTW";
    } else if (match(tolower(lastname),"johnson")) {
	prefix = "CRJ";
    } else if (match(tolower(lastname),"hansen")) {
	prefix = "CDH";
    } else if (match(tolower(lastname),"fletcher")) {
	prefix = "TJF";
    } else if (match(tolower(lastname),"brooks")) {
	prefix = "DHB";
    } else { 
	prefix = "UNK";
    }
#    printf("REturning prefix value of %s\n", prefix);
    return prefix;
}
