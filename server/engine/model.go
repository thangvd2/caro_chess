package engine

type Player string

const (
	PlayerX Player = "X"
	PlayerO Player = "O"
)

type GameRule string

const (
	RuleStandard  GameRule = "standard"
	RuleFreeStyle GameRule = "freeStyle"
	RuleCaro      GameRule = "caro"
)

type Position struct {
	X int `json:"x"`
	Y int `json:"y"`
}

type Cell struct {
	Position Position `json:"position"`
	Owner    *Player  `json:"owner"` // nil if empty
}

func (c *Cell) IsEmpty() bool {
	return c.Owner == nil
}

type Board struct {
	Rows    int       `json:"rows"`
	Columns int       `json:"columns"`
	Cells   [][]*Cell `json:"cells"`
}

func NewBoard(rows, columns int) *Board {
	cells := make([][]*Cell, rows)
	for y := 0; y < rows; y++ {
		row := make([]*Cell, columns)
		for x := 0; x < columns; x++ {
			row[x] = &Cell{
				Position: Position{X: x, Y: y},
				Owner:    nil,
			}
		}
		cells[y] = row
	}
	return &Board{
		Rows:    rows,
		Columns: columns,
		Cells:   cells,
	}
}
