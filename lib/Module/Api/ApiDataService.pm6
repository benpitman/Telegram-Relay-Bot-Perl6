#!/usr/bin/perl6

use v6;
use JSON::Tiny;

need Entity::Entity;
need Service::Service;

need Module::Chat::ChatService;
need Module::ChatLink::ChatLinkService;
need Module::Command::CommandService;
need Module::Message::MessageService;
need Module::MessageLink::MessageLinkService;
need Module::Request::RequestService;
need Module::Response::ResponseService;
need Module::User::UserService;

need Module::Command::Entity::CommandRequestEntity;
need Module::Command::Entity::CommandResponseEntity;

class ApiDataService
{
    has $!entity = Entity.new;
    has @!results = [];
    has $!service = Service.new;

    method validateResponse (Str $response)
    {
        # Save response
        my $responseService = ResponseService.new;
        my Entity $responseEntity = $responseService.insert($response);

        if $responseEntity.hasErrors() {
            $!entity.addError($responseEntity.getErrors());
            return $!entity;
        }

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
                @!results[0]<first_name>    // Nil,
                @!results[0]<last_name>     // Nil,
                @!results[0]<username>      // Nil
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

            next if %result<update_id> le $updateId;
            # Overwrite every time so it's set to the last in the loop
            $updateId = %result<update_id>;
            my %message = %result<message>;
            my %response = %();
            my $relayMessage = True;
            my $requestResponse = False;
            my $silent = False;

            # Get user if it exists
            my %from = %message<from>;
            my $userId = self!addUser(%from);
            return $!entity if $!entity.hasErrors();

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
                    %chat<title> // Nil,
                    %chat<type>
                );

                if $chatEntity.hasErrors() {
                    $!entity.addError($chatEntity.getErrors());
                    return $!entity;
                }

                $chatId = $chatEntity.getData()[0];
            }

            $chatEntity = $chatService.getTitle($chatId);

            if $chatEntity.hasErrors() {
                $!entity.addError($chatEntity.getErrors());
                return $!entity;
            }

            %response<chat> = $chatEntity.getData();

            $chatEntity = $chatService.getOneByChatId(%chat<id>);

            if $chatEntity.hasErrors() {
                $!entity.addError($chatEntity.getErrors());
                return $!entity;
            }
            my $chatType = $chatEntity.getData()<chat_type>;

            # If chat is private, never relay the message
            if $chatType === 'private' {
                $relayMessage = False;
            }

            # Get reply to message if exists
            my $toMessageId;
            my $toUserId;
            my $requestType;
            if ?%message<reply_to_message> {
                my $toUserId = self!addUser(%message<reply_to_message><from>);
                return $!entity if $!entity.hasErrors();

                if $toUserId eq $!service.getBotId() and $chatType === 'private' {

                    # Check if there are any awaiting requests for that user
                    my $requestService = RequestService.new;
                    my Entity $requestEntity = $requestService.getPendingByIds($chatId, $userId);

                    if $requestEntity.hasErrors() {
                        $!entity.addError($requestEntity.getErrors());
                        return $!entity;
                    }

                    if $requestEntity.hasData() {
                        # If there is a request waiting, never relay
                        $relayMessage = False;
                        $requestResponse = True;
                        $requestType = $requestEntity.getData()<request_type>;
                    }
                    else {
                        $silent = True;
                    }
                }
                else {
                    my Entity $messageEntity = $messageService.getOneByMessageId(
                        %message<reply_to_message><message_id>,
                        $chatId
                    );

                    if $messageEntity.hasErrors() {
                        $!entity.addError($messageEntity.getErrors());
                        return $!entity;
                    }

                    if $messageEntity.hasData() {
                        $toMessageId = $messageEntity.getData()<ID>;
                    }
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
                $chatId,
                $userId,
                $toMessageId                    // Nil,
                $stickerId                      // Nil,
                $documentId                     // Nil,
                %message<text>                  // Nil,
                DateTime.new(%message<date>)
            );
            %response<text> = %message<text> // '';

            if $messageEntity.hasErrors() {
                $!entity.addError($messageEntity.getErrors());
                return $!entity;
            }
            my $messageId = $messageEntity.getData()[0];
            %response<messageId> = $messageId;

            # Parse commands
            if %message<text>.starts-with('/') {
                # If message is a command, never relay
                $relayMessage = False;
                my $commandService = CommandService.new;
                my Entity $commandEntity = $commandService.parseCommand(
                    %message<text>,
                    $chatId,
                    $userId,
                    $chatType === 'private'
                );

                if $commandEntity.hasErrors() {
                    $!entity.addError($commandEntity.getErrors());
                    return $!entity;
                }

                given $commandEntity {
                    when CommandResponseEntity {
                        %response<text> = $commandEntity.getMessage();
                    }
                    when CommandRequestEntity {
                        %response<text> = $commandEntity.getMessage();
                        %response<markup> = $commandEntity.getMarkup();

                        my $requestService = RequestService.new;
                        my Entity $requestEntity = $requestService.insert(
                            %response<text>,
                            $commandEntity.getRequestType(),
                            $chatId,
                            $userId
                        );

                        if $requestEntity.hasErrors() {
                            $!entity.addError($requestEntity.getErrors());
                            return $!entity;
                        }
                    }
                    default {
                        %response<text> = $commandEntity.getMessage();
                    }
                }
            }

            if $requestResponse {
                my $commandService = CommandService.new;
                my Entity $commandEntity = $commandService.parseResponse(
                    $requestType,
                    %message<text>,
                    $userId
                );

                if $commandEntity.hasErrors() {
                    $!entity.addError($commandEntity.getErrors());
                    return $!entity;
                }

                %response<text> = $commandEntity.getMessage();
            }

            %response<relay> = $relayMessage;
            if !$relayMessage {
                my Entity $userEntity = $userService.getName($!service.getBotId());
                return $userEntity if $userEntity.hasErrors();

                %response<from> = $userEntity.getData();

                $chatEntity = $chatService.getOneById($chatId);
                return $chatEntity if $chatEntity.hasErrors();

                %response<targetChat> = $chatEntity.getData()<chat_id>;
            }
            else {
                # Get user's name
                my Entity $userEntity = $userService.getName($userId);
                return $userEntity if $userEntity.hasErrors();
                %response<from> = $userEntity.getData();

                # Get target chat ID
                my $chatLinkService = ChatLinkService.new;
                my Entity $chatLinkEntity = $chatLinkService.getOneByOrigin($chatId);

                if $chatLinkEntity.hasErrors() {
                    $!entity.addError($chatLinkEntity.getErrors());
                    return $!entity;
                }

                my $targetChatId;
                if $chatLinkEntity.hasData() {
                    $targetChatId = $chatLinkEntity.getData()<chat_link_target_chat_id>;
                    %response<chatLinkId> = $chatLinkEntity.getData()<ID>;
                }
                else {
                    $targetChatId = $!service.getDefaultTargetChatId();
                }

                next if $targetChatId === -1;

                $chatEntity = $chatService.getOneById($targetChatId);
                return $chatEntity if $chatEntity.hasErrors();
                %response<targetChat> = $chatEntity.getData()<chat_id>;

                # Get target message ID
                my $messageLinkService = MessageLinkService.new;
                my Entity $messageLinkEntity = $messageLinkService.getOneByOrigin($messageId);

                if $messageLinkEntity.hasErrors() {
                    $!entity.addError($messageLinkEntity.getErrors());
                    return $!entity;
                }

                my $targetMessageId;
                if $messageLinkEntity.hasData() {
                    $targetMessageId = $messageLinkEntity.getData()<message_link_target_message_id>;
                    %response<messageLinkId> = $messageLinkEntity.getData()<ID>;
                }
                else {
                    $targetMessageId = $!service.getDefaultTargetMessageId();
                }

                next if $targetMessageId === -1;

                $messageEntity = $messageService.getOneById($targetMessageId);
                return $messageEntity if $messageEntity.hasErrors();
                %response<targetMessage> = $messageEntity.getData()<message_id>;
            }

            @responses.push: %response;
        }

        $!service.setUpdateId($updateId);
        $!entity.setData(@responses);

        return $!entity;
    }

    method saveRelay (Str $response, Cool $originMessageId, Cool $chatLinkId = Nil)
    {
        self.validateResponse($response);
        return $!entity if $!entity.hasErrors() || !@!results.elems;

        my $messageLinkService = MessageLinkService.new;

        my Entity $messageLinkEntity = $messageLinkService.insert(
            %(
                'message_link_origin_message_id'    => $originMessageId,
                'message_link_target_message_id'    => @!results[0]<message><message_id>,
                'message_link_chat_link_id'         => $chatLinkId
            )
        );

        if $messageLinkEntity.hasErrors() {
            $!entity.addError($messageLinkEntity.getErrors());
            return $!entity;
        }
    }

    method !addUser (%user)
    {
        my $userService = UserService.new;
        my Entity $userEntity = $userService.getOneByUserId(%user<id>);

        if $userEntity.hasErrors() {
            $!entity.addError($userEntity.getErrors());
            return -1;
        }

        if $userEntity.hasData() {
            return $userEntity.getData()<ID>;
        }

        $userEntity = $userService.insert(
            %user<id>,
            %user<is_bot>,
            %user<first_name>   // Nil,
            %user<last_name>    // Nil,
            %user<username>     // Nil
        );

        if $userEntity.hasErrors() {
            $!entity.addError($userEntity.getErrors());
            return -1;
        }

        return $userEntity.getData()[0];
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
