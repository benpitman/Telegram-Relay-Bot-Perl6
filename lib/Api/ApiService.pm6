#!/usr/bin/perl6

use v6;
use Api::ApiDataService;
use Api::ApiFileService;
use Api::ApiHttpService;
# use Api::ApiTextService;
use Entity::Entity;

class ApiService
{
    has %.apiConfig;

    has $!apiDataService = ApiDataService.new;
    has $!apiFileService = ApiFileService.new;
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
        $!entity.addError($httpEntity.getErrors()) if $httpEntity.hasErrors();

        my Entity $dataEntity = $!apiDataService.parseResponse($httpEntity.getData());
        $!entity.addError($dataEntity.getErrors()) if $dataEntity.hasErrors();

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
