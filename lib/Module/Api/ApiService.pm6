#!/usr/bin/perl6

use v6;

need Module::Api::ApiDataService;
need Module::Api::ApiDBService;
need Module::Api::ApiHttpService;
# need Api::ApiTextService;
need Module::Message::MessageService;
need Entity::Entity;

class ApiService
{
    has %.apiConfig;

    has $!apiDataService = ApiDataService.new;
    has $!apiDBService = ApiDBService.new;
    has $!apiHttpService = ApiHttpService.new;
    # has $!apiTextService = ApiTextService.new;

    has $!entity = Entity.new;
    has $!token = %!apiConfig<token>;
    has $!url = "https://api.telegram.org/bot" ~ $!token;
    has %!post = %();

    method getUpdates ()
    {
        $!url ~= "/getUpdates";

        my Entity $httpEntity = $!apiHttpService.post($!url);
        if $httpEntity.hasErrors() {
            $!entity.addError($httpEntity.getErrors());
            return $!entity;
        }

        my Entity $dataEntity = $!apiDataService.parseResponse($httpEntity.getData());
        if $dataEntity.hasErrors() {
            $!entity.addError($dataEntity.getErrors());
            return $!entity;
        }

        #TODO check if message exists

        my $messageService = MessageService.new;
        $messageService.get();

        return $!entity;
    }

    method sendMessage (Cool $chat_id, Str $text, *%addenda)
    {
        $!url ~= "/sendMessage";
        %!post = %(
            :$chat_id,
            :$text,
        );

        %!post.push: $_ for %addenda;

        my $post = self!stringifyPost();
    }

    method !stringifyPost ()
    {
        return ~%!post
            .subst( /\n/, '&', :g )
            .subst( /\h+/, '=', :g );

        # say S:g[\h+] = '=' with ( S[\n] = '&' with ~%a );
    }
}
