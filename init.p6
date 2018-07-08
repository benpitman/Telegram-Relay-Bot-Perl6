#!/usr/bin/perl6

use v6;
use lib <lib Settings>;
use Service;
use JSON::Tiny;

sub MAIN ()
{
    my $configFile = open('Settings/config.json', :r);
    my %config = from-json($configFile.slurp);
    $configFile.close;

    my $apiService = Service.getApiService();
    $apiService.=new(apiConfig => %config<bot><api>);

    $apiService.getUpdates().say;
}
