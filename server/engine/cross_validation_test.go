package engine

import (
	"encoding/json"
	"fmt"
	"os"
	"testing"
)

type TestMove struct {
	X      int    `json:"x"`
	Y      int    `json:"y"`
	Player string `json:"player"`
}

type ExpectedState struct {
	Winner        *string               `json:"winner"`
	IsGameOver    bool                  `json:"isGameOver"`
	WinningLine   []map[string]int       `json:"winningLine"`
	LastMoveFailed bool                  `json:"lastMoveFailed"`
	Reason        string                `json:"reason"`
}

type TestScenario struct {
	Name     string        `json:"name"`
	Rule     string        `json:"rule"`
	Moves    []TestMove    `json:"moves"`
	Expected ExpectedState `json:"expected"`
}

type TestVectors struct {
	Scenarios []TestScenario `json:"scenarios"`
}

func TestCrossLanguageValidation(t *testing.T) {
	// Load test vectors from JSON file
	data, err := os.ReadFile("../../test_vectors/engine_scenarios.json")
	if err != nil {
		t.Fatalf("Failed to read test vectors: %v", err)
	}

	var vectors TestVectors
	if err := json.Unmarshal(data, &vectors); err != nil {
		t.Fatalf("Failed to parse test vectors: %v", err)
	}

	for _, scenario := range vectors.Scenarios {
		t.Run(scenario.Name, func(t *testing.T) {
			rule := parseRule(scenario.Rule)
			engine := NewGameEngine(15, 15, rule)

			// Apply all moves
			for _, move := range scenario.Moves {
				player := parsePlayer(move.Player)

				pos := Position{X: move.X, Y: move.Y}
				success := engine.PlacePiece(pos)

				// If move failed, player turn doesn't change
				// If move succeeded, turn alternates
				if !success && engine.CurrentPlayer != player {
					// Move was rejected by the engine (valid)
					continue
				}
			}

			// Validate final state
			expected := scenario.Expected
			expectedGameOver := expected.IsGameOver
			expectedWinner := expected.Winner

			if engine.IsGameOver != expectedGameOver {
				t.Errorf("Game over mismatch: expected %v, got %v", expectedGameOver, engine.IsGameOver)
			}

			if expectedWinner == nil {
				if engine.Winner != nil {
					t.Errorf("Expected no winner, got %v", engine.Winner)
				}
			} else {
				if engine.Winner == nil {
					t.Errorf("Expected winner %s, but got no winner", *expectedWinner)
				} else {
					winnerStr := playerToString(*engine.Winner)
					if winnerStr != *expectedWinner {
						t.Errorf("Winner mismatch: expected %s, got %s", *expectedWinner, winnerStr)
					}
				}
			}

			// Validate winning line if provided - check if all expected positions are in the winning line
			if len(expected.WinningLine) > 0 {
				if engine.WinningLine == nil {
					t.Errorf("Expected winning line, but got nil")
				} else {
					if len(engine.WinningLine) != len(expected.WinningLine) {
						t.Errorf("Winning line length mismatch: expected %d, got %d",
							len(expected.WinningLine), len(engine.WinningLine))
					} else {
						// Create a map of expected positions for comparison
						expectedPositions := make(map[string]bool)
						for _, expPos := range expected.WinningLine {
							key := fmt.Sprintf("%d,%d", expPos["x"], expPos["y"])
							expectedPositions[key] = true
						}

						// Check that all winning line positions are in the expected set
						for _, actPos := range engine.WinningLine {
							posKey := fmt.Sprintf("%d,%d", actPos.X, actPos.Y)
							if !expectedPositions[posKey] {
								t.Errorf("Winning line contains unexpected position (%s)", posKey)
							}
						}
					}
				}
			}
		})
	}
}

func parseRule(rule string) GameRule {
	switch rule {
	case "standard":
		return RuleStandard
	case "freestyle":
		return RuleFreeStyle
	case "caro":
		return RuleCaro
	default:
		panic("Unknown rule: " + rule)
	}
}

func parsePlayer(player string) Player {
	switch player {
	case "X":
		return PlayerX
	case "O":
		return PlayerO
	default:
		panic("Unknown player: " + player)
	}
}

func playerToString(player Player) string {
	switch player {
	case PlayerX:
		return "X"
	case PlayerO:
		return "O"
	default:
		return "?"
	}
}
