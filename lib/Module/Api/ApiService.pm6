#!/usr/bin/perl6

use v6;

need Service::Service;

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

    has $!url = "https://api.telegram.org/bot" ~ %!apiConfig<botToken>;
    has %!post = %();

    method updateMe ()
    {
        # Get response
        my $apiHttpService = ApiHttpService.new;
        my Entity $httpEntity = $apiHttpService.post($!url ~ '/getMe');

        return $httpEntity if $httpEntity.hasErrors();

        my $response = $httpEntity.getData();

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
        my $service = Service.new;

        %!post = %(upadte_id => $service.getUpdateId() + 1);
        my $post = self!stringifyPost();

        my Entity $httpEntity = $apiHttpService.post($!url ~ '/getUpdates', $post);

        return $httpEntity if $httpEntity.hasErrors();

        my $response = $httpEntity.getData();

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
        my $entity = Entity.new;
        for @responses -> %response {
            $text = '';
            $text ~= "Chat: " ~ %response<chat> ~ "\n" if ?%response<chat>;
            $text ~= "From: " ~ %response<from>;
            $text ~= "\n\n%response<text>" if ?%response<text>;

            my Entity $httpEntity = self.sendMessage(
                %response<targetChat>,
                $text,
                %response<targetMessage>,
                %response<markup>
            );

            if $httpEntity.hasErrors() {
                $entity.addError($httpEntity.getErrors());
                return $entity;
            }

            if %response<relay> {
                my $apiDataService = ApiDataService.new;
                my Entity $dataEntity = $apiDataService.saveRelay(
                    $httpEntity.getData(),
                    %response<messageId>,
                    %response<chatLinkId>
                );
            }
        }
    }

    method sendMessage (Cool $chat_id, Str $text, $reply_to_message_id = Nil, $reply_markup = '')
    {
        %!post = %(
            :$chat_id,
            :$text,
            :$reply_to_message_id,
            :$reply_markup
        );

        # %!post.push: $_ for %addenda;

        my $post = self!stringifyPost();
        my $apiHttpService = ApiHttpService.new;
        return $apiHttpService.post($!url ~ "/sendMessage", $post);
    }

    method !stringifyPost ()
    {
        # return ~%!post
        #     .subst( /\n/, '&', :g )
        #     .subst( /\h+/, '=', :g );
        my $post = '';
        for %!post.kv -> $key, $val {
            $post ~= '&' ~ $key ~ '=' ~ $val if ?$val;
        }
        return $post;

        # say S:g[\h+] = '=' with ( S[\n] = '&' with ~%a );
    }
}
