#!/usr/bin/perl6

use v6;
use JSON::Tiny;

need Service::Service;

need Repository::AbstractRepository;

need Module::Message::MessageService;

class App
{
    method new ()
    {
        my %config = Service.getConfig();
        # AbstractRepository.new(database => %config<database>);
        AbstractRepository.new();

        my $messageService = MessageService.new;
        my $messageEntity = $messageService.get();
        say $messageEntity.dispatch();
        exit;

        my $apiService = Service.getApiService();
        $apiService.=new(apiConfig => %config<api>);

        my $apiEntity = $apiService.getUpdates();
        # my $apiEntity = $apiService.sendMessage("1", "hello");

        $apiEntity.dispatch() if $apiEntity.hasErrors();

        my $textService = Service.getTextService();
        $textService.=new();
    }
}
