#!/usr/bin/perl6

use v6;

need Module::User::UserRepository;

class UserService
{
    method insert ($userId, $isBot, $firstName, $lastName, $username)
    {
        my $userRepository = UserRepository.new;
        return $userRepository.insert(
            %(
                user_id         => $userId,
                user_bot        => +$isBot,
                user_name       => $firstName ~ ' ' ~ $lastName,
                user_username   => $username
            )
        );
    }
}
