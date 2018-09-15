#!/usr/bin/perl6

use v6;

need Service::Service;

need Entity::Entity;

need Module::Api::ApiDataService;
need Module::Api::ApiHttpService;
need Module::Message::MessageService;
need Module::Response::ResponseService;

class ApiService
{
    has $!service = Service.new;

    method updateMe ()
    {
        # Get response
        my $apiHttpService = ApiHttpService.new;
        my Entity $httpEntity = $apiHttpService.post($!service.getPostUrl() ~ '/getMe');

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
        my Entity $httpEntity = $apiHttpService.post($!service.getPostUrl() ~ '/getWebhookInfo');

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

        my $postString = self!stringifyPost(%(
            offset => $!service.getUpdateId() + 1
        ));

        my Entity $httpEntity = $apiHttpService.post($!service.getPostUrl() ~ '/getUpdates', $postString);

        return $httpEntity if $httpEntity.hasErrors();

        my $response = $httpEntity.getData();

        # Parse response
        my $apiDataService = ApiDataService.new;
        my Entity $dataEntity = $apiDataService.parseUpdateResponse($response);

        return $dataEntity if $dataEntity.hasErrors();

        if $dataEntity.hasData() {
            my Entity $forwardEntity = self.forwardMessages($dataEntity.getData());

            return $forwardEntity if $forwardEntity.hasErrors();
        }

        return $dataEntity;
    }

    method forwardMessages (@responses)
    {
        my $text;
        my $entity = Entity.new;

        for @responses -> %response {
            $text = '';

            if %response<pretext> {
                $text ~= "Chat: " ~ %response<chat> ~ "\n" if ?%response<chat>;
                $text ~= "From: " ~ %response<from>;
            }
            $text ~= "\n\n" ~ %response<text> if ?%response<text>;

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
                    %response<chatId>
                );

                if $dataEntity.hasErrors() {
                    $entity.addError($dataEntity.getErrors());
                    return $entity;
                }
            }
        }

        return $entity;
    }

    method sendMessage (Cool $chat_id, Str $text, $reply_to_message_id = Nil, $reply_markup = Nil)
    {
        my $postString = self!stringifyPost(%(
            :$chat_id,
            :$text,
            :$reply_to_message_id,
            :$reply_markup
        ));
        my $apiHttpService = ApiHttpService.new;

        return $apiHttpService.post($!service.getPostUrl() ~ "/sendMessage", $postString);
    }

    method !stringifyPost (%post)
    {
        my $postString = '';

        for %post.kv -> $key, $val {
            $postString ~= '&' ~ $key ~ '=' ~ $val if $val.defined;
        }

        return $postString;
    }
}
