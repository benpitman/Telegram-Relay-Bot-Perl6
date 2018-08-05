#!/usr/bin/perl6

use v6;
use JSON::Fast;

class Service
{
    has $!configFilePath;
    has %!config;

    submethod BUILD ()
    {
        $!configFilePath = 'Settings/config.json';
        $!configFilePath.IO.e or die "'$!configFilePath' file not found";

        try {
            from-json($!configFilePath.IO.slurp);

            CATCH {
                die 'Config file is incorrectly formatted';
            }
        }

        %!config = from-json($!configFilePath.IO.slurp);
    }

    method getConfig ()
    {
        return %!config;
    }

    method getUpdateId ()
    {
        return %!config<api><updateId>;
    }

    method saveUpdateId (Int $updateId)
    {
        %!config<api><updateId> = $updateId;

        spurt $!configFilePath, to-json(%!config, :pretty, :spacing(4)), :close;
    }
}
