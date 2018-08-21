#!/usr/bin/perl6

use v6;

need Module::Api::ApiDataService;
# need Module::Api::ApiDBService;
need Module::Api::ApiHttpService;
# need Api::ApiTextService;
need Module::Message::MessageService;
need Module::Response::ResponseService;
need Entity::Entity;

class ApiService
{
    has %.apiConfig;

    # has $!apiDBService = ApiDBService.new;
    # has $!apiTextService = ApiTextService.new;

    has $!token = %!apiConfig<token>;
    has $!url = "https://api.telegram.org/bot" ~ $!token;
    has %!post = %();

    method updateMe ()
    {
        # Get response
        my $apiHttpService = ApiHttpService.new;
        my Entity $httpEntity = $apiHttpService.post($!url ~ '/getMe');

        return $httpEntity if $httpEntity.hasErrors();

        my $response = $httpEntity.getData();

        # Save response
        my $responseService = ResponseService.new;
        my Entity $responseEntity = $responseService.insert($response);

        return $responseEntity if $responseEntity.hasErrors();

        # Parse response
        my $apiDataService = ApiDataService.new;
        my Entity $dataEntity = $apiDataService.parseMeResponse($response);

        return $dataEntity;
    }

    method getWebhookInfo ()
    {
        # Get HTTP response
        my $apiHttpService = ApiHttpService.new;
        my Entity $httpEntity = $apiHttpService.post($!url ~ '/getWebhookInfo');

        return $httpEntity if $httpEntity.hasErrors();

        my $response = $httpEntity.getData();

        # Save response
        my $responseService = ResponseService.new;
        my Entity $responseEntity = $responseService.insert($response);

        return $responseEntity if $responseEntity.hasErrors();

        # Parse response
        my $apiDataService = ApiDataService.new;
        my Entity $dataEntity = $apiDataService.parseWebhookResponse($response);

        return $dataEntity if $dataEntity.hasErrors();

        return $dataEntity;
    }

    method getUpdates ()
    {
        # Get response
        my $apiHttpService = ApiHttpService.new;
        my Entity $httpEntity = $apiHttpService.post($!url ~ '/getUpdates');

        return $httpEntity if $httpEntity.hasErrors();

        my $response = $httpEntity.getData();

        # Save response
        my $responseService = ResponseService.new;
        my Entity $responseEntity = $responseService.insert($response);

        return $responseEntity if $responseEntity.hasErrors();

        # Parse response
        my $apiDataService = ApiDataService.new;
        my Entity $dataEntity = $apiDataService.parseUpdateResponse($response);

        return $dataEntity if $dataEntity.hasErrors();

        if $dataEntity.hasData() {
            self.forwardMessages($dataEntity.getData());
        }

        return $dataEntity;
    }

    method forwardMessages (@responses)
    {
        my $text;
        for @responses -> %response {
            $text = '';
            $text ~= "Chat: " ~ %response<chat> if ?%response<chat>;
            $text ~= "\nFrom: " ~ %response<from>;
            $text ~= "\n\n%response<message>" if ?%response<message>;

            self.sendMessage(%response<target>, $text);
        }
    }

    method sendMessage (Cool $chat_id, Str $text)
    {
        %!post = %(
            :$chat_id,
            :$text,
        );

        # %!post.push: $_ for %addenda;

        my $post = self!stringifyPost();
        my $apiHttpService = ApiHttpService.new;
        my Entity $httpEntity = $apiHttpService.post($!url ~ "/sendMessage", $post);
    }

    method !stringifyPost ()
    {
        # return ~%!post
        #     .subst( /\n/, '&', :g )
        #     .subst( /\h+/, '=', :g );
        my $post = '';
        for %!post.kv -> $key, $val {
            $post ~= '&' ~ $key ~ '=' ~ $val;
        }
        return $post;

        # say S:g[\h+] = '=' with ( S[\n] = '&' with ~%a );
    }
}
