package elo

import "math"

const K = 32

// CalculateRatings returns the new ratings for player A and player B.
// actualScoreA is 1.0 for A win, 0.0 for B win, 0.5 for draw.
func CalculateRatings(ratingA, ratingB int, actualScoreA float64) (int, int) {
	expectedA := 1.0 / (1.0 + math.Pow(10, float64(ratingB-ratingA)/400.0))
	expectedB := 1.0 - expectedA // Zero-sum

	newRatingA := float64(ratingA) + float64(K)*(actualScoreA-expectedA)
	
	actualScoreB := 1.0 - actualScoreA
	newRatingB := float64(ratingB) + float64(K)*(actualScoreB-expectedB)

	return int(math.Round(newRatingA)), int(math.Round(newRatingB))
}
