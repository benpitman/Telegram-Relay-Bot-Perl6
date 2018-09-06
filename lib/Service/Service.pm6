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

        self.updateConfig();
    }

    method updateConfig ()
    {
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

    method setUpdateId (Int $updateId)
    {
        self.updateConfig();
        %!config<api><updateId> = $updateId;
        self!saveConfig();
    }

    method adminExists ()
    {
        return %!config<api><adminId> gt -1;
    }

    method isAdmin (Int $userId)
    {
        return %!config<api><adminId> eq $userId;
    }

    method setAdmin (Int $userId)
    {
        self.updateConfig();
        %!config<api><adminId> = $userId;
        self!saveConfig();
    }

    method getDefaultTargetChatId ()
    {
        return %!config<api><defaultTargetChatId>;
    }

    method setDefaultTargetChatId (Int $defaultTargetChatId)
    {
        self.updateConfig();
        %!config<api><defaultTargetChatId> = $defaultTargetChatId;
        self!saveConfig();
    }

    method getBotId ()
    {
        return %!config<api><botId>;
    }

    method setBotId (Cool $id = -1)
    {
        self.updateConfig();
        %!config<api><botId> = $id;
        self!saveConfig();
    }

    method getBotToken ()
    {
        return %!config<api><botToken>;
    }

    method !saveConfig ()
    {
        spurt $!configFilePath, to-json(%!config, :pretty, :spacing(4)), :close;
    }
}
