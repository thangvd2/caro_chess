package main

type GameSession struct {
	ClientX *Client
	ClientO *Client
	Turn    string
}

func newGameSession(x, o *Client) *GameSession {
	return &GameSession{
		ClientX: x,
		ClientO: o,
		Turn:    "X",
	}
}
