package gcs

import (
  "crypto/sha1"
  "log"
  "sync"
  "github.com/pcmoritz/ray-2/go/pkg/ray"
)

type FunctionTable struct {
  entries [](*ray.FunctionDefinition)
  mutex sync.Mutex
}

func AddFunctionDefinition(functionTable FunctionTable, functionDefinition *ray.FunctionDefinition) {
  log.Print("Adding function definition ", functionDefinition)
  functionTable.mutex.Lock()
  functionTable.entries = append(functionTable.entries, functionDefinition)
  functionTable.mutex.Unlock()
}

// TODO: Define typedef for object id

type ObjectTable struct {
  entries map[[sha1.Size]byte][bool]
  // channel [[sha1.Size]byte]chan
  mutex sync.Mutex
}

func AddObject(objectTable ObjectTable, object_id [sha1.Size]byte) {
  log.Print("Adding object definition", object_id)
  // TODO send object over channel
  // TODO add object to object table
}
