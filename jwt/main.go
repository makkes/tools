package main

import (
	"bufio"
	"crypto/rsa"
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

func getToken(jwtString string, pubKey *rsa.PublicKey) (*jwt.Token, error) {
	parser := jwt.NewParser(
		jwt.WithoutClaimsValidation(),
	)

	var keyfunc jwt.Keyfunc
	if pubKey != nil {
		keyfunc = func(token *jwt.Token) (interface{}, error) {
			return pubKey, nil
		}
	}

	token, err := parser.Parse(jwtString, keyfunc)
	if err != nil {
		if errors.Is(err, jwt.ErrTokenUnverifiable) {
			if keyfunc == nil {
				fmt.Printf("Signature NOT verified! ❌\n\n")
				return token, nil
			} else {
				return nil, fmt.Errorf("failed verifying token: %w", err)
			}
		}
		if errors.Is(err, jwt.ErrTokenSignatureInvalid) {
			fmt.Printf("Signature invalid! ❌\n\n")
			return token, nil
		}
		return nil, fmt.Errorf("unexpected error parsing token: %w", err)
	}
	fmt.Printf("Signature verified ✔️\n\n")
	return token, nil

}

func main() {
	stdin := bufio.NewScanner(os.Stdin)
	var tokenString string
	if stdin.Scan() {
		tokenString = stdin.Text()
	}

	var pubKeyBytes []byte
	if len(os.Args) > 2 && os.Args[1] == "-k" {
		var err error
		pubKeyBytes, err = os.ReadFile(os.Args[2])
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error reading public key file: %s. Continuing without signature verification.\n", err)
		}
	}

	var pubKey *rsa.PublicKey
	if pubKeyBytes != nil {
		var err error
		pubKey, err = jwt.ParseRSAPublicKeyFromPEM(pubKeyBytes)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error parsing public key: %s. Continuing without signature verification.\n", err)
		}
	}

	token, err := getToken(tokenString, pubKey)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed parsing token: %s", err)
		os.Exit(1)
	}
	if token == nil {
		fmt.Fprintf(os.Stderr, "Token is invalid.\n")
		os.Exit(1)
	}

	fmt.Printf("Header:\n")
	for key, val := range token.Header {
		fmt.Printf("  %s: %s\n", key, val)
	}
	fmt.Printf("\n")

	fmt.Printf("Claims (")
	if mapClaims, ok := token.Claims.(jwt.MapClaims); ok {
		if err := jwt.NewValidator().Validate(mapClaims); err != nil {
			fmt.Printf("invalid, %s):\n", err)
		} else {
			fmt.Printf("valid):\n")
		}
		for key, val := range mapClaims {
			fmt.Printf("  ")
			if key == "exp" || key == "iat" || key == "nbf" { // date values
				var floatVal float64
				var ok bool
				if floatVal, ok = val.(float64); !ok {
					fmt.Printf("%s: %v (unexpected type for value)\n", key, val)
				} else {
					intVal := int64(floatVal)
					fmt.Printf("%s: %d (%s)\n", key, intVal, time.Unix(intVal, 0))
				}
			} else if f, ok := val.(float64); ok { // some float64 value
				fmt.Printf("%s: %f\n", key, f)
			} else { // unknown value, print as is
				fmt.Printf("%s: %v\n", key, val)
			}
		}
	}
}
