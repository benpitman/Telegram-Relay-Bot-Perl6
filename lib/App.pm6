#!/usr/bin/perl6

use v6;
use JSON::Tiny;

need Service::Service;
need Entity::Entity;

need Repository::AbstractRepository;

need Module::Api::ApiService;
need Module::Error::ErrorService;
need Module::Message::MessageService;

class App
{
    has $!apiService;

    method new ()
    {
        my %config = Service.getConfig();
        my Entity $apiEntity;

        $!apiService = ApiService.new(apiConfig => %config<api>);

        $apiEntity = $!apiService.getWebhookInfo();

        self!parseErrors($apiEntity) if $apiEntity.hasErrors();
        my $webhookUrl = $apiEntity.getData()<webhook>;

        if ?%config<webhook><url> && %config<webhook><url> === $webhookUrl {
            self!listener();
        }
        else {
            self!updateLoop();
        }

        # AbstractRepository.new(database => %config<database>);
        # AbstractRepository.new();

        # my $messageService = MessageService.new;
        # my $messageEntity = $messageService.get();
        # say $messageEntity.dispatch();
        # exit;


        # my $apiEntity = $apiService.sendMessage("1", "hello");

        # $apiEntity.dispatch() if $apiEntity.hasErrors();

        # my $textService = TextService.new();
    }

    method !updateLoop ()
    {
        my Entity $apiEntity = $!apiService.getUpdates();
    }

    method !listener ()
    {
    }

    method !parseErrors(Entity $entity)
    {
        my $errorService = ErrorService.new;
        $errorService.insert($entity.getErrors());
        $entity.dispatch();
    }
}
