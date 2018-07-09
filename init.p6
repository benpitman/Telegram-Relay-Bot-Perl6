#!/usr/bin/perl6

use v6;
use lib <lib>;
use Service;
use JSON::Tiny;

sub getConfig ()
{
    return from-json('Settings/config.json'.IO.slurp);
}

sub MAIN ()
{
    my %config = getConfig;

    my $apiService = Service.getApiService();
    $apiService.=new(apiConfig => %config<bot><api>);

    my $apiEntity = $apiService.getUpdates();

    die $apiEntity.getErrors() if $apiEntity.hasErrors();

    my $textService = Service.getTextService();
    $textService.=new();
}
