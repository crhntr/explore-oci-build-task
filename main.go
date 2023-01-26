package main

import "os"

const varName = "SOME_VARIABLE"

func main() {
	value, found := os.LookupEnv(varName)
	if !found {
		panic(varName + " not found")
	}
	println(value)
}
