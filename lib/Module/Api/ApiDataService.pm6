#!/usr/bin/perl6

use v6;
use JSON::Tiny;

need Entity::Entity;
need Service::Service;

need Module::Chat::ChatService;
need Module::Link::LinkService;
need Module::Message::MessageService;
need Module::User::UserService;

need Module::Message::Entity::MessageRequestEntity;
need Module::Message::Entity::MessageResponseEntity;

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

    method parseMeResponse (Str $response)
    {
        self.validateResponse($response);
        return $!entity if $!entity.hasErrors() || !@!results.elems;

        my $userService = UserService.new;
        my Entity $userEntity = $userService.getOneByUserId(@!results[0]<id>);

        if $userEntity.hasErrors() {
            $!entity.addError($userEntity.getErrors());
            return $!entity;
        }

        my $botId;
        if $userEntity.hasData() {
            $botId = $userEntity.getData()<ID>;
        }
        else {
            my $userEntity = $userService.insert(
                @!results[0]<id>,
                @!results[0]<is_bot>,
                @!results[0]<first_name>    // 'NULL',
                @!results[0]<last_name>     // 'NULL',
                @!results[0]<username>      // 'NULL'
            );

            if $userEntity.hasErrors() {
                $!entity.addError($userEntity.getErrors());
                return $!entity;
            }

            $botId = $userEntity.getData()[0];
        }

        $!service.setBotId($botId);
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

            # Save message
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

            # Parse commands
            my $messageIsCommand = False;
            if %message<text>.starts-with('/') {
                $messageIsCommand = True;
                my Entity $messageEntity = $messageService.parseCommand(%message<text>, $userId);

                if $messageEntity.hasErrors() {
                    $!entity.addError($messageEntity.getErrors());
                    return $!entity;
                }

                given $messageEntity {
                    when MessageResponseEntity {
                        %response<message> = $messageEntity.getMessage();
                    }
                    when MessageRequestEntity {
                        %response<message> = $messageEntity.getData();
                    }
                    default {
                        %response<message> = $messageEntity.getMessage();
                    }
                }
            }

            if $messageIsCommand {
                $chatEntity = $chatService.getOneById($chatId);
                return $chatEntity if $chatEntity.hasErrors();
                %response<from> = 'Relay';
                %response<target> = $chatEntity.getData()<chat_id>;
            }
            else {
                # Get target chat ID
                my $linkService = LinkService.new;
                my Entity $linkEntity = $linkService.getTarget();

                if $linkEntity.hasErrors() {
                    $!entity.addError($linkEntity.getErrors());
                    return $!entity;
                }

                my $targetId;
                if $linkEntity.hasData() {
                    $targetId = $linkEntity.getData();
                }
                else {
                    $targetId = $!service.getDefaultTargetChatId();
                }

                next if $targetId === -1;

                $chatEntity = $chatService.getOneById($targetId);
                return $chatEntity if $chatEntity.hasErrors();
                %response<target> = $chatEntity.getData()<chat_id>;
            }

            @responses.push: %response;
        }

        $!service.setUpdateId($updateId);
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
