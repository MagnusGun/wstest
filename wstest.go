package main

import (
	"bufio"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"net/url"
	"os"
	"os/signal"
	"path"
	"runtime"
	"time"

	"github.com/akamensky/argparse"
	"github.com/gorilla/websocket"
	"github.com/sirupsen/logrus"
)

//var addr = flag.String("addr", "localhost:8080", "http service address")

func initLog(logLevel string) *logrus.Logger {
	logger := logrus.New()
	logger.SetReportCaller(true)
	logger.Formatter = &logrus.JSONFormatter{
		CallerPrettyfier: func(f *runtime.Frame) (string, string) {
			_, fileName := path.Split(f.File)
			return "", fmt.Sprintf("%s:%d", fileName, f.Line)
		},
	}
	switch logLevel {
	case "trace":
		logger.SetLevel(logrus.TraceLevel)
	case "debug":
		logger.SetLevel(logrus.DebugLevel)
	case "info":
		logger.SetLevel(logrus.InfoLevel)
	case "warn":
		logger.SetLevel(logrus.WarnLevel)
	case "error":
		logger.SetLevel(logrus.ErrorLevel)
	case "fatal":
		logger.SetLevel(logrus.FatalLevel)
	case "panic":
		logger.SetLevel(logrus.PanicLevel)
	}
	iow := io.Writer(os.Stdout)
	logger.SetOutput(iow)
	return logger
}

func scanner(input chan string) {
	defer close(input)
	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		input <- scanner.Text()
	}
}

func main() {
	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt)

	parser := argparse.NewParser("print", "Server Core")
	serverURL := parser.String("", "server", &argparse.Options{Required: false, Help: "websocket IP or url", Default: "localhost"})
	serverPort := parser.Int("", "port", &argparse.Options{Required: false, Help: "websocket port", Default: 8443})
	serverPath := parser.String("", "path", &argparse.Options{Required: false, Help: "server path", Default: "/"})
	logLevel := parser.Selector("", "loglevel", []string{"trace", "debug", "info", "warn", "error", "fatal", "panic"}, &argparse.Options{
		Required: false,
		Help:     "changes log output level",
		Default:  "info"})
	if err := parser.Parse(os.Args); err != nil {
		fmt.Print(parser.Usage(err))
	}

	log := initLog(*logLevel)

	input := make(chan string, 1)
	go scanner(input)

	addr := fmt.Sprintf("%s:%d", *serverURL, *serverPort)
	url := url.URL{Scheme: "ws", Host: addr, Path: *serverPath}
	log.Info("connecting to %s", url.String())

	dialer := *websocket.DefaultDialer
	dialer.TLSClientConfig = &tls.Config{InsecureSkipVerify: true}

	c, _, err := dialer.Dial(url.String(), nil)
	if err != nil {
		log.Fatal("dial:", err)
	}
	defer c.Close()

	done := make(chan struct{})

	go func() {
		defer close(done)

		type Data struct {
			Action string      `json:"action"`
			Data   interface{} `json:"data"`
			Module string      `json:"module"`
		}

		var payload Data
		for {
			if err := c.ReadJSON(&payload); err != nil {
				log.Error("read:", err)
				return
			}
			/*
				_, message, err := c.ReadMessage()
				if err != nil {
					log.Error("read:", err)
					return
				}
				log.Infof("message: %s", message)
			*/
			switch payload.Data.(type) {
			case float64:
				{
					log.Info("float64: ", payload.Data)
				}
			case interface{}:
				{
					byteData := []byte(fmt.Sprintf("%v", payload.Data))
					if json.Valid(byteData) {
						log.Infof("byteData: %s", byteData)
					} else {
						log.Info("interface: ", payload.Data)
					}

				}
			default:
				{
					log.Info("default: ", payload.Data)
				}
			}
		}
	}()

	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-done:
			log.Info("done 1")
			return
		case str := <-input:
			err := c.WriteMessage(websocket.TextMessage, []byte(str))
			if err != nil {
				log.Info("write:", err)
				return
			}
		case <-interrupt:
			log.Info("interrupt")
			// Cleanly close the connection by sending a close message and then
			// waiting (with timeout) for the server to close the connection.
			err := c.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
			if err != nil {
				log.Error("write close:", err)
				return
			}
			select {
			case <-done:
				log.Info("done 2")
			case <-time.After(time.Second):
			}
			return
		}
	}
}
