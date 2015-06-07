all : gen build

gen: 
	go generate

build:
	go build gocalc.go
