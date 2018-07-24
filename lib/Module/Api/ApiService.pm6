#!/usr/bin/perl6

use v6;

need Module::Api::ApiDataService;
need Module::Api::ApiDBService;
need Module::Api::ApiHttpService;
# need Api::ApiTextService;
need Module::Message::MessageService;
need Module::Response::ResponseService;
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
        my Entity $httpEntity = $!apiHttpService.post($!url ~ "/getUpdates");
        if $httpEntity.hasErrors() {
            $!entity.addError($httpEntity.getErrors());
            return $!entity;
        }

        my $response = $httpEntity.getData();

        # my $responseService = ResponseService.new;
        # my Entity $responseEntity = $responseService.insert($response);
        #
        # if $responseEntity.hasErrors() {
        #     $!entity.addError($responseEntity.getErrors());
        #     return $!entity;
        # }

        my Entity $dataEntity = $!apiDataService.parseResponse($response);
        if $dataEntity.hasErrors() {
            $!entity.addError($dataEntity.getErrors());
            return $!entity;
        }

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
