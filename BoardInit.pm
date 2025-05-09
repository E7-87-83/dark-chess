package BoardInit;
use v5.30;
use DBI;
use Carp;
use List::Util qw/shuffle/;

my $driver = "SQLite";
my $database = "test.db";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password) or die $DBI::errstr;

sub start {
    my $game_id = $_[0];
    my @arr = split "", "KRRNNCCAABBPPPPPkrrnnccaabbppppp";
    @arr = shuffle @arr;
    my $board = join "", map { "x". $_ } @arr;
    $dbh->do("INSERT INTO boards (game_id, board, player_to_move) values (\"$game_id\", \"$board\", \"1\")") or return 0;
    return 1;
}
