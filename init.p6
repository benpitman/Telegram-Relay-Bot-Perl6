#!/usr/bin/perl6

use v6;
use lib <lib>;
use Service;
use JSON::Tiny;

sub MAIN ()
{
    my %config = getConfig();

    my $apiService = Service.getApiService();
    $apiService.=new(apiConfig => %config<bot><api>);

    my $apiEntity = $apiService.getUpdates();
    # my $apiEntity = $apiService.sendMessage("1", "hello");

    $apiEntity.dispatch() if $apiEntity.hasErrors();

    my $textService = Service.getTextService();
    $textService.=new();
}

sub updateLoop ()
{
    return;
}

sub getConfig ()
{
    my $configFile = 'Settings/config.json'.IO.slurp // die 'No config file found';
    return from-json($configFile);
}
