%{

package main

import (
	"fmt"
	"bufio"
	"log"
	"io"
	"strconv"
	"os"
	"bytes"
	"unicode/utf8"
	"unicode"
)

%}

%start lines

%union {
	num float64
	string string
}

%type <num> expr stmt

%token '+' '-' '*' '/' '(' ')' ';'
%token LET 
%token <string> ID
%token <num> NUM

%left '+' '-'
%left '*' '/'
%left UMINUS

%%

lines:
|	line
|	lines ';' line

line: 
	stmt
	{
		fmt.Println($1)
	}
|	expr 
	{
		fmt.Println($1)
	}
stmt: 
	ID '=' expr	
	{
		env[$1] = $3
		$$ = $3
	}
expr: 
	NUM
| 	ID
	{
		$$ = env[$1]
	}
| 	expr '+' expr
	{
		$$ = $1 + $3
	}
| 	expr '-' expr
	{
		$$ = $1 - $3
	}
| 	expr '*' expr
	{
		$$ = $1 * $3
	}
| 	expr '/' expr
	{
		$$ = $1 / $3
	}
| 	'-' expr %prec UMINUS
	{
		$$ = -$2
	}
| 	'(' expr ')'
	{
		$$ = $2
	}

%%

var env map[string]float64

const eof = 0

type elex struct {
	line []byte
	peek rune
}

func (x *elex) Lex(yylval *exprSymType) int {
	
	for {
		c := x.next()
		
		switch {
		case c == eof:
			return eof
		case unicode.IsNumber(c):
			return x.num(c, yylval)
		case unicode.IsLetter(c):
			return x.char(c, yylval)
		case isOneOf(c,';','+','-','*','/','(',')','='):
			return int(c)
		case unicode.IsSpace(c):
		default:
			fmt.Printf("unrecognized char %q", c)
		}
	}
}

func isOneOf(c rune, rs ...rune) bool {
	for _,r := range rs {
		if (c == r) {
			return true
		}
	}

	return false
}

func (x *elex) char(c rune, yylval *exprSymType) int {
	add := func(b *bytes.Buffer, c rune) {
		b.WriteRune(c)
	}
	
	var b bytes.Buffer
	
	add(&b, c)

	L: for {
		c = x.next()
		switch {
			case unicode.IsLetter(c):
				add(&b, c)	
			default: 
				break L
		}
	}

	if c != eof {
		x.peek = c
	}
	
	s := b.String()

	if (s == "let"){
		return LET
	}

	yylval.string = s
	return ID
}

func (x *elex) num(c rune, yylval *exprSymType) int {
	add := func(b *bytes.Buffer, c rune) {
		b.WriteRune(c)
	}
	
	var b bytes.Buffer
	
	add(&b, c)

	L: for {
		c = x.next()
		switch c {
		case '.','e','E','-','0','1','2','3','4','5','6','7','8','9':
			add(&b, c)
		default: 
			break L
		}
	}
	
	if c != eof {
		x.peek = c
	}

	v,e := strconv.ParseFloat(b.String(), 64)

	if (e != nil){	
		fmt.Println(e)
	}

	yylval.num = v
	return NUM
}

func (x *elex) next() rune {
	// if the next char is eof, that means we peeked forward and then backed up
	// by one character

	// so we just return the peek and reset it
	if x.peek != eof {
		r := x.peek
		x.peek = eof
		return r
	}
	
	if len(x.line) == 0 {
		return eof
	}

	c, size := utf8.DecodeRune(x.line)
	x.line = x.line[size:] // chop off the remainder of the line

	return c
}

func (x *elex) Error(s string) {
	fmt.Printf("Parse error: %s", s)
}

func main(){
	
	env = make(map[string]float64)
	in := bufio.NewReader(os.Stdin)
	for {
		if _, err := os.Stdout.WriteString("> "); err != nil {
			fmt.Println("FAIL")
			return
		}
		
		line, err := in.ReadBytes('\n')
		if err == io.EOF {
			return
		}

		if err != nil {
			log.Fatalf("ReadBytes: %s", err)
		}
		
		exprParse(&elex{line: line})
	}
}
