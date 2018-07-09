#!/bin/bash

# xquest_prepare - a script to prepare and start xquest/xprophet runs.

# This script can download and install the xQuest/xProphet 2.1.1 pipeline and its
# dependencies (Apache 2, Perl libraries, etc.) and prepare the necessary
# directory structure.

# Runs on Ubuntu 18.04 LTS.

##### FUNCTIONS #####

function download {
  # Downloading xQuest/xProphet
  printf "Downloading xQuest/xProphet... "
  cd $HOME/xquest
  wget -q --user=xquest --password=xprophet http://proteomics.ethz.ch/xquest2_www//downloads/V2_1_1.tar > /dev/null
  printf "Done.\n\n"

  # Extracting the archive
  printf "Extracting tar... "
  tar -xf V2_1_1.tar > /dev/null
  rm V2_1_1.tar
  printf "Done.\n\n"

  # Installing dependencies
  printf "Installing dependencies...\nThe script will ask you your password to run apt-get, install dos2unix and run cpan.
For the latter, please use the default configuration.\n"
  cd V2_1_1/xquest/installation
  chmod 755 install_packages.sh
  # ./install_packages.sh
  printf "Done.\n\n"

  # Installing xQuest/xProphet
  printf "Installing xQuest/xProphet...\n"
  sed '1s/.*/INSTALLDIR=$HOME\/xquest\/V2_1_1\/xquest/' install_xquest.sh > install_xquest_new.sh
  mv install_xquest.sh install_xquest.sh.bak
  mv install_xquest_new.sh install_xquest.sh
  # ./install_xquest.sh
  cp $HOME/.bashrc $HOME/.bashrc.bak
  # echo "# Add xQuest bin to PATH" >> $HOME/.bashrc
  # echo "export PATH=$PATH:$HOME/xquest/V2_1_1/xquest/bin" >> $HOME/.bashrc
  printf "Done.\n\n"

  # Configuring Apache 2
  printf "Configuring the Apache 2 web server...\nThe script will ask you your password.\n"
  sudo chmod -R 777 $HOME/xquest/results
  # apache2.conf
  sudo cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bak
  sudo echo "ServerName localhost" >> /etc/apache2/apache2.conf
  sudo echo "ScriptAlias /cgi-bin/ /var/www/cgi-bin/" >> /etc/apache2/apache2.conf
  sudo echo "Options +ExecCGI" >> /etc/apache2/apache2.conf
  sudo echo "AddHandler cgi-script .cgi .pl .py" >> /etc/apache2/apache2.conf
  # serve-cgi-bin.conf
  sudo cp /etc/apache2/conf-available/serve-cgi-bin.conf /etc/apache2/conf-available/serve-cgi-bin.conf.bak
  sudo sed -i '/\/usr\/lib\//\/var\/www\/' /etc/apache2/conf-available/serve-cgi-bin.conf
  sudo sed -i '/Require all granted/d' /etc/apache2/conf-available/serve-cgi-bin.conf
  sudo sed -i '/Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch/Options +ExecCGI' /etc/apache2/conf-available/serve-cgi-bin.conf
  # 000-default.conf
  sudo cp /etc/apache2/conf-available/000-default.conf /etc/apache2/conf-available/000-default.conf.bak
  sudo sed -i '/DocumentRoot \/var\/www\/html\//DocumentRoot \/var\/www\/' /etc/apache2/conf-available/000-default.conf
  # Enabling CGI module
  sudo a2enmod cgi
  # Creating cgi-bin folder and symlinks
  sudo mkdir /var/www/cgi-bin/
  sudo ln -s $HOME/xquest/V2_1_1/xquest/cgi/ /var/www/cgi-bin/xquest-cgi/
  sudo ln -s $HOME/xquest/results/ /var/www/results/
  # Restarting Apache 2 server
  sudo service apache2 restart
  printf "Done.\n\n"

}

function usage {
  printf "AUTHOR: Samuel Diebolt\n\n"

  printf "INFORMATION: This script downloads and installs the xQuest/xProphet
pipeline and its dependencies (Apache 2, Perl libraries, etc.)
and prepares the necessary directory structure in $HOME/xquest.\n\n"

  printf "USAGE: xquest_prepare -option [parameter]\n\n"

  printf "OPTIONS: Values in [] are the default values that are used if
the option is not provided.\n\n"
  printf -- "\t-i | --interactive: run in interactive mode.\n\n"
  printf -- "\t-D | --download: download and install xQuest/xProphet and its
        dependencies.\n\n"
  printf -- "\t-d | --directory [run]: analysis directory name.
        e.g.: $HOME/xquest/analysis/run.\n\n"
  printf -- "\t-m | --mzxml [./]: path to the mzXML files, including ending '/' e.g.
        /path/to/mzxmls/.\n\n"
  printf -- "\t-f | --fasta [./my_db.fasta]: path to the FASTA database, e.g.
        /path/to/fasta/my_db.fasta.\n\n"
  printf -- "\t-s | --start: run xQuest/xProphet after preparations are done.
        Options xmlmode and pseudosh are used for xQuest.\n\n"
  printf -- "\t-h | --help: prints this help.\n\n"

  printf "EXAMPLE: xquest_prepare -l files -p /path/to/mzxmls/.\n"
}

##### MAIN #####

interactive=
dl=
xquest=
xprophet=
directory="run"
mzxml="./"
fasta="./"


# The script should not be run as root
if [ "$EUID" = 0 ]
  then echo "Please do not this script run as root."
  exit
fi

# Command line options
while [ "$1" != "" ]; do
  case $1 in
    -i | --interactive)   interactive=1
                          ;;
    -D | --download)      dl=1
                          ;;
    -d | --directory)     shift
                          directory=$1
                          ;;
    -m | --mzxml)         shift
                          mzxml=$1
                          ;;
    -f | --fasta)         shift
                          fasta=$1
                          ;;
    -x | --xquest)        xquest=1
                          ;;
    -p | --xprophet)      xprophet=1
                          ;;
    -h | --help)          usage
                          exit
                          ;;
    *)                    usage
                          exit 1
  esac
  shift
done

if [ "$interactive" = "1" ]; then
  printf "Interactive mode is on.\n\n"
else
  printf "Interactive mode is off.\n\n"
fi

mkdir -p $HOME/xquest/{results,analysis/$directory/{mzxml,db}}

# Download and install xQuest/xProphet and its dependencies
if [ "$dl" = "1" ]; then
  download
fi

# Move the mzxml and fasta files to the analysis directory, create definition files
# and reverse database
printf "Copying mzxml and fasta files to $HOME/xquest/analysis/$directory/... "
cd $HOME/xquest/analysis/$directory/
cp $mzxml/*.mzxml mzxml/
cp $fasta db/database.fasta
xdecoy.pl -db db/database.fasta > /dev/null
runXquest.pl -getdef > /dev/null
printf "Done.\n\n"

# Configuring definition files
read -p "You will now configure xquest.def. Press enter to continue.\n"
nano xquest.def
read -p "You will now configure xmm.def. Press enter to continue.\n"
nano xmm.def

# Starting the search
if [ "$xquest" = "1" ]; then
  printf "Configuring the search...\n\n"
  ls mzxml/ | sed 's/\(.*\)\..*/\1/' > files
  pQuest.pl -list files -path $HOME/xquest/analysis/$directory/mzxml/
  printf "Done.\n\n"
  printf "Running the search...\n\n"
  runXquest.pl -list files -xmlmode -pseudosh
  printf "Done.\n\n"

  # Merging result files
  printf "Merging result files... "
  resultfolder=$HOME/xquest/analysis/$directory/results$directory
  mergexml.pl -list resultdirectories_fullpath -resdir $resultfolder > /dev/null
  printf "Done.\n\n"

  # Annotate search results
  printf "Annotating search results... "
  cd $resultfolder
  annotatexml.pl -xmlfile merged_xquest.xml -out annotated_xquest.xml -native> /dev/null
  printf "Done.\n\n"

  if [ "$xprophet" = "1"]; then
    # Configuring xProphet analysis
    printf "Configuring xProphet analysis...\n"
    xprophet.pl > /dev/null
    read -p "You will now configure xproph.def. Press enter to continue.\n"
    nano xproph.def
    printf "Done.\n\n"

    # Starting xProphet analysis
    printf "Running xProphet... "
    xprophet.pl -in annotated_xquest.xml -out xquest.xml > /dev/null
    printf "Done.\n\n"
  else
    mv annotated_xquest xquest.xml
  fi

  # Copying results to the results folder for the web server
  printf "Copying results to the web server...\nThe script will ask your password to give the correct permissions to Apache 2.\n"
  cp -R $resultfolder $HOME/xquest/results
  sudo chmod -R 777 $HOME/xquest/results/results$directory
  printf "Done.\n\n"

  # Displaying the result manager
  printf "Display the result manager.\n"
  firefox localhost/cgi-bin/xquest-cgi/resultsmanager.cgi
fi
