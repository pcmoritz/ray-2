package main

import (
  "flag"
  "fmt"
  "log"
  "net"
  "os/exec"
  "sync"
  "syscall"

  "github.com/golang/protobuf/proto"
  "github.com/garyburd/redigo/redis"
  "github.com/pcmoritz/ray-2/go/pkg/gcs"
  "github.com/pcmoritz/ray-2/go/pkg/ray"
  "github.com/pcmoritz/ray-2/go/pkg/scheduler"
)

func startWorkers(socket string) {
  log.Print("Starting worker pool...")
  // worker := exec.Command("ray", "worker", "--socket", socket)
  exec.Command("ray", "worker", "--socket", socket)
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

  startWorkers(socket)

  for {
      fd, err := l.Accept()
      if err != nil {
          log.Fatal("accept error:", err)
      }

      go scheduler.SchedulerServer(fd)
  }
}
