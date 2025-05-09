use v5.30;
use Mojolicious::Lite;
use LWP::UserAgent;
use lib ".";

use DBI;
my $driver = "SQLite";
my $database = "test.db";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password) or die $DBI::errstr;



my $localpath = 'http://localhost';


post '/comp/:game_id' => sub {
  my $game_id = $_[0]->param('game_id');
  my ($hp) = $dbh->selectrow_arrayref("SELECT COUNT(*) from games where game_id = \"$game_id\"")
    or die "Couldn't execute statement";
  my ($bp) = $dbh->selectrow_arrayref("SELECT COUNT(*) from boards where game_id = \"$game_id\"")
    or die "Couldn't execute statement";
  if ($hp->[0] == 1 && $bp->[0] == 1) {
	  my $ua = LWP::UserAgent->new(timeout => 10);
	  my $human_player = $dbh->selectrow_arrayref("SELECT human_player from games where game_id = \"$game_id\"")->[0]
		or die "Couldn't execute statement";
	  my $bot_player = int(!$human_player);
	  my ($pbd, $player_to_move) = $dbh->selectrow_arrayref("SELECT public_board, player_to_move from boards where game_id = \"$game_id\"")->@*
        or die "Couldn't execute statement";
	  return unless $player_to_move eq $bot_player;
	  my $bot_move_decision = _evaluate($pbd, $bot_player);
	  my $res = $ua->post("$localpath:5000/play/$game_id/$bot_player/$bot_move_decision");
	  $_[0]->rendered(200);
  }
};



sub _evaluate {
    my $pboard = $_[0];
    my $side = $_[1];
}

# Start the Mojolicious command system
app->start;
