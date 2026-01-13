package engine

type GameEngine struct {
	Board         *Board     `json:"board"`
	CurrentPlayer Player     `json:"currentPlayer"`
	IsGameOver    bool       `json:"isGameOver"`
	Winner        *Player    `json:"winner"`
	Rule          GameRule   `json:"rule"`
	History       []Position `json:"history"`
	WinningLine   []Position `json:"winningLine"`
}

func NewGameEngine(rows, columns int, rule GameRule) *GameEngine {
	return &GameEngine{
		Board:         NewBoard(rows, columns),
		CurrentPlayer: PlayerX,
		IsGameOver:    false,
		Winner:        nil,
		Rule:          rule,
		History:       []Position{},
		WinningLine:   nil,
	}
}

func (ge *GameEngine) PlacePiece(pos Position) bool {
	if ge.IsGameOver {
		return false
	}
	if !ge.IsValidPosition(pos) {
		return false
	}
	if !ge.Board.Cells[pos.Y][pos.X].IsEmpty() {
		return false
	}

	ge.applyMove(pos)
	ge.History = append(ge.History, pos)
	return true
}

func (ge *GameEngine) applyMove(pos Position) {
	player := ge.CurrentPlayer
	ge.Board.Cells[pos.Y][pos.X].Owner = &player

	line := ge.checkWin(pos)
	if line != nil {
		ge.IsGameOver = true
		curr := ge.CurrentPlayer
		ge.Winner = &curr
		ge.WinningLine = line
	} else {
		if ge.CurrentPlayer == PlayerX {
			ge.CurrentPlayer = PlayerO
		} else {
			ge.CurrentPlayer = PlayerX
		}
	}
}

func (ge *GameEngine) IsValidPosition(pos Position) bool {
	return pos.X >= 0 &&
		pos.X < ge.Board.Columns &&
		pos.Y >= 0 &&
		pos.Y < ge.Board.Rows
}

func (ge *GameEngine) checkWin(lastMove Position) []Position {
	player := *ge.Board.Cells[lastMove.Y][lastMove.X].Owner
	directions := [][]int{
		{1, 0},  // Horizontal
		{0, 1},  // Vertical
		{1, 1},  // Diagonal \
		{1, -1}, // Diagonal /
	}

	for _, dir := range directions {
		line := []Position{lastMove}
		dx, dy := dir[0], dir[1]

		forwardCount := 0
		for i := 1; i < 6; i++ {
			x := lastMove.X + dx*i
			y := lastMove.Y + dy*i
			pos := Position{X: x, Y: y}
			if !ge.IsValidPosition(pos) {
				break
			}
			cell := ge.Board.Cells[y][x]
			if cell.Owner == nil || *cell.Owner != player {
				break
			}
			forwardCount++
			line = append(line, pos)
		}

		backwardCount := 0
		for i := 1; i < 6; i++ {
			x := lastMove.X - dx*i
			y := lastMove.Y - dy*i
			pos := Position{X: x, Y: y}
			if !ge.IsValidPosition(pos) {
				break
			}
			cell := ge.Board.Cells[y][x]
			if cell.Owner == nil || *cell.Owner != player {
				break
			}
			backwardCount++
			line = append(line, pos)
		}

		totalCount := 1 + forwardCount + backwardCount

		if ge.Rule == RuleStandard {
			if totalCount == 5 {
				return line
			}
		} else if ge.Rule == RuleFreeStyle {
			if totalCount >= 5 {
				return line
			}
		} else if ge.Rule == RuleCaro {
			if totalCount == 5 {
				blockedForward := false
				fX := lastMove.X + dx*(forwardCount+1)
				fY := lastMove.Y + dy*(forwardCount+1)
				fPos := Position{X: fX, Y: fY}

				if !ge.IsValidPosition(fPos) {
					blockedForward = true
				} else {
					fCell := ge.Board.Cells[fY][fX]
					if fCell.Owner != nil && *fCell.Owner != player {
						blockedForward = true
					}
				}

				blockedBackward := false
				bX := lastMove.X - dx*(backwardCount+1)
				bY := lastMove.Y - dy*(backwardCount+1)
				bPos := Position{X: bX, Y: bY}

				if !ge.IsValidPosition(bPos) {
					blockedBackward = true
				} else {
					bCell := ge.Board.Cells[bY][bX]
					if bCell.Owner != nil && *bCell.Owner != player {
						blockedBackward = true
					}
				}

				if !(blockedForward && blockedBackward) {
					return line
				}
			}
		}
	}

	return nil
}
