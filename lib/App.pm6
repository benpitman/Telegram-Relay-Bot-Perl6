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
    has %!config;
    has $!service = Service.new;
    has $!messageService;

    method init ()
    {
        %!config = $!service.getConfig();

        my Entity $apiEntity;

        my $apiService = ApiService.new(apiConfig => %!config<api>);

        $apiEntity = $apiService.getWebhookInfo();

        self!parseErrors($apiEntity) if $apiEntity.hasErrors();
        my $webhookUrl = $apiEntity.getData()<webhook>;

        if ?%!config<webhook><url> {
            if %!config<webhook><url> === $webhookUrl {
                # self!listener();
                return;
            }
            else {
                die 'Webook URL does not match config URL'
            }
        }
        elsif $apiEntity.getData()<pending> > 0 {
            $apiService = ApiService.new(apiConfig => %!config<api>);
            $apiEntity = $apiService.getUpdates();

            self!parseErrors($apiEntity) if $apiEntity.hasErrors();
        }
    }

    method !parseErrors(Entity $entity)
    {
        # my $errorService = ErrorService.new;
        # $errorService.insert($entity.getErrors());
        $entity.dispatch();
    }
}
