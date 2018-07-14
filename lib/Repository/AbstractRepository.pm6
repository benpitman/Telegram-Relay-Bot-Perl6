#!/usr/bin/perl6

use v6;
use DBIish;

need Service::Service;
need Entity::Entity;

role AbstractRepository
{
    has $.table is rw;
    has $!dbc;
    has $!entity = Entity.new;

    submethod BUILD (:$!table)
    {
        my %config = Service.getConfig();
        my Str $database = %config<database>.gist;

        $!dbc = DBIish.connect(
            'SQLite',
            database => $database
        ) // die "Database '$database' not found.";
    }

    submethod END ()
    {
        $!dbc.dispose();
    }

    multi method insert (@rows)
    {
        my @ids;
        my @id;

        for @rows -> %row {
            @id = self.insert(%row);

            last if $!entity.hasErrors();
            @ids.push: @id[0];
        }

        return @ids;
    }

    multi method insert (%cols)
    {
        my @keys;
        my @vals;

        for %cols.kv -> $key, $val {
            @keys.push: $key;
            @vals.push: "'$val'";
        }

        my $colString = @keys.join(', ');
        my $valString = @vals.join(', ');
        my $dbs;

        try {
            $dbs = $!dbc.prepare(qq:to/STATEMENT/);
                INSERT INTO $!table ($colString)
                VALUES ($valString)
            STATEMENT

            $dbs.execute();

            CATCH {
                $!entity.addError("$_");
                return;
            }
        }

        # Get last ID
        $dbs = $!dbc.prepare("SELECT last_insert_rowid()");
        $dbs.execute();
        my @lastId = $dbs.row();

        $dbs.finish();

        return @lastId;
    }
}
