package main

import (
  "log"
  "net"
  "os/exec"
  "syscall"

  "github.com/pcmoritz/ray-2/go/pkg/scheduler"
)

func main() {
  log.Print("Starting Ray...")

  log.Print("Starting worker pool...")
  worker := exec.Command("python", "-m", "ray")

  err := syscall.Unlink("/tmp/photon")
  if err != nil {
    log.Print("Unlink:", err)
  }

  l, err := net.Listen("unix", "/tmp/photon")
  if err != nil {
      log.Fatal("listen error:", err)
  }

  for {
      fd, err := l.Accept()
      if err != nil {
          log.Fatal("accept error:", err)
      }

      go scheduler.SchedulerServer(fd)
  }
}
