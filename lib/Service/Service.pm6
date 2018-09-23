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

    method getPostUrl ()
    {
        return "https://api.telegram.org/bot" ~ %!config<api><botToken>;
    }

    method updateConfig ()
    {
        %!config = from-json($!configFilePath.IO.slurp);
    }

    method getConfig ()
    {
        self.updateConfig();
        return %!config;
    }

    method getDatabase ()
    {
        self.updateConfig();
        return %!config<database>.gist;
    }

    method getUpdateId ()
    {
        self.updateConfig();
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
        self.updateConfig();
        return %!config<api><adminId> gt -1;
    }

    method isAdmin (Int $userId)
    {
        self.updateConfig();
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
        self.updateConfig();
        return %!config<api><defaultTargetChatId>;
    }

    method setDefaultTargetChatId (Int $defaultTargetChatId)
    {
        self.updateConfig();
        %!config<api><defaultTargetChatId> = $defaultTargetChatId;
        self!saveConfig();
    }

    method isDefaultTargetChatId (Cool $chatId)
    {
        self.updateConfig();
        return %!config<api><defaultTargetChatId> eq $chatId;
    }

    method getBotId ()
    {
        self.updateConfig();
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
        self.updateConfig();
        return %!config<api><botToken>;
    }

    method !saveConfig ()
    {
        spurt $!configFilePath, to-json(%!config, :pretty, :spacing(4)), :close;
    }
}
