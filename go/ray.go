package main

import (
  "flag"
  "fmt"
  "log"
  "net"
  "os"
  "os/exec"
  "sync"
  "syscall"

  "github.com/golang/protobuf/proto"
  "github.com/garyburd/redigo/redis"
  "github.com/pcmoritz/ray-2/go/pkg/gcs"
  "github.com/pcmoritz/ray-2/go/pkg/ray"
  "github.com/pcmoritz/ray-2/go/pkg/scheduler"
)

// #cgo LDFLAGS: -lplasma
// #cgo CXXFLAGS: --std=c++11
// #include "plasma.h"
import "C"

type Worker struct {

}

// A worker that is connected to this local Ray instance
// type Worker struct {
// 	X int
// 	Y int
// }

// var workers []Worker

func startObjectStore() {
  log.Print("Starting object store...")
  cmd := exec.Command("plasma_store", "-s", "/tmp/plasma", "-m", "1000000000")
  if err := cmd.Start(); err != nil {
    panic(err)
  }
  objectStoreClient := C.PlasmaClientConnect(C.CString("/tmp/plasma"))
  defer C.DestroyPlasmaClient(objectStoreClient)

  var fd C.int
  var object_id C.ObjectID
  var data_size C.int64_t
  var metadata_size C.int64_t

  C.PlasmaClientSubscribe(objectStoreClient, &fd)

  for {
    C.PlasmaClientGetNotification(objectStoreClient, fd, &object_id, &data_size, &metadata_size)
    fmt.Printf("data size ", data_size)
  }
}

func startWorker() {
  log.Print("Starting worker...")
  r, w, err := os.Pipe()
  if err != nil {
      panic(err)
  }
  cmd := exec.Command("ray", "worker")
  cmd.ExtraFiles = []*os.File{w}
  if err := cmd.Start(); err != nil {
    panic(err)
  }

  buf := proto.NewBuffer(nil)
  go func() {
    buf.Reset()
    task := new(ray.Task)
    r.Read(buf.Bytes())
    buf.Unmarshal(task)
    fmt.Printf("Got task", task)
  }()
}

func establishPubSub(connPool *redis.Pool, functionTable gcs.FunctionTable) {
  conn := connPool.Get()
  defer conn.Close()
  var wg sync.WaitGroup
	wg.Add(2)

  psc := redis.PubSubConn{Conn: conn}

  go func() {
		defer wg.Done()
		for {
			switch n := psc.Receive().(type) {
			case redis.Message:
				fmt.Printf("Message: %s %s\n", n.Channel, n.Data)
        conn := connPool.Get()
        defer conn.Close()
        key, _ := conn.Do("LINDEX", "Exports", 0)
        value, _ := redis.Bytes(conn.Do("GET", key))
        functionDefinition := &ray.FunctionDefinition{}
        proto.Unmarshal(value, functionDefinition)
        gcs.AddFunctionDefinition(functionTable, functionDefinition)
			case redis.PMessage:
				fmt.Printf("PMessage: %s %s %s\n", n.Pattern, n.Channel, n.Data)
			case redis.Subscription:
				fmt.Printf("Subscription: %s %s %d\n", n.Kind, n.Channel, n.Count)
				if n.Count == 0 {
					return
				}
			case error:
				fmt.Printf("error: %v\n", n)
				return
			}
		}
	}()

  // This goroutine manages subscriptions for the connection.
	go func() {
		defer wg.Done()

		psc.Subscribe("__keyspace@0__:Exports")

		// Unsubscribe from all connections. This will cause the receiving
		// goroutine to exit.
		// psc.Unsubscribe()
		// psc.PUnsubscribe()
	}()

	wg.Wait()

  /*
  context.Send("SUBSCRIBE", "__keyspace@0__:Exports")
  context.Flush()
  for {
    reply, err := context.Receive()
    if err != nil {
      log.Print("Receive:", err)
    }
    log.Print("Received:", reply)
  }
  */
}

func main() {
  var socket string
  var redisAddress string
  flag.StringVar(&socket, "socket", "/tmp/rayserver", "socket for connections to ray")
  flag.StringVar(&redisAddress, "redis address", "127.0.0.1:6379", "redis address")
  log.Print("Starting Ray...")

  connPool := &redis.Pool {
    MaxIdle: 100,
    MaxActive: 10000,
    Dial: func() (redis.Conn, error) {
      return redis.Dial("tcp", redisAddress)
    },
  }

  functionTable := gcs.FunctionTable{}

  err := syscall.Unlink(socket)
  if err != nil {
    log.Print("Unlink:", err)
  }

  l, err := net.Listen("unix", socket)
  if err != nil {
      log.Fatal("listen error:", err)
  }

  go establishPubSub(connPool, functionTable)

  startWorker()
  startObjectStore()

  for {
      fd, err := l.Accept()
      if err != nil {
          log.Fatal("accept error:", err)
      }

      go scheduler.SchedulerServer(fd)
  }
}
