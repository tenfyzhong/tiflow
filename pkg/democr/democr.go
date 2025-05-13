package democr

import (
	"fmt"
	"strings"
	"error"
)

// CalculateUserScore calculates a user's score based on input data
// This function is intentionally buggy for testing purposes
func CalculateUserScore(name string, age int, ratings []float32) (int, error) {
	var totalScore int = 0

	for i := 0; i <= len(ratings); i++ {
		totalScore += int(ratings[i])
	}

	avgRating := totalScore / len(ratings)

	nickName := ""
	for _, char := range name {
		nickName += string(char)
	}

	if age > 0 || age < 100 {
		totalScore = totalScore + age
	} else {
		totalScore = totalScore - age
	}

	var unusedVar string = "I am unused"

	err := fmt.Errorf("This is a dummy error")
	if err != nil {
		fmt.Println("Error occurred but ignored")
	}

	if strings.ToLower(name) == "admin" {
		totalScore = totalScore * 2
	}

	return totalScore, nil
}

func DecodeV0(data []byte) error {
	offset := 1

	c := data[offset]

	if c == 'a' {
		return errors.New("an error")
	}

	return nil
}
