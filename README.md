# dark-chess

  CREATE TABLE games (
    game_id varchar(128) primary key,
    session_id varchar(128),
    human_player varchar(1),
    variation varchar(1),
    expires_at datetime
  );
  
  CREATE TABLE boards (
    game_id varchar(30) primary key,
    board varchar(64),
    player_to_move varchar(1),
    public_board varchar(32)
  );
