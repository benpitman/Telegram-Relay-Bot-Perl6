#!/usr/bin/perl6

use v6;

need Entity::Entity;
need Module::Link::LinkRepository;

class LinkService
{
    method insert ()
    {
        return;
    }

    method getTarget (Cool $chatId)
    {
        my $linkRepository = LinkRepository.new;

        $linkRepository.select();

        $linkRepository.where('link_origin_chat_id', $chatId);

        return $linkRepository.getFirst();
    }
}
