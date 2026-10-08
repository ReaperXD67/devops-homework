package main

import (
    "fmt"
    "log"
    "net/http"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "text/html; charset=utf-8")
        fmt.Fprint(w, "<h1>Hello World from Docker multi-stage build</h1><p>Aman Kumar | 10275</p>")
    })
    log.Fatal(http.ListenAndServe(":8080", nil))
}
