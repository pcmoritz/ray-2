package scheduler

import (
  //"crypto/sha1"
  "encoding/binary"
  "io"
  "log"
  "net"
  "github.com/golang/protobuf/proto"
  "github.com/pcmoritz/ray-2/go/pkg/ray"
)

const PROTOCOL_VERSION = 0

func readMessage(conn io.Reader) (int64, []byte)  {
  var version int64
  err := binary.Read(conn, binary.LittleEndian, &version)
  if err != nil {
    log.Fatal("Read version: ", err)
  }
  var messageType int64
  err = binary.Read(conn, binary.LittleEndian, &messageType)
  if err != nil {
    log.Fatal("Read type: ", err)
  }
  var size int64
  err = binary.Read(conn, binary.LittleEndian, &size)
  if err != nil {
    log.Fatal("Read size: ", err)
  }
  buf := make([]byte, size)
  err = binary.Read(conn, binary.LittleEndian, &buf)
  if err != nil {
    log.Fatal("Read buf: ", err)
  }
  return messageType, buf
}

func writeMessage(conn net.Conn, messageType int64, message []byte) {
  err := binary.Write(conn, binary.LittleEndian, PROTOCOL_VERSION)
  if err != nil {
    log.Fatal("Write version: ", err)
  }
  err = binary.Write(conn, binary.LittleEndian, messageType)
  if err != nil {
    log.Fatal("Write type: ", err)
  }
  err = binary.Write(conn, binary.LittleEndian, int64(len(message)))
  if err != nil {
    log.Fatal("Write size: ", err)
  }
  log.Print("Length is: ", len(message))
  err = binary.Write(conn, binary.LittleEndian, message)
  if err != nil {
    log.Fatal("Write buf: ", err)
  }
}

const IDSize = 20

type ObjectTableEntry struct {

}

// type ObjectTable struct {
//   map[byte[IDSize]][ObjectTableEntry] entries
// }

type QueueEntry struct {
  task *ray.Task
}

var waitingQueue []QueueEntry
var activeQueue []QueueEntry

func SchedulerLoop() {
  for {
    // TODO get object id from channel
    // iterate through waitingQueue and shift stuff to activeQueue
  }
}

func SchedulerServer(conn net.Conn) {
  log.Print("New client joined")
  // TODO(pcm): Change that
  for {
    task := &ray.Task{}
    _, buf := readMessage(conn)
    proto.Unmarshal(buf, task)
    waitingQueue = append(waitingQueue, QueueEntry{task})
    // log.Print("Got task ", message)
  }
}
