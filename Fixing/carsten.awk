# A program to clean up end note output
#
BEGIN{
    i=0; 
    numconverted = 0;
    prefix = "CHW:"
}
/@/ {
  line1 = $0;
  line = $0;
  numlines = 0;
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
# MAke the new key line
      if ( linenum == 1 ) {
	  cnum = index(thelines[1], "{");
	  bibtype = substr(thelines[1], 1, cnum);
#	  printf("cnum = %d and bibtype is %s\n", cnum, bibtype);
# Now find the authors
      } else if ( index(tolower(thelines[linenum]), "author") > 0 ) {
	  cnum = index(thelines[linenum], "\"");
#	  firstauth = substr(thelines[linenum], cnum+1, 3);
	  nameline = substr(thelines[linenum], cnum+1, 40);
	  split(nameline,thenames," ");
	  firstauth = substr(thenames[2],1,3);
#	  printf("nameline = %s\n", nameline);
#	  printf("thenames are %s %s %s\n", thenames[1], thenames[2],thenames[3]);
	  if ( index(firstauth,",") > 0 ) {
	      cnum = index(firstauth,",");
	      firstauth = substr(firstauth,1,cnum-1);
	  } else if ( length(firstauth) < 3 ) {
	      firstauth = substr(firstauth,1,length(firstauth));
	  }
	  if (linenum == 2) {
	      qodd = 1 } 
	  else {
	      qodd = 0 }
		  
#	  printf("first author is %s from %s\n",
#		 firstauth, thelines[linenum]);
# Find the year
      } else if ( index(tolower(thelines[linenum]), "year") > 0 ) {
	  cnum = index(thelines[linenum], "\"");
	  theyear = substr(thelines[linenum], cnum+1, 4);
	  if ( theyear < 2000 ) {
	      yearstring = substr(theyear,3,2);
	  } else {
	      yearstring = theyear;
	  }
	  printf(" yearstring is %s from %s\n", 
		 yearstring, thelines[linenum])
      }
  }
# The key for the bibtex entry
  key = prefix firstauth yearstring;
  printf(" Key: %s\n", key);

# Now create the Bibtex entry

  outfile = "output.bib";
  printf("%s%s,\n", bibtype, key ) > outfile; 
  if ( qodd == 1 ) { 
      firstnum = 2; 
  } else {
      firstnum = 3;
  }
  for (linenum=firstnum; linenum <= numlines; linenum++) {
      
      printf("%s\n", Packentry(thelines[linenum]))  > outfile;
  }
  printf("}\n\n") > outfile;
  numconverted = numconverted + 1;
}
END{
    printf("Converted %d entries\n", numconverted);
}
######################################################################
function Packentry( entryin ) {

# Clean up and pack an entry, get rid of funky characters or make the 
# proper LaTeX special characters

  gsub(/\|/, " ", entryin );
  gsub(/  /, " ", entryin );
#  gsub(/\"/, "", entryin );
  gsub(/%/, "\\%", entryin); 
  gsub(/\$/, "\\\$", entryin); 
  gsub(/\#/, "\\\#", entryin); 
  return entryin;
}
