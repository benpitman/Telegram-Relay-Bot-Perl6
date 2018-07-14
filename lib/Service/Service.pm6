#!/usr/bin/perl6

use v6;
use JSON::Tiny;

class Service
{
    method getApiService ()
    {
        return Module::Api::ApiService;
    }

    method getConfig ()
    {
        my $configFile = 'Settings/config.json'.IO.slurp // die 'No config file found';
        return from-json($configFile);
    }
}
