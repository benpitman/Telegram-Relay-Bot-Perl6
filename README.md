# Telegram Relay Bot

## --------------------- Dependencies ----------------------

#### Ubuntu 18.04
```bash
# Perl6
sudo apt-get -y install rakudo moarvm moarvm-dev

# SQLite
sudo apt-get -y install sqlite3
# Add 'sqlitebrowser' to the end if you want a GUI for the database

# Curl
sudo apt-get -y install curl libcurl4-openssl-dev

# Zef (module manager)
cd /tmp
git clone https://github.com/ugexe/zef.git
cd zef
perl6 -I. bin/zef install .
sudo ln -s ~/.perl6/bin/zef /usr/local/bin/zef
```
---
#### Ubuntu < 18
You will need to install Perl6 manually (which is kind of a pain). Here are some useful links:

[Rakudo GitHub](https://github.com/rakudo/rakudo) (For manual installation)

[Installing Rakudo Star](https://rakudo.org/files/star/source) (I've not had much luck with this in the past, but your results may differ)

If you went with manual install, you'll need to also install Zef manually too, see the end of the install process for Ubuntu 18.04.

```bash
# SQLite
sudo apt-get -y install sqlite3
# Add 'sqlitebrowser' to the end if you want a GUI for the database

# Curl
sudo apt-get -y install curl libcurl4-openssl-dev
```
---
#### Windows 10 (and possibly lower, I've not tried)

Curl should already come installed, but if not you can download it [here](https://curl.haxx.se/download.html).

[SQLite](http://www.sqlitetutorial.net/download-install-sqlite/)

[Rakudo Star](https://rakudo.org/files/star/source)

## ------------------------- Modules ---------------------------

- Curl
    - [LibCurl::HTTP](https://github.com/CurtTilmes/perl6-libcurl#libcurlhttp)
- Database
    - [DBIish](https://github.com/perl6/DBIish)
- JSON
    - [JSON::Fast](https://github.com/timo/json_fast)

## -------------------- Database Usage --------------------

See my gist for the DBIish wrapper I built [here](https://gist.github.com/benpitman/7b399aa63193498828c443040cd01050) for more information.
