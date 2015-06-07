//go:generate -command yacc go tool yacc
//go:generate yacc -o gocalc.go -p "expr" gocalc.y

package main
