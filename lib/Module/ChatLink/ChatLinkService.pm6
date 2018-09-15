#!/usr/bin/perl6

use v6;

need Entity::Entity;
need Module::ChatLink::ChatLinkRepository;

class ChatLinkService
{
    method insert (Cool $originChatId, Cool $targetChatId)
    {
        my $chatLinkEntity = self.getOneByOrigin($originChatId);

        return $chatLinkEntity if $chatLinkEntity.hasErrors();

        my $chatLinkRepository = ChatLinkRepository.new;

        if $chatLinkEntity.hasData() {
            $chatLinkRepository.set('chat_link_target_chat_id', $targetChatId);

            $chatLinkRepository.where('ID', $chatLinkEntity.getData()<ID>);

            return $chatLinkRepository.save();
        }
        else {
            return $chatLinkRepository.insert(
                %(
                    'chat_link_origin_chat_id'    => $originChatId,
                    'chat_link_target_chat_id'    => $targetChatId
                )
            );
        }
    }

    method getOneByOrigin (Cool $chatId)
    {
        my $chatLinkRepository = ChatLinkRepository.new;

        $chatLinkRepository.select();
        $chatLinkRepository.where('chat_link_origin_chat_id', $chatId);

        return $chatLinkRepository.getFirst();
    }

    method getChatLink (Cool $chatId)
    {
        my $entity = Entity.new;
        my $chatLinkRepository = ChatLinkRepository.new;

        $chatLinkRepository.select();

        $chatLinkRepository.where('chat_link_origin_chat_id', $chatId);
        $chatLinkRepository.orWhere('chat_link_target_chat_id', $chatId);

        my Entity $chatLinkEntity = $chatLinkRepository.getFirst();

        return $chatLinkEntity if $chatLinkEntity.hasErrors();

        if $chatLinkEntity.getData()<chat_link_origin_chat_id> === $chatId {
            $entity.setData($chatLinkEntity.getData()<chat_link_target_chat_id>);
        }
        else {
            $entity.setData($chatLinkEntity.getData()<chat_link_origin_chat_id>);
        }

        return $entity;
    }
}
