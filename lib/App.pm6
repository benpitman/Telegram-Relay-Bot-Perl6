#!/usr/bin/perl6

use v6;
use JSON::Fast;

need Entity::Entity;
need Service::Service;

need Repository::AbstractRepository;

need Module::Api::ApiService;
need Module::Error::ErrorService;
need Module::Message::MessageService;

class App
{
    has $!service = Service.new;
    has $!apiService;

    method init ()
    {
        my %config = $!service.getConfig();

        my Entity $apiEntity;

        $!apiService = ApiService.new(apiConfig => %config<api>);

        $apiEntity = $!apiService.getWebhookInfo();

        self!parseErrors($apiEntity) if $apiEntity.hasErrors();
        my $webhookUrl = $apiEntity.getData()<webhook>;

        if ?%config<webhook><url> {
            if %config<webhook><url> === $webhookUrl {
                self!listener();
            }
            else {
                die 'Webook URL does not match config URL'
            }
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

        loop {
            my Entity $apiEntity = $!apiService.getUpdates();
            self!parseErrors($apiEntity) if $apiEntity.hasErrors();

            sleep 10;
        }
    }

    method !listener ()
    {
        return;
    }

    method !parseErrors(Entity $entity)
    {
        my $errorService = ErrorService.new;
        $errorService.insert($entity.getErrors());
        $entity.dispatch();
    }
}
