package gcs

import (
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
