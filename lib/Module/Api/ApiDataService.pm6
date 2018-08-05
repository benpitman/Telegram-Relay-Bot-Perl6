#!/usr/bin/perl6

use v6;
use JSON::Tiny;

need Entity::Entity;
need Service::Service;

need Module::User::UserService;
need Module::Chat::ChatService;
need Module::Message::MessageService;

class ApiDataService
{
    has $!entity = Entity.new;
    has @!results = [];
    has $!service = Service.new;

    method validateResponse (Str $response)
    {
        my %response = from-json($response);

        if !%response<ok> {
            $!entity.addError('(' ~ %response<error_code> ~ '): ' ~ %response<description>);
            return $!entity;
        }

        # Result can be array or hash, this makes sure it's always a 1D array
        given %response<result> {
            when Hash   { @!results = [$_]; }
            when Array  { @!results = |$_; }
        }

        # No results
        return $!entity if !@!results.elems;
    }

    method parseWebhookResponse (Str $response)
    {
        self.validateResponse($response);

        $!entity.setData(
            %(
                webhook => ?@!results[0]<url> // '',
                pending => +@!results[0]<pending_update_count> // 0
            )
        );

        return $!entity;
    }

    method parseUpdateResponse (Str $response)
    {
        self.validateResponse($response);

        return $!entity if $!entity.hasErrors() || !@!results.elems;

        my $updateId = $!service.getUpdateId();
        my @responses = [];
        my $userService = UserService.new;
        my $chatService = ChatService.new;
        my $messageService = MessageService.new;
        # my $fileService = FileService.new; #TODO for stickers, documents and other files

        for @!results -> %result {

            next if %result<update_id> <= $updateId;
            # Overwrite every time so it's set to the last in the loop
            $updateId = %result<update_id>;
            my %message = %result<message>;
            my %response = %();

            # Get user if it exists
            my %from = %message<from>;
            my Entity $userEntity = $userService.getOneByUserId(%from<id>);

            if $userEntity.hasErrors() {
                $!entity.addError($userEntity.getErrors());
                return $!entity;
            }

            my $userId;
            if $userEntity.hasData() {
                $userId = $userEntity.getData()<ID>;
            }
            else {
                $userService = UserService.new;
                $userEntity = $userService.insert(
                    %from<id>,
                    %from<is_bot>,
                    %from<first_name>   // 'NULL',
                    %from<last_name>    // 'NULL',
                    %from<username>     // 'NULL'
                );

                if $userEntity.hasErrors() {
                    $!entity.addError($userEntity.getErrors());
                    return $!entity;
                }

                $userId = $userEntity.getData()[0];
            }
            $userEntity = $userService.getName($userId);
            return $userEntity if $userEntity.hasErrors();
            %response<from> = $userEntity.getData();

            # Get chat if exists
            my %chat = %message<chat>;
            my Entity $chatEntity = $chatService.getOneByChatId(%chat<id>);

            if $chatEntity.hasErrors() {
                $!entity.addError($chatEntity.getErrors());
                return $!entity;
            }

            my $chatId;
            if $chatEntity.hasData() {
                $chatId = $chatEntity.getData()<ID>;
            }
            else {
                my Entity $chatEntity = $chatService.insert(
                    %chat<id>,
                    %chat<title> // 'NULL',
                    %chat<type>
                );

                if $chatEntity.hasErrors() {
                    $!entity.addError($chatEntity.getErrors());
                    return $!entity;
                }

                $chatId = $chatEntity.getData()[0];
            }

            $chatEntity = $chatService.getTitle($chatId);
            return $chatEntity if $chatEntity.hasErrors();
            %response<chat> = $chatEntity.getData();

            # Get reply to message if exists
            my $toMessageId;
            if ?%message<reply_to_message> {
                my Entity $messageEntity = $messageService.getOneByMessageId(
                    %message<reply_to_message><message_id>,
                    $toMessageId
                );

                if $messageEntity.hasErrors() {
                    $!entity.addError($messageEntity.getErrors());
                    return $!entity;
                }

                if $messageEntity.hasData() {
                    $toMessageId = $messageEntity.getData()<ID>;
                }
            }

            # Get sticker if exists
            my $stickerId;
            if %message<sticker> {
                # $stickerId = self.getIfExists($messageService, %message<sticker><file_id>);

                return $!entity if $!entity.hasErrors();
            }

            # Get document if exists
            my $documentId;
            if %message<document> {
                # $documentId = self.getIfExists($messageService, %message<sticker><file_id>);

                return $!entity if $!entity.hasErrors();
            }

            my Entity $messageEntity = $messageService.insert(
                %message<message_id>,
                $userId,
                $chatId,
                $toMessageId                    // 'NULL',
                $stickerId                      // 'NULL',
                $documentId                     // 'NULL',
                %message<text>                  // 'NULL',
                DateTime.new(%message<date>)
            );
            %response<message> = %message<text> // '';

            if $messageEntity.hasErrors() {
                $!entity.addError($messageEntity.getErrors());
                return $!entity;
            }

            if $messageEntity.hasData() {
                @responses.push: %response;
            }
        }

        $!service.saveUpdateId($updateId);
        $!entity.setData(@responses);

        return $!entity;
    }

    method getIfExists ($service, $id)
    {
        my Entity $entity = $service.getOneBySubId($id);

        if $entity.hasErrors() {
            $!entity.addError($entity.getErrors());
            return
        }

        if $entity.hasData() {
            return $entity.getData()<ID>;
        }
    }
}
