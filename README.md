# Simple xQuest

This script can download and install the xQuest/xProphet 2.1.1 pipeline and its dependencies (Apache 2, Perl libraries, etc.) and prepare the necessary directory structure to ensure an easy use on an **Ubuntu 18.04** VM as well as on a native installation.

Thus, the installation and use of xQuest/xProphet is greatly simplified for command line beginners.

Currently, the -x (launching xQuest) and -p (launching xProphet) aurgments are unreliable and should not be used. Apache 2 configuration, directory structure creation and xQuest/xProphet installation should work fine.

## Prerequisites

This script runs on Ubuntu 18.04 LTS. All dependencies for xQuest/xProphet can be installed through the script.

Due to modifications to Apache 2 configuration files – backups are created –, it is recommended to use a fresh install or VM of **Ubuntu 18.04**.

### Installing

Clone the project, then
```
cd simple-xquest/
chmod 755 simple_xquest.sh
./simple_xquest.sh -h
```

## Authors

- **Samuel Diebolt** - <samuel.diebolt@espci.fr>

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
