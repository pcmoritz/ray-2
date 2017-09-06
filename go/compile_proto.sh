# Install protobuf go compiler
go get -u github.com/golang/protobuf/protoc-gen-go

# Put protobuf go compiler into the PATH
export PATH=$PATH:$GOPATH/bin

# Create protobuf go sources
../cpp/build/src/ray/proto/protobuf/src/protobuf/protoc --go_out=./pkg/ray/ --proto_path ../cpp/src/ray/proto/ ../cpp/src/ray/proto/ray.proto
