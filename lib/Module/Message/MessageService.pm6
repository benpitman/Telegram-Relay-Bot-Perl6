#!/usr/bin/perl6

use v6;

need Module::Message::MessageRepository;

class MessageService
{
    method insert ($messageId, $chatId, $userId, $toMessageId, $stickerId, $documentId, $messageText, $messageDate)
    {
        my $messageRepository = MessageRepository.new;
        return $messageRepository.insert(
            %(
                message_id              => $messageId,
                message_chat_id         => $chatId,
                message_user_id         => $userId,
                message_to_message_id   => $toMessageId,
                message_sticker_id      => $stickerId,
                message_document_id     => $documentId,
                message_text            => $messageText,
                message_date            => $messageDate
            )
        );
    }

    method getOneByMessageId ($messageId, $chatId)
    {
        my $messageRepository = MessageRepository.new;

        $messageRepository.select();

        $messageRepository.where(
            ['message_id', 'message_chat_id'],
            [$messageId, $chatId]
        );

        return $messageRepository.getFirst();
    }
}
