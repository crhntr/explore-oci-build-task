package main

import "os"

const varName = "GREETING"

func main() {
	value, found := os.LookupEnv(varName)
	if !found {
		panic(varName + " not found")
	}
	println(value)
}
