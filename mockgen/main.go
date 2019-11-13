package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"text/template"
)

const programTmpl = `package main

import (
	"fmt"
	"reflect"
	"strings"

	_pkg "{{.Pkg}}"
)

type Method struct {
	Name string
	In   []string
	Out  []string
}

func main() {
	longestFnNameLength := 0
	imports := map[string]bool{"{{.Pkg}}": true}
	v := reflect.TypeOf((*_pkg.{{.Type}})(nil)).Elem()
	methods := make([]Method, v.NumMethod())
	for i := 0; i < v.NumMethod(); i++ {
		method := Method{}
		m := v.Method(i)
		method.Name = m.Name
		if len(m.Name) > longestFnNameLength {
			longestFnNameLength = len(m.Name)
		}
		method.In = make([]string, m.Type.NumIn())
		for j := 0; j < m.Type.NumIn(); j++ {
			param := m.Type.In(j)
			if param.PkgPath() != "" {
				imports[param.PkgPath()] = true
			}
			method.In[j] = param.String()
		}

		method.Out = make([]string, m.Type.NumOut())
		for j := 0; j < m.Type.NumOut(); j++ {
			param := m.Type.Out(j)
			method.Out[j] = param.String()
		}
		methods[i] = method
	}

	fmt.Printf("package mocks\n\nimport (\n")
	for imp := range imports {
		fmt.Printf("\t\"%s\"\n", imp)
	}
	fmt.Printf(")\n\n")

	fmt.Printf("type Mock struct {\n")
	longestFnNameLength += 12
	for _, method := range methods {
		fmt.Printf("\t%sInvocations%sint\n", method.Name, strings.Repeat(" ", longestFnNameLength-len(method.Name)-11))
		fmt.Printf("\t%sFn%sfunc(%s)", method.Name, strings.Repeat(" ", longestFnNameLength-len(method.Name)-2), strings.Join(method.In, ", "))
		if len(method.Out) == 1 {
			fmt.Printf(" %s", method.Out[0])
		} else if len(method.Out) > 1 {
			fmt.Printf(" (%s)", strings.Join(method.Out, ", "))
		}
		fmt.Println()
	}
	fmt.Printf("}\n")

	for _, method := range methods {
		fmt.Printf("\nfunc (m *Mock) %s(", method.Name)
		for i, param := range method.In {
			fmt.Printf("p%d %s", i, param)
			if i < len(method.In)-1 {
				fmt.Printf(", ")
			}
		}
		fmt.Printf(")")
		if len(method.Out) == 1 {
			fmt.Printf(" %s", method.Out[0])
		} else if len(method.Out) > 1 {
			fmt.Printf(" (%s)", strings.Join(method.Out, ", "))
		}
		fmt.Printf(" {\n")
		fmt.Printf("\tm.%sInvocations++\n\t", method.Name)
		if len(method.Out) > 0 {
			fmt.Printf("return ")
		}
		fmt.Printf("m.%sFn(", method.Name)
		for i, _ := range method.In {
			fmt.Printf("p%d", i)
			if i < len(method.In)-1 {
				fmt.Printf(", ")
			}
		}
		fmt.Printf(")\n}\n")
	}
}
`

func main() {
	prevWd, err := os.Getwd()
	if err != nil {
		panic(err)
	}
	tempDir, err := ioutil.TempDir(".", "")
	if err != nil {
		panic(err)
	}
	defer func() {
		err = os.Chdir(prevWd)
		if err != nil {
			panic(err)
		}
		err = os.RemoveAll(tempDir)
		if err != nil {
			panic(err)
		}
	}()
	err = os.Chdir(tempDir)
	if err != nil {
		panic(err)
	}

	var program bytes.Buffer
	template.Must(template.New("program").Parse(programTmpl)).Execute(&program, struct {
		Pkg  string
		Type string
	}{
		Pkg:  os.Args[1],
		Type: os.Args[2],
	})

	err = ioutil.WriteFile("mocker.go", program.Bytes(), 0600)
	if err != nil {
		panic(err)
	}
	compileCmd := exec.Command("go", "build", "-o", "mocker", "mocker.go")
	out, err := compileCmd.CombinedOutput()
	if err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", string(out))
		panic(err)
	}

	runCmd := exec.Command("./mocker")
	out, err = runCmd.CombinedOutput()
	if err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", string(out))
		panic(err)
	}

	fmt.Printf("%s", string(out))
}
