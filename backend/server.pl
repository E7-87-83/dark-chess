use v5.30;
use Mojolicious::Lite;
use LWP::UserAgent;
use lib ".";
use BoardControl;
use BoardInit;

use DateTime;
use Data::UUID;
use DateTime::Duration;

use DBI;
my $driver = "SQLite";
my $database = "test.db";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password) or die $DBI::errstr;



my $localpath = 'http://localhost';


post '/gameInit/:session_id' => sub {
  my $session_id = $_[0]->param('session_id');
  my ($hp) = $dbh->selectrow_arrayref("SELECT COUNT(*) from games where session_id = \"$session_id\"")
    or die "Couldn't execute statement in gameInit";
  if ($hp->[0] >= 1) {
	  $dbh->do("DELETE from games where session_id = \"$session_id\"") 
	    or die "Could not delete game(s) with session ID $session_id";
  }
  my $dt = DateTime->now;
  my $dur = DateTime::Duration->new(hours => 24);
  $dt->add($dur);
  my $end_time = $dt->ymd . " " . $dt->hms;
  my $ug    = Data::UUID->new;
  my $game_id = $ug->create_str;
  $dbh->do("INSERT INTO games values (
	\"$game_id\", 
	\"$session_id\", 
	\"1\",
	\"0\",
	\"$end_time\"
	)") 
    or die "Could not insert new game with session ID $session_id";
   $_[0]->rendered(200);
};

post '/alterPlayer/:game_id' => sub {
  my $game_id = $_[0]->param('game_id');
  my ($hp) = $dbh->selectrow_arrayref("SELECT COUNT(*) from games where game_id = \"$game_id\"")
    or die "Couldn't execute select from games statement in alterPlayer";
  my ($bp) = $dbh->selectrow_arrayref("SELECT COUNT(*) from boards where game_id = \"$game_id\"")
    or die "Couldn't execute select from boards statement in alterPlayer";
  my $human_player;
  if ($hp->[0] == 1) {
	  $human_player = $dbh->selectrow_arrayref("SELECT human_player from games where game_id = \"$game_id\"")->[0]
		or die "Couldn't execute statement";
  }
  if ($hp->[0] == 1 && $bp->[0] == 0) {
	$dbh->do("UPDATE games SET human_player = \"".int(!$human_player)."\" where game_id =\"$game_id\"")
	  or die "ERROR: Update unsuccessful. Cannot change the human player's colour.";
	$_[0]->rendered(200);
  } else {
	$_[0]->rendered(400);
  }
};

post '/alterVar/:game_id' => sub {
  my $game_id = $_[0]->param('game_id');
  my ($hp) = $dbh->selectrow_arrayref("SELECT COUNT(*) from games where game_id = \"$game_id\"")
    or die "Couldn't execute select from games statement in alterPlayer";
  my ($bp) = $dbh->selectrow_arrayref("SELECT COUNT(*) from boards where game_id = \"$game_id\"")
    or die "Couldn't execute select from boards statement in alterPlayer";
  my $var;
  if ($hp->[0] == 1) {
	  $var = $dbh->selectrow_arrayref("SELECT variation from games where game_id = \"$game_id\"")->[0]
		or die "Couldn't execute statement";
  }
  if ($hp->[0] == 1 && $bp->[0] == 0) {
	$dbh->do("UPDATE games SET variation = \"".int(!$var)."\" where game_id =\"$game_id\"")
	  or die "ERROR: Update unsuccessful. Cannot change the variation.";
	$_[0]->rendered(200);
  } else {
	$_[0]->rendered(400);
  }
};

post '/boardInit/:game_id' => sub {
  my $game_id = $_[0]->param('game_id');
  my ($hp) = $dbh->selectrow_arrayref("SELECT COUNT(*) from games where game_id = \"$game_id\"")
    or die "Couldn't execute statement in boardInit";
  if ($hp->[0] == 1) {
	BoardInit::start($game_id);
	$_[0]->rendered(200);
  } else {
	$_[0]->rendered(400);
  }
};

post '/play/:game_id/:player/:move' => sub {
  my $game_id = $_[0]->param('game_id');
  my $move = $_[0]->param('move');
  my $player = $_[0]->param('player');
  my $ua = LWP::UserAgent->new(timeout => 10);
  if (BoardControl::is_valid_move($game_id, $move, $player)) {
	my $res = $ua->post("$localpath:5000/game/$game_id/$player/$move", {passkey => 'darkchess01'} );
  }
  $_[0]->rendered(200);
};

post '/game/:game_id/:player/:move' => sub {
  my $passkey = $_[0]->param('passkey');
  my $game_id = $_[0]->param('game_id');
  my $move = $_[0]->param('move');
  my $player = $_[0]->param('player');
  my $ua = LWP::UserAgent->new(timeout => 10);
  if ($passkey eq 'darkchess01') {
	my ($human_player) = $dbh->selectrow_arrayref("SELECT human_player from games where game_id = \"$game_id\"")->@*
      or die "Couldn't execute statement";
	BoardControl::act_move_on_game($game_id, $move, $player);
	$_[0]->rendered(200);
	if ($player eq $human_player) {
		sleep(1);
		my $res = $ua->post("$localpath:5001/comp/$game_id");  # ask engine to react
	}
  } else {
	$_[0]->rendered(400);
  }
};

get '/cond/:game_id' => sub {
  my $game_id = $_[0]->param('game_id');
  my ($hp) = $dbh->selectrow_arrayref("SELECT COUNT(*) from games where game_id = \"$game_id\"")
    or die "Couldn't execute statement";
  if ($hp->[0] == 1) {
	  my ($human_player) = $dbh->selectrow_arrayref("SELECT human_player from games where game_id = \"$game_id\"")->@*
		or die "Couldn't execute statement";
	  my ($pboard, $player_to_move) = $dbh->selectrow_arrayref("SELECT public_board, player_to_move from boards where game_id = \"$game_id\"")->@*
		or die "Couldn't execute statement";
	  $_[0]->render(json => {board => $pboard, player => $player_to_move, human => $human_player});
  } else {
	  $_[0]->rendered(400);
  }
};



# Start the Mojolicious command system
app->start;
