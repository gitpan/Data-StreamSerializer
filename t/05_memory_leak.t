#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 3;
use Time::HiRes qw(time);
use Encode qw(decode encode);

use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'Data::StreamSerializer';
}

sub gen_rand_object() {
    my $h = {};
    for (0 .. 20) {
        for (0 .. 20) {
            $h->{rand()} = [ map { rand } 0 .. 10 ];
        }
    }

    $h;
}

my $size = Data::StreamSerializer::_memory_size;
my $size_end = Data::StreamSerializer::_memory_size;
my $time = time;
my ($count, $count_end) = (1, 1);
my $i = 0;
my $len = 0;
for(;;) {
    my $sr = new Data::StreamSerializer(gen_rand_object);
    while (defined (my $part = $sr->next)) {
        $len += length $part;
        $i++;
    }

    if (time - $time > $count and $count < 3) {
        $size = Data::StreamSerializer::_memory_size;
        $count++;
    }

    if ($count_end < 10) {
        if (time - $time > $count_end) {
            $size_end = Data::StreamSerializer::_memory_size;
            $count_end++;
        }
    } else {
        $size_end = Data::StreamSerializer::_memory_size;
        last;
    }
}

ok $size_end == $size, "Check memory leak";
note "$i iterations were done, $len bytes were produced";

my @test_array;
$time = time;
$size = $size_end;
for (1 .. 1000_000 + int rand 1000_000) {
    push @test_array, rand rand 1000;
}

ok Data::StreamSerializer::_memory_size != $size,
    sprintf "Check memory checker (size: %d elements) :)", scalar @test_array;
